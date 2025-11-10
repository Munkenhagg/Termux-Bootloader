#!/data/data/com.termux/files/usr/bin/bash

options=("Login" "Manage Users" "Settings" "Exit")
current=0
last_drawn=-1  # no lines drawn yet

draw_menu() {
    # If we already drew the menu, erase previous lines
    if [ $last_drawn -ge 0 ]; then
        for ((i=0; i<${#options[@]}; i++)); do
            echo -ne "\033[A\033[2K"  # move up & clear line
        done
    fi

    for i in "${!options[@]}"; do
        if [ $i -eq $current ]; then
            echo -e "➤ ${options[$i]}"
        else
            echo "  ${options[$i]}"
        fi
    done

    last_drawn=${#options[@]}  # remember how many lines we drew
}

# Initial draw
echo "Use ↑ ↓ to move, Enter to select:"
draw_menu

while true; do
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.1 rest
        key+="$rest"
    fi

    case "$key" in
        $'\x1b[A') ((current--)); ((current<0)) && current=$((${#options[@]}-1)) ;;
        $'\x1b[B') ((current++)); ((current>=${#options[@]})) && current=0 ;;
        "") echo "You selected: ${options[$current]}"; break ;;
    esac

    draw_menu
done
