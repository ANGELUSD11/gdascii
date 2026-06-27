ESC=$'\033'
RESET="${ESC}[0m"
CYAN="${ESC}[96m"
YELLOW="${ESC}[93m"
GREEN="${ESC}[92m"
RED="${ESC}[91m"
GRAY="${ESC}[90m"
BOLD="${ESC}[1m"

WIDTH=68
HEIGHT=17
GROUND=13          
FRAME_DELAY=0.05
loops="${1:-0}"  

OUT_SQ=(
'.---------.'
'|         |'
'|         |'
'|         |'
"'---------'"
)
OUT_DI=(
'    /     \    '
'   /       \   '
'  /         \  '
' /           \ '
'  \         /  '
'   \       /   '
'    \     /    '
)

FACE0=(            
'           '
'  ##   ##  '
'           '
'  #######  '
'           '
)
FACE2=(           
'             '
'  ##    ###  '
'        ###  '
'  ##    ###  '
'             '
)
FACE1=(            
'              '
'              '
'      # #     '
'    #######   '
'              '
'              '
'              '
)
FACE3=(            
'              '
'              '
'    #######   '
'      # #     '
'              '
'              '
'              '
)

SPIKE=(
'  /\  '
' /  \ '
'/____\'
)
SPIKE_W=6
SPIKE_H=3

declare -a CH CL

clear_canvas() {
    local total=$(( WIDTH * HEIGHT )) i
    for (( i = 0; i < total; i++ )); do
        CH[i]=' '
        CL[i]=''
    done
}

stamp() {
    local x=$1 y=$2 color=$3; shift 3
    local sprite=( "$@" )
    local row line c ch ry rx idx
    for row in "${!sprite[@]}"; do
        line="${sprite[$row]}"
        ry=$(( y + row ))
        (( ry < 0 || ry >= HEIGHT )) && continue
        for (( c = 0; c < ${#line}; c++ )); do
            ch="${line:c:1}"
            [[ "$ch" == ' ' ]] && continue
            rx=$(( x + c ))
            (( rx < 0 || rx >= WIDTH )) && continue
            idx=$(( ry * WIDTH + rx ))
            CH[idx]="$ch"
            CL[idx]="$color"
        done
    done
}

draw_ground() {
    local c idx
    for (( c = 0; c < WIDTH; c++ )); do
        idx=$(( GROUND * WIDTH + c ))
        CH[idx]='='; CL[idx]="$GREEN"
        idx=$(( (GROUND + 1) * WIDTH + c ))
        CH[idx]='#'; CL[idx]="$GRAY"
    done
}

draw_cube() {
    local center=$1 h=$2 idx=$3
    local fw fh left top
    local -a OUT FACE

    (( h == 0 )) && idx=0          

    case $idx in
        0) OUT=( "${OUT_SQ[@]}" ); FACE=( "${FACE0[@]}" ); fw=13; fh=5 ;;
        1) OUT=( "${OUT_DI[@]}" ); FACE=( "${FACE1[@]}" ); fw=15; fh=7 ;;
        2) OUT=( "${OUT_SQ[@]}" ); FACE=( "${FACE2[@]}" ); fw=13; fh=5 ;;
        3) OUT=( "${OUT_DI[@]}" ); FACE=( "${FACE3[@]}" ); fw=15; fh=7 ;;
    esac

    left=$(( center - fw / 2 ))
    top=$(( GROUND - fh - h ))
    stamp "$left" "$top" "$YELLOW$BOLD" "${OUT[@]}"   
    stamp "$left" "$top" "$CYAN$BOLD"   "${FACE[@]}"   
}

render() {
    local r c idx col ch prev line out=''
    for (( r = 0; r < HEIGHT; r++ )); do
        line=''; prev='__none__'
        for (( c = 0; c < WIDTH; c++ )); do
            idx=$(( r * WIDTH + c ))
            col="${CL[idx]}"; ch="${CH[idx]}"
            if [[ "$col" != "$prev" ]]; then
                line+="${col:-$RESET}"; prev="$col"
            fi
            line+="$ch"
        done
        out+="${line}${RESET}"$'\n'
    done
    printf '%s' "$out"
}

jump_height() {
    local center=$1 x=$2
    local maxh=6 span=11
    local d=$(( x - center ))
    (( d < 0 )) && d=$(( -d ))
    (( d > span )) && { echo 0; return; }
    local h=$(( maxh - (maxh * d * d) / (span * span) ))
    (( h < 0 )) && h=0
    echo "$h"
}

cleanup() {
    printf '%s' "${ESC}[?25h"
    printf '%s\n' "${RESET}"
    tput cnorm 2>/dev/null
    exit 0
}
trap cleanup INT TERM EXIT

printf '%s' "${ESC}[2J${ESC}[?25l"
tput civis 2>/dev/null

SPIKE_X=$(( WIDTH - 24 ))
SPIKE_GROUND_Y=$(( GROUND - SPIKE_H ))
TAKEOFF=$(( SPIKE_X + (3 * SPIKE_W) / 2 ))   

count=0
while :; do
    spin=0
    for (( center = -6; center <= WIDTH + 6; center++ )); do
        clear_canvas
        draw_ground

        stamp "$SPIKE_X"                   "$SPIKE_GROUND_Y" "$RED$BOLD" "${SPIKE[@]}"
        stamp "$(( SPIKE_X + SPIKE_W ))"   "$SPIKE_GROUND_Y" "$RED$BOLD" "${SPIKE[@]}"
        stamp "$(( SPIKE_X + 2*SPIKE_W ))" "$SPIKE_GROUND_Y" "$RED$BOLD" "${SPIKE[@]}"

        h=$(jump_height "$TAKEOFF" "$center")
        if (( h > 0 )); then
            spin=$(( spin + 1 ))           
        else
            spin=0
        fi
        idx=$(( (spin / 2) % 4 ))
        draw_cube "$center" "$h" "$idx"

        printf '%s[H   %s%s★  gdascii  ★%s\n' \
            "$ESC" "$BOLD" "$CYAN" "$RESET"
        render
        printf '   %sCtrl+C to exit%s' "$GRAY" "$RESET"

        sleep "$FRAME_DELAY"
    done

    (( count++ ))
    (( loops > 0 && count >= loops )) && break
done

cleanup
