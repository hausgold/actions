#!/bin/bash
#
# $1 - the target script to run
# $2 - Github token to use

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
  >&2 echo 'Execution target ($1) is missing.'
  exit 1
fi

if [ -z "${2}" ]; then
  >&2 echo 'Github clone token ($2) is missing.'
  exit 1
fi

# Common settings
APP="${1}"
GIT_URL="https://${2}@github.com/hausgold/potpourri.git"
DEST='/opt/hausgold/potpourri'

# Just clone and build it once and use the cache on subsequent calls
if [ ! -d "${DEST}" ]; then
  # Fetch the potpourri repository (some day Github may
  # allows server-side filtering)
  (
    mkdir -p "${DEST}"
    git clone \
      --no-checkout \
      --depth=1 \
      --filter=blob:none \
      --branch master \
      --single-branch \
      "${GIT_URL}" "${DEST}"
    git -C "${DEST}" checkout master

    # Run the export environment variable helper to export the settings
    make -C "${DEST}" --no-print-directory build-actions
  ) > /dev/null
else
  # We're running on a cached version of Potpourri, so we should check for
  # updates and where there are some, we rebuild the scripts accordingly
  mkdir -p "${DEST}/hooks"
  cat >"${DEST}/hooks/post-update" <<EOF
#!/bin/bash
echo 'Rebuild the potpourri cache after update..'
make build-actions
EOF
  chmod +x "${DEST}/hooks/post-update"
  git -C "${DEST}" pull
fi

# Run the Github Actions pre-prepare script
bash "${DEST}/dist/actions/ci-pre-target"

# Run the target command
bash "${DEST}/dist/actions/${1}"

# Run the Github Actions post-prepare script
bash "${DEST}/dist/actions/ci-post-target"
