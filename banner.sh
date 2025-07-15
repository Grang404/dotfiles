#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'
clear
print_with_delay() {
    local text="$1"
    local delay="${2:-0.005}"
    local color="${3:-$WHITE}"
    echo -en "$color"
    for ((i = 0; i < ${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo -e "$NC"
}
print_ascii_art() {
    center_ascii "$1" 0.001
}
print_border() {
    local color="$1"
    local width=80
    local delay="${2:-0.005}"
    echo -e "$color"
    for ((i = 0; i < width; i++)); do
        echo -n "═"
        sleep "$delay"
    done
    echo -e "$NC"
}
center_text() {
    local text="$1"
    local color="${2:-$WHITE}"
    local delay="${3:-0.005}"
    local width=80
    local padding=$(((width - ${#text}) / 2))
    echo -e "$color"
    printf '%*s' $padding ''
    print_with_delay "$text" "$delay" "$color"
    echo -e "$NC"
}
center_ascii() {
    local color="$1"
    local delay="${2:-0.001}"
    echo -e "$color"
    while IFS= read -r line; do
        local width=80
        local line_length=${#line}
        local padding=$(((width - line_length) / 2))
        printf '%*s' $padding ''
        for ((i = 0; i < ${#line}; i++)); do
            echo -n "${line:$i:1}"
            sleep "$delay"
        done
        echo
    done <<'EOF'
                                                                
 @@@@@@@@  @@@@@@@    @@@@@@    @@@@@@   @@@@@@@                
@@@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@  @@@@@@@@               
!@@        @@!  @@@  @@!  @@@  @@!  @@@  @@!  @@@               
!@!        !@!  @!@  !@!  @!@  !@!  @!@  !@   @!@               
!@! @!@!@  @!@!!@!   @!@  !@!  @!@  !@!  @!@!@!@                
!!! !!@!!  !!@!@!    !@!  !!!  !@!  !!!  !!!@!!!!               
:!!   !!:  !!: :!!   !!:  !!!  !!:  !!!  !!:  !!!               
:!:   !::  :!:  !:!  :!:  !:!  :!:  !:!  :!:  !:!               
 ::: ::::  ::   :::  ::::: ::  ::::: ::   :: ::::               
 :: :: :    :   : :   : :  :    : :  :   :: : ::                
                                                                
                                                                
@@@  @@@  @@@   @@@@@@   @@@@@@@   @@@@@@   @@@       @@@       
@@@  @@@@ @@@  @@@@@@@   @@@@@@@  @@@@@@@@  @@@       @@@       
@@!  @@!@!@@@  !@@         @@!    @@!  @@@  @@!       @@!       
!@!  !@!!@!@!  !@!         !@!    !@!  @!@  !@!       !@!       
!!@  @!@ !!@!  !!@@!!      @!!    @!@!@!@!  @!!       @!!       
!!!  !@!  !!!   !!@!!!     !!!    !!!@!!!!  !!!       !!!       
!!:  !!:  !!!       !:!    !!:    !!:  !!!  !!:       !!:       
:!:  :!:  !:!      !:!     :!:    :!:  !:!   :!:       :!:      
 ::   ::   ::  :::: ::      ::    ::   :::   :: ::::   :: ::::  
:    ::    :   :: : :       :      :   : :  : :: : :  : :: : :  
EOF
    echo -e "$NC"
}

mpg123 -q --scale 1500 doom.mp3 &
MUSIC_PID=$!

display_startup() {
    print_border "$CYAN" 0.005
    echo
    center_ascii "$RED" 0.001
    echo
    print_border "$CYAN" 0.005
    echo
}

cleanup() {

    kill $MUSIC_PID 2>/dev/null
}

display_startup

trap cleanup EXIT
trap cleanup SIGINT
trap cleanup SIGTERM
trap cleanup SIGHUP

sleep 200
kill $MUSIC_PID 2>/dev/null
