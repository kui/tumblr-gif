
#!/bin/bash
# <help>generating and viewing png</help>

usage="Usage: $(basename "$0") view <video_file> <offset_time> <duration_sec>
  <offset_time>: HH:MM:SS or HH:MM:SS.ss"

if [[ $# -ne 3 ]]; then
    abort "$usage"
fi

clean_files

video_file="$1"
offset_time="$2"
duration_sec="$3"

mkdir -pv "$WORKSPACE"
avconv -r 30 -i "$video_file" -f image2 \
    -filter:v yadif -ss "$offset_time" -s '500x280' \
    -t "$duration_sec" "$WORKSPACE/%04d.png"

pngs=()
set +u
for p in $WORKSPACE/*.png; do
    if [[ -f "$p" ]]
    then pngs=("${pngs[@]}" "$p")
    fi
done

if [[ ${#pngs} -gt 0 ]]
then hook_after_view "${pngs[@]}"
else abort "ERROR: no png on '$WORKSPACE'"
fi
set -u
