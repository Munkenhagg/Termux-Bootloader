#!/data/data/com.termux/files/usr/bin/bash
echo "# guaranteed to work with a working bash setup"
options=("Login" "Manage Users" "Settings" "Exit")
current=0
last_drawn=-1  # no lines drawn yet

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

echo "Use w/s to move, Enter to select:"
draw_menu

while true; do
    read -rsn1 key
    case "$key" in
        w|W) ((current--)); ((current<0)) && current=$((${#options[@]}-1)) ;;
        s|S) ((current++)); ((current>=${#options[@]})) && current=0 ;;
        "") echo "You selected: ${options[$current]}"; break ;;
    esac
    draw_menu
done
