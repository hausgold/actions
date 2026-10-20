#!/bin/bash
#
# $1 - application name
#
# The +CLONE_TOKEN+ and +SECRET_KEY+ environment variables must be present.

PROGNAME="$(basename "${0}")"

# Die on any errors, and inherit the ERR trap into subshells
set -eE

# Report the failed command, its line and its exit code on stderr. The
# wrapping action prints the collected stderr as warnings when we fail. We
# print the unexpanded source text of the command, so no secrets end up in
# the log. Failed subshell groups are skipped, because their failed inner
# command was already reported.
#
# $1 - the line number of the failed command
function report-failure()
{
  local code="${?}"

  if [[ "${BASH_COMMAND}" =~ ^\( ]]; then
    return
  fi

  >&2 echo "${PROGNAME}: line ${1}: \`${BASH_COMMAND}\`" \
    "failed with exit code ${code}"
}
trap 'report-failure "${LINENO}"' ERR

if [ -z "${1}" ]; then
  >&2 echo 'Application name ($1) is missing.'
  exit 1
else
  APP="${1}"
fi

if [ -z "${CLONE_TOKEN}" ]; then
  >&2 echo 'The `CLONE_TOKEN` environment variable is missing.'
  exit 1
fi

if [ -z "${SECRET_KEY}" ]; then
  >&2 echo 'The `SECRET_KEY` environment variable is missing.'
  exit 1
fi

# Common settings
GIT_URL="https://${CLONE_TOKEN}@github.com/hausgold/settings.git"
DEST="$(mktemp -d)"

# Make sure to drop cloned settings in order to prevent unauthorized access to
# other sensible/secret data/information. Custom user defined actions, later in
# the Github Action workflow are prevented to access these information.
function cleanup() { rm -rf "${DEST}"; }
trap cleanup EXIT

# Fetch the settings repository (some day Github may
# allows server-side filtering)
(
  rm -rf "${DEST}"
  git clone \
    --no-checkout \
    --depth=1 \
    --filter=blob:none \
    --branch master \
    --single-branch \
    "${GIT_URL}" "${DEST}"
  git -C "${DEST}" config --local core.sparsecheckout true
  cat <<EOF >"${DEST}/.git/info/sparse-checkout"
!/*
/exe/
/apps/github-actions-commons.md*
/apps/${APP}.md*
/users/deployhausgold/id*
/Makefile
EOF
  git -C "${DEST}" checkout master
) > /dev/null

# Install the machine user SSH key for further organization access
(
  git config --global user.email 'deploy@hausgold.de'
  git config --global user.name 'deployhausgold'

  SETTINGS_SECRET_KEY="${SECRET_KEY}" \
    make -C "${DEST}" --no-print-directory \
      .decrypt-users-deployhausgold-id-rsa \
      .decrypt-users-deployhausgold-id-rsa-pub

  mkdir -p ${HOME}/.ssh
  cp "${DEST}/users/deployhausgold"/id* ${HOME}/.ssh/
  chmod 0600 ${HOME}/.ssh/id_rsa
  chmod 0644 ${HOME}/.ssh/id_rsa.pub
  cat >>${HOME}/.ssh/config <<EOF
Host github.com
  StrictHostKeyChecking no
EOF
  cat >>${HOME}/.ssh/setup <<EOF
ssh-add ~/.ssh/id_rsa
EOF
) > /dev/null

# Run the export environment variable helper to export the settings
APP_RECIPE="export-envs-$(${DEST}/exe/files-to-recipes <<< "${APP}")"
SETTINGS_SECRET_KEY="${SECRET_KEY}" \
  make -C "${DEST}" --no-print-directory \
    export-envs-github-actions-commons \
    "${APP_RECIPE}" \
      | cut -d' ' -f2- \
      | sort -u
