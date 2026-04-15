#!/data/data/com.termux/files/usr/bin/bash

printf "This script is not finished. running old-config-wiz.sh..."
exec ./old-config.wiz.sh
printf "%bWarning%b: if this script errors for no reason use my old config-wiz.sh" "\033[93m" "\033[0m"

declare -A dep
declare -A depreq
declare -A depopt

for c in jq figlet sha256sum awk; do
    command -v $c >/dev/null 2>&1 && dep[$c]=y || dep[$c]=n
done

# *not recommended* optionally set a custom directory for the tmp json with 'TMPDIR=/path/to/tmpdir ./config-wiz.sh'
TMPJSON="$(mktemp)"

depreq[sha256sum]=coreutils
depreq[awk]=gawk

depopt[sudo]=sudo
depopt[su]=util-linux
depopt[tput]=ncurses-utils
depopt[nano]=nano

alias depinst='pkg install'

menu() {
    local options=("$@")
    local current=0 key
    local last_lines=0
    draw_menu() {
	    tput civis
        tput cup 0 0
        printf "%b" "\033[32m"
        figlet $figlet_args "$figlet_text"
        local line_count=0
        for i in "${!options[@]}"; do
            tput el
            if [[ $i == $current ]]; then
                printf "%b➤ %s%b\n" "\033[32m" "${options[$i]}" "\033[97m"
            else
                printf "  %b%s\n" "\033[97m" "${options[$i]}"
            fi
            ((line_count++))
        done
        for ((i=line_count;i<last_lines;i++)); do
            tput el
            echo
        done
        last_lines=$line_count
    }

    while true; do
        draw_menu
        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.05 key || key=""
            case "$key" in
                "[A") ((current--));;
                "[B") ((current++));;
            esac
        elif [[ $key == "" ]]; then
            selected="${options[$current]}"
            return 0
        fi
        (( current < 0 )) && current=$((${#options[@]} - 1))
        (( current >= ${#options[@]} )) && current=0
    done
}

writejsonconf() {
    [ -z "$(cat $CONFIG_FILE)" ] && printf "{}" > "$CONFIG_FILE"
    jq -e '.users' "$CONFIG_FILE" >/dev/null 2>&1 || jq '.users = []' "$CONFIG_FILE" > "$TMPJSON"
}

finish() {
    mv "$TMPJSON" "$CONFIG_FILE"
}

depmenu() {
    
}
configmenu() {

}

main_menu() {
    while true; do
        menu "Configuration" "Dependencies" "Finish"
        case "$selected" in
            "Configuration") configmenu ;;
            "Dependencies") depmenu ;;
            "Finish") finish ;;
        esac
    done
}
