#!/bin/bash
#
# $1 - the target script to run
# $2 - Github token to use

# Die on any errors
set -e

if [ -z "${1}" ]; then
  echo 'Execution target ($1) is missing.'
  exit 1
fi

if [ -z "${2}" ]; then
  echo 'Github clone token ($1) is missing.'
  exit 1
fi

# Common settings
APP="${1}"
GIT_URL="https://${2}@github.com/hausgold/potpourri.git"
DEST='/tmp/potpourri'

# Just clone and build it once and use the cache on subsequent calls
if [ ! -d "${DEST}" ]; then
  # Fetch the potpourri repository (some day Github may
  # allows server-side filtering)
  (
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
  ) &> /dev/null
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

# Run the target command
bash "${DEST}/dist/actions/${1}"
