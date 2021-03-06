#!/bin/bash
# <help>generate gif which meets tumblr gif specification</help>

DEFAULT_INIT_WIDTH=500
DEFAULT_HALF_INIT_WIDTH=245

saturation=100
init_width=$DEFAULT_INIT_WIDTH
fuzz=1
frame_interval=3
last_delay=
delay_factor=3
blend_loop=0
cross_blend_loop=0
is_echo_convert=false
output_gif=
is_half=false
is_dither=false

usage="Usage: $(basename "$0") [<option> [ ... ] ] <output_gif>
    -s,--saturation NUM     :
        set this smaller NUM if tumblr return \"Error uploading image\".
        default: $saturation, max: 100, min: 1
    -w,--init-width NUM     : default: $init_width
    -f,--fuzz NUM           :
        set this larger NUM then a smaller gif was generated.
        default: $fuzz, max: 100, min: 0
    -i,--frame-interval NUM :
        set this larger NUM if tumblr return \"Error uploading image\".
        set this larger NUM then a smaller gif was generated.
        default: $frame_interval
    -l,--last-delay NUM     :
        set this larger NUM if you want a gif which has the last frame stop
        for NUM delay.
        default: delay-factor * frame-interval
    -b,--blend-loop NUM     :
        blending between the first frame and the last frame with NUM frame.
        '--cross-blend-loop NUM' will be ignored if you used this option.
        default: $blend_loop
    -c,--cross-blend-loop NUM     :
        blending between the first NUM frames and the last NUM frames.
        '--blend-loop NUM' will be ignored if you used this option.
        default: $cross_blend_loop
    -d,--dither             : with '-dither FloydSteinberg' option.
    --delay-factor NUM      :
        set this larger NUM if you want a gif with slower speed animation.
        default: $delay_factor
    --half                  :
        generate a gif which be the half size and
        the upper limit file size is 2MB.
    --echo-convert          : just output 'convert' cmmands. does not execute.
    -h,--help
"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--saturation)
            is_int "$2" || abort "$1 argument must integer: $2"
            saturation="$2"
            shift
            ;;
        -w|--init-width)
            is_int "$2" || abort "$1 argument must integer: $2"
            init_width="$2"
            shift
            ;;
        -f|--fuzz)
            is_int "$2" || abort "$1 argument must integer: $2"
            fuzz="$2"
            shift
            ;;
        -i|--frame-interval)
            is_int "$2" || abort "$1 argument must integer: $2"
            frame_interval=$2
            shift
            ;;
        -l|--last-delay)
            is_int "$2" || abort "$1 argument must integer: $2"
            last_delay=$2
            shift
            ;;
        --delay-factor)
            is_int "$2" || abort "$1 argument must integer: $2"
            delay_factor=$2
            shift
            ;;
        -b|--blend-loop)
            is_int "$2" || abort "$1 argument must integer: $2"
            blend_loop=$2
            shift
            ;;
        -c|--cross-blend-loop)
            is_int "$2" || abort "$1 argument must integer: $2"
            cross_blend_loop=$2
            shift
            ;;
        --echo-convert)
            is_echo_convert=true
            ;;
        --half)
            is_half=true
            if [[ $init_width -eq $DEFAULT_INIT_WIDTH ]]
            then init_width=$DEFAULT_HALF_INIT_WIDTH
            fi
            ;;
        -d|--dither)
            is_dither=true
            ;;
        -h|--help) abort "$usage" ;;
        -*) abort "unknown option: $1" ;;
        *)
            [[ -z "$output_gif" ]] || abort "invalid argument: $1"
            output_gif="$1"
            ;;
    esac
    shift
done

if [[ -z "$last_delay" ]]
then last_delay=$((delay_factor * frame_interval))
fi

if [[ -z "$output_gif" ]]
then abort "$usage"
fi

(
    for v in saturation init_width fuzz frame_interval last_delay delay_factor \
        blend_loop cross_blend_loop is_echo_convert is_half is_dither output_gif
    do eval echo "$v : \$$v"
    done
    echo -------------------
) | column -t

do_convert

hook_after_gen "$output_gif"
