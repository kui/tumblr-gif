#!/bin/bash
# <help>generate gif which meets tumblr gif specification</help>

usage="Usage: $(basename "$0") [<option> [ ... ] ] <output_gif>
    -s,--saturation NUM     :
        set this smaller NUM if tumblr return \"Error uploading image\".
        default: 95, max: 100, min: 1.
    -w,--init-width NUM     : default: 500
    -f,--fuzz NUM           :
        set this smaller NUM then a smaller gif was generated. default: 2.
    -i,--frame-interval NUM :
        set this larger NUM then a smaller gif was generated. default: 1.
    -l,--last-delay NUM     :
        set this larger NUM if you want a gif which has the last frame stop
        for NUM delay.
        default: ( delay-factor * frame-interval )
    --delay-factor NUM      :
        set this larger NUM if you want a gif at faster speed animation.
        default: 3
    --echo-convert          : output 'convert' cmmands
    -h,--help
"

saturation=95
init_width=500
fuzz=2
frame_interval=2
last_delay=
delay_factor=3
output_gif=
is_echo_convert=false

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
            frame_interval="$2"
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
        --echo-convert)
            is_echo_convert="true"
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
        is_echo_convert output_gif
    do eval echo "$v : \$$v"
    done
    echo ---------------
) | column -t

do_convert

hook_after_gen "$output_gif"
