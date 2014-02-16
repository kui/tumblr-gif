#!/bin/bash -eu

function load_rc() {
    if [[ ! -f "$RC_FILE" ]]
    then create_rc
    fi

    debug "load $RC_FILE"

    . "$RC_FILE"
}

function create_rc() {
    echo "Create default config: $RC_FILE"

    if ! [[ "$0" =~ tumblr-gif ]]; then
        echo '#!/bin/bash -eu' > "$RC_FILE"
        return 0
    fi

    start=$(grep -Pn '##[S]TART_SAMPLE_CONF' $0 | cut -d: -f1)
    end=$(grep -Pn '##[E]ND_SAMPLE_CONF' $0 | cut -d: -f1)

    head -n $((end - 1)) $0 \
        | tail -n $((end - start - 1)) \
        | sed -e 's/^ *://' > "$RC_FILE"

    return 0

: '
:##START_SAMPLE_CONF
:#!/bin/bash -eu
:# -*- coding:utf-8; mode:sh; -*-
:
:###########################################################
:## env
:
:# export PATH="${HOME}/local/bin:${PATH}"
:# export LD_LIBRARY_PATH="${HOME}/local/lib:${LD_LIBRARY_PATH-}"
:
:###########################################################
:## hooks on each tasks
:
:after_view() { # argument: generated png file pathes
:    echo "generate $# PNG files"
:    xdg-open "$(dirname "$1")"
:}
:
:after_gen() { # artument: a generated gif path
:    xdg-open "$1"
:}
:##END_SAMPLE_CONF
'
}
