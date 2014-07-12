#!/bin/bash

function is_debug_enable() {
    [[ -n "${DEBUG-}" ]]
}
function debug() {
    if is_debug_enable
    then echo "$@"
    fi
}
function set_x() {
    if is_debug_enable
    then set -x
    fi
}

function abort() {
    err "$@"
    exit $(status_code "$*")
}
function status_code() {
    local c=$(hash_code 255 "$*")
    echo $((c + 1))
}
function hash_code() {
    local base=$1
    shift
    local s=$(sum <<< "$*" | cut -d' ' -f1)
    bc <<< "$s % $base"
}
function err() {
    echo -e "$@" >&2
}

function is_int() {
    [[ "$1" =~ [0-9]+ ]]
}

function clean_files() {
    rm -vrf -- "$WORKSPACE"/*
}
