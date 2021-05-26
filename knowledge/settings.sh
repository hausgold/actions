#!/bin/bash
#
# $1 - application name
# $2 - Github token to use

# Die on any errors
set -e

if [ -z "${1}" ]; then
  echo 'Application name ($1) is missing.'
  exit 1
fi

if [ -z "${2}" ]; then
  echo 'Github clone token ($1) is missing.'
  exit 1
fi

# Common settings
APP="${1}"
GIT_URL="https://${2}@github.com/hausgold/knowledge.git"
DEST='/tmp/knowledge'

# Fetch the knowledge repository (some day Github may
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
/.travis/
/infrastructure/apps/
/infrastructure/user/deployhausgold/id*
/Makefile
EOF
  git -C "${DEST}" checkout master
) &> /dev/null

# Install the machine user SSH key for further organization access
(
  mkdir -p ${HOME}/.ssh
  cp "${DEST}/infrastructure/user/deployhausgold"/id* \
    ${HOME}/.ssh/
  chmod 0600 ${HOME}/.ssh/id_rsa
  chmod 0644 ${HOME}/.ssh/id_rsa.pub
) &> /dev/null

# Run the export environment variable helper to export the settings
make -C "${DEST}" --no-print-directory "export-envs-${APP}" \
  | cut -d' ' -f2-
