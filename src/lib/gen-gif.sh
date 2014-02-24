#!/bin/bash

MAX_FILE_SIZE=$((990 * 1000)) # 990 KB
MIN_FILE_SIZE=$((985 * 1000)) # 990 KB
MAX_SIDE=500
MIN_SIDE=230

function do_convert() {
    gen_gif $init_width

    local sides="$(get_geometry)"
    local base_width=$(cut -dx -f1 <<< "$sides")
    local base_height=$(cut -dx -f2 <<< "$sides")

    if [[ $base_width -eq $MAX_SIDE || $base_height -eq $MAX_SIDE ]] \
        && [[ $(stat -c%s "$output_gif") -lt $MAX_FILE_SIZE ]]; then
        echo "Success!"
        return 0
    fi

    if is_valid_sides $base_width $base_height && is_valid_size; then
        echo "Success!"
        return 0
    fi

    local width_history=
    local sides w h
    while true ; do
        sides="$(next_sides)"
        w=$(cut -dx -f1 <<< "$sides")
        h=$(cut -dx -f2 <<< "$sides")
        if grep -qF $w <<< "$width_history"; then
            echo "Width Convergence: ${w}x${h}"
            echo "Success?"
            return 0
        else
            width_history="$width_history $w"
        fi

        if ! is_valid_sides $w $h; then
            abort "Failure: delete some images on $WORKSPACE"
        fi

        gen_gif $w

        if is_valid_size; then
            break
        fi
    done

    echo "Success"
}

function is_valid_size() {
    local size=$(stat -c%s "$output_gif")
    [[ $size -lt $MAX_FILE_SIZE \
        && $size -gt $MIN_FILE_SIZE ]] || return 1
}
function is_valid_sides() {
    local width=$1
    local height=$2

    if [[ $width -gt $height ]]; then # the long side is width
        if [[ $width -gt $MAX_SIDE ]]; then
            echo "Too long width"
            return 1
        elif [[ $width -lt $MIN_SIDE ]]; then
            echo "Too short width"
            return 1
        fi
    else # the long side is height
        if [[ $height -gt $MAX_SIDE ]]; then
            echo "Too long height"
            return 1
        elif [[ $height -lt $MIN_SIDE ]]; then
            echo "Too short height"
            return 1
        fi
    fi
}
function get_geometry() {
    identify -format '%[fx:w]x%[fx:h]\n' "$output_gif" | head -n 1
    return ${PIPESTATUS[0]}
}
function get_width() {
    identify -format '%[fx:w]\n' "$output_gif" | head -n 1
    return ${PIPESTATUS[0]}
}
function get_size() {
    stat -c%s "$output_gif"
}

function next_sides() {
    local w=$(get_width "$output_gif")
    local s=$(get_size "$output_gif")
    local next_w=$(evenize $(bc -l <<< "sqrt($MAX_FILE_SIZE / $s) * $w"))
    if [[ $next_w -gt $MAX_SIDE ]]; then
        next_w=$MAX_SIDE
    fi
    next_h=$(((base_height * next_w) / base_width))
    if [[ $next_h -gt $MAX_SIDE ]]; then
        next_h=$MAX_SIDE
        next_w=$(((base_width * next_h) / base_height))
    fi

    echo ${next_w}x${next_h}
    width_history="$width_history $next_w"
}
function evenize() {
    local i=${1%.*}
    echo $((i / 2 * 2))
}

gen_counter=1
function gen_gif() {
    local width="$1"

    local delay=$((delay_factor * frame_interval))
    local arg="-delay $delay"
    local last_i=$(ls $WORKSPACE | wc -l)
    if [[ $((last_i % frame_interval)) -eq 0 ]]
    then last_i=$((last_i - frame_interval))
    else last_i=$(((last_i / frame_interval) * frame_interval))
    fi

    set +x
    local f i=0
    for f in $(ls $WORKSPACE | sort -n); do
        if [[ $((i % frame_interval)) -eq 0 ]]; then
            f="$WORKSPACE/$f"
            if [[ $i -eq $last_i ]]
            then arg="$arg -delay $last_delay '$f'"
            else arg="$arg '$f'"
            fi
        fi
        i=$((i + 1))
    done
    set_x

    echo_and_eval convert $arg -loop 0 \
        -geometry "${width}x" \
        -fuzz ${fuzz}% \
        -dither FloydSteinberg \
        -modulate "100,$saturation" \
        -layers optimize "$output_gif"

    local s="$(ls -sh "$output_gif"|tail -n 1|awk '{print $1}')"
    echo -e "#${gen_counter}\t$(get_geometry) \t${s}B";
    gen_counter=$((gen_counter + 1))
}

function echo_and_eval() {
    if $is_echo_convert
    then echo "$@"
    fi
    eval "$@"
}
