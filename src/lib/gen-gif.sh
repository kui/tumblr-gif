#!/bin/bash


MAX_FILE_SIZE=$((995 * 1000)) # 998 KB
MIN_FILE_SIZE=$((990 * 1000)) # 990 KB
MAX_SIDE=500

function do_convert() {
    if $is_half
    then update_for_half_limits
    fi

    if [[ $MIN_FILE_SIZE -gt $MAX_FILE_SIZE ]]; then
        abort "ERROR: invalid MIN/MAX_FILE_SIZE: ${MIN_FILE_SIZE}/${MAX_FILE_SIZE}"
    elif [[ $(list_frames | wc -l) -lt $frame_interval ]]; then
        abort "ERROR: too less images"
    fi

    printf '  %s images, %sB (avg: %sKB)\n' \
        $(list_frames | wc -l) \
        $(du -sh $WORKSPACE | cut -f1) \
        $(bc <<< "$(du -s $WORKSPACE | cut -f1) / $(ls $WORKSPACE/* | wc -l)")

    rm_blendeds
    if [[ $blend_loop -gt 0 ]]; then
        gen_blendeds
    fi

    if $is_echo_convert; then
        echo "$(convert_cmd $init_width)"
        return 0
    fi

    gen_gif $init_width

    if is_valid_gif; then
        echo "Success!"
        return 0
    fi

    local width_history=$(get_width)
    local sides w
    while true ; do
        w=$(next_width)
        if grep -qF $w <<< "$width_history"; then
            echo "GIF width convergence: ${w}x"
            echo "Success?"
            return 0
        elif [[ $w -lt $((MAX_SIDE / 2 )) ]]; then
            abort "ERROR: Too large or many frames to make a GIF\nabort"
            return 1
        else
            width_history="$width_history $w"
        fi

        gen_gif $w

        if is_valid_gif; then
            break
        fi
    done

    echo "Success"
}

function update_for_half_limits() {
    MAX_FILE_SIZE=$((1998 * 1000)) # 1998 KB
    MIN_FILE_SIZE=$((1990 * 1000)) # 1990 KB
    MAX_SIDE=245
}

function list_frames() {
    ls -- $WORKSPACE | grep -vP '^__blended-\d+\.png$'
}
function rm_blendeds() {
    ls -- $WORKSPACE | grep -P '^__blended-\d+\.png$' | xargs -I{} rm $WORKSPACE/{}
}
function is_valid_gif() {
    local size=$(get_size)
    local geo=$(get_geometry)
    local width=$(cut -f1 -dx <<< $geo)
    local height=$(cut -f2 -dx <<< $geo)

    ( is_valid_sides $width $height && is_expected_size_range $size) \
        || ( is_max_sides $width $height && is_valid_size $size)
}
function is_valid_sides() {
    local w=$1 h=$2
    if [[ $w -gt $h ]]
    then [[ $w -le $MAX_SIDE ]]
    else [[ $h -le $MAX_SIDE ]]
    fi
}
function is_expected_size_range() {
    [[ $1 -le $MAX_FILE_SIZE \
        && $1 -ge $MIN_FILE_SIZE ]]
}
function is_max_sides() {
    local w=$1 h=$2
    if [[ $w -gt $h ]]
    then [[ $w -eq $MAX_SIDE ]]
    else [[ $h -eq $MAX_SIDE ]]
    fi
}
function is_valid_size() {
    [[ $1 -le $MAX_FILE_SIZE ]]
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
    local geo=$(get_geometry)
    local w=$(cut -f1 -dx <<< $geo)
    local h=$(cut -f2 -dx <<< $geo)
    local s=$(get_size)

    local next_w=$(evenize $(bc -l <<< "sqrt($MAX_FILE_SIZE / $s) * $w"))
    if [[ $next_w -gt $MAX_SIDE ]]; then
        next_w=$MAX_SIDE
    fi

    local next_h=$(((h * next_w) / w))
    if [[ $next_h -gt $MAX_SIDE ]]; then
        next_h=$MAX_SIDE
        next_w=$(((w * next_h) / h))
    fi

    echo ${next_w}
}
function evenize() {
    local i=${1%.*}
    echo $((i / 2 * 2))
}

function gen_blendeds() {
    local first_frame="$(get_first_frame)"
    local last_frame="$(get_last_frame)"
    local interval=$(( 100 / ( blend_loop + 1 ) ))
    local percent out
    for percent in $(seq $interval $interval $((100 - interval))); do
        out="$WORKSPACE/$(printf '__blended-%02d.png' $percent)"
        composite -blend $percent $first_frame $last_frame $out
    done
}
function get_first_frame() {
    echo "$WORKSPACE/$(list_frames | sort -n | head -n 1)"
}
function get_last_frame() {
    local last_i=$(list_frames | wc -l)
    if [[ $((last_i % frame_interval)) -eq 0 ]]
    then last_i=$((last_i - frame_interval))
    else last_i=$(((last_i / frame_interval) * frame_interval))
    fi

    set +x
    local f i=0
    for f in $(list_frames | sort -n); do
        if [[ $((i % frame_interval)) -eq 0 ]]; then
            f="$WORKSPACE/$f"
            if [[ $i -eq $last_i ]]; then
                echo "$f"
                break
            fi
        fi
        i=$((i + 1))
    done
    set_x
}

gen_counter=1
function gen_gif() {
    local width="$1"

    eval "$(convert_cmd $width)"

    local s="$(ls -sh "$output_gif"|tail -n 1|awk '{print $1}')"
    printf '#%d: %7s %4sB\n' $gen_counter $(get_geometry) $s;
    gen_counter=$((gen_counter + 1))
}
function list_blendeds() {
    ls -- "$WORKSPACE" | grep -P '^__blended-\d+\.png$'
}
function convert_cmd() {
    local width="$1"
    local delay=$((delay_factor * frame_interval))
    local arg="-delay $delay"
    local last_frame=$(get_last_frame)

    set +x
    local f i=0
    for f in $(list_frames | sort -n); do
        if [[ $((i % frame_interval)) -eq 0 ]]; then
            f="$WORKSPACE/$f"
            if [[ "$f" = "$last_frame" ]]
            then arg="$arg -delay $last_delay '$f'"
            else arg="$arg '$f'"
            fi
        fi
        i=$((i + 1))
    done
    set_x

    if [[ $blend_loop -gt 0 ]]; then
        arg="$arg -delay $delay"
        for f in $(list_blendeds | sort -n); do
            f="$WORKSPACE/$f"
            arg="$arg '$f'"
        done
    fi

    echo -n "convert $arg -loop 0 "
    echo -n "-geometry ${width}x "
    if $is_dither
    then echo -n "-dither FloydSteinberg "
    else echo -n "+dither "
    fi
    echo -n "-modulate 100,$saturation "
    if [[ $(bc <<< "$fuzz > 0") -eq 1 ]]
    then echo -n "-fuzz ${fuzz}% "
    fi
    echo -n "-layers OptimizeTransparency \"$output_gif\""
}
