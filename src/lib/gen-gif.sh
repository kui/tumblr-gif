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

    local w h
    while true ; do
        w=$(next_width)
        h=$(((base_height * w) / base_width))

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
    [[ $(stat -c%s "$output_gif") -lt $MAX_FILE_SIZE \
        && $(stat -c%s "$output_gif") -gt $MIN_FILE_SIZE ]] || return 1
}
function is_valid_sides() {
    local width=$1
    local height=$2

    if [[ $width -gt $height ]]; then # the long side is width
        [[ $width -le $MAX_SIDE ]] || (echo "Too long width"; return 1)
        [[ $width -ge $MIN_SIDE ]] || (echo "Too short width"; return 1)
    else # the long side is height
        [[ $height -le $MAX_SIDE ]] || (echo "Too long height"; return 1)
        [[ $height -ge $MIN_SIDE ]] || (echo "Too short height"; return 1)
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

function next_width() {
    local w=$(get_width "$output_gif")
    local s=$(get_size "$output_gif")
    # echo "sqrt(($MAX_FILE_SIZE - $offset) / ($s - $offset)) * $w" >&2
    # evenize $(bc -l <<< "sqrt(($MAX_FILE_SIZE - $offset) / ($s - $offset)) * $w")
    evenize $(bc -l <<< "sqrt($MAX_FILE_SIZE / $s) * $w")
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
    last_i=$(((last_i / frame_interval)  * frame_interval))
    last_i=$((last_i - frame_interval))

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
