#!/data/data/com.termux/files/usr/bin/bash
echo "# If this script runs and tells you what you selected the main script will fully work too"

options=("Login" "Manage Users" "Settings" "Exit")
current=0
last_drawn=-1 

draw_menu() {
    if [ $last_drawn -ge 0 ]; then
        for ((i=0; i<${#options[@]}; i++)); do
            echo -ne "\033[A\033[2K"
        done
    fi

    for i in "${!options[@]}"; do
        if [ $i -eq $current ]; then
            echo -e "➤ ${options[$i]}"
        else
            echo "  ${options[$i]}"
        fi
    done

    last_drawn=${#options[@]}
}

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
