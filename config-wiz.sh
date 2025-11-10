#!/data/data/com.termux/files/usr/bin/bash
CONFIG_DIR="$HOME/.config/termux-bootloader"
mkdir -p "$CONFIG_DIR"
prompt() {
    local var="$1" message="$2" default="$3"
    local current="${!var:-$default}"
    read -rp "$message [$default]: " input
    input="${input:-$current}"
    jq --arg option "$var" --arg value "$input" '.[$option] = $value' "$CONFIG_DIR/config.json" > "$CONFIG_DIR/tmp.json" && mv "$CONFIG_DIR/tmp.json" "$CONFIG_DIR/config.json"
}

clear
printf "\033[92m"
figlet -f big "Termux Bootloader"
printf "\n"
printf "\033[32m"
figlet -f mini "S e t u p   W i z a r d"
echo -e "\033[0m\n\n"
prompt figlet_text "What do you wish to set as the banner text" "Welcome to Termux!"
prompt figlet_args "Please enter what arguments you wish to feed to the figlet banner" "-f big"
while true; do
    read -p "Do you wish to allow further user changes: " multiple_users_prompt
    multiple_users_prompt=$(echo "$multiple_users_prompt" | tr '[:upper:]' '[:lower:]')
    case "$multiple_users_prompt" in
	y|yes|true) jq '.allow_user_changes = "true"' "$CONFIG_DIR/config.json" > "$CONFIG_DIR/tmp.json" && mv "$CONFIG_DIR/tmp.json" "$CONFIG_DIR/config.json"; break ;;
	n|no|false) jq '.allow_user_changes = "false"' "$CONFIG_DIR/config.json" > "$CONFIG_DIR/tmp.json" && mv "$CONFIG_DIR/tmp.json" "$CONFIG_DIR/config.json"; break ;;
	*)
	    echo "couldnt determine what you meant. continuing"
	    sleep 2.5
	    continue
	;;
    esac
    break
done
prompt selected_theme "Please enter a color for the selected column(All ANSI colors)" green
prompt unselected_theme "Please enter a color for the unselected columns(All ANSI colors)" white
prompt main_theme "Please enter a color for the banner(all ANSI colors)" green
