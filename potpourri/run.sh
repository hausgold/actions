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
  # Fetch the knowledge repository (some day Github may
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
fi

# Run the target command
bash "${DEST}/dist/actions/${1}"
