#!/bin/bash

function hook_after_view() {
    [[ $# -gt 0 ]] || return

    if type after_view &> /dev/null
    then after_view "$@"
    else echo "Generate png files: $@"
    fi
}

function hook_after_gen() {
    [[ $# -eq 1 ]] || return

    if type after_gen &> /dev/null
    then after_gen "$1"
    else echo "Build gif: $1"
    fi
}
