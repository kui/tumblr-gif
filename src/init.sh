#!/bin/bash

set -eu

if [[ -z "${WORKSPACE-}" ]]; then
    WORKSPACE=/tmp/tumblr-gif
fi

if [[ -z "${RC_FILE-}" ]]; then
    RC_FILE="$HOME/.tumblr-gif-rc.sh"
fi
