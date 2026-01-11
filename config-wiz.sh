#!/data/data/com.termux/files/usr/bin/bash
CONFIG_DIR="$HOME/.config/termux-bootloader"
CONFIG_FILE="$CONFIG_DIR/config.json"
mkdir -p "$CONFIG_DIR"
if [ ! -s "$CONFIG_FILE" ]; then
  echo '{}' > "$CONFIG_FILE"
fi
if [ -z "$(cat $CONFIG_FILE | grep 'users')" ]; then
	jq '.users = []' "$CONFIG_DIR/config.json" > "$CONFIG_DIR/tmp.json" && mv "$CONFIG_DIR/tmp.json" "$CONFIG_DIR/config.json"
fi
prompt() {
    local var="$1" message="$2" default="$3"
    local current="${!var:-$default}"
    read -rp "$message [$default]: " input
    input="${input:-$current}"
    jq --arg option "$var" --arg value "$input" '.[$option] = $value' "$CONFIG_DIR/config.json" > "$CONFIG_DIR/tmp.json" && mv "$CONFIG_DIR/tmp.json" "$CONFIG_FILE"
}

clear
printf "\033[92m"
figlet -f big "Termux Bootloader"
printf "\n"
printf "\033[32m"
figlet -f mini "S e t u p   W i z a r d"
echo -e "\033[0m\n\n"
prompt figlet_text "What do you wish to set as the banner text" "Termux Bootloader"
prompt figlet_args "Please enter what arguments you wish to feed to the figlet banner" "-f big"
prompt selected_theme "Please enter a color for the selected column(All ANSI colors)" green
prompt unselected_theme "Please enter a color for the unselected columns(All ANSI colors)" white
prompt main_theme "Please enter a color for the banner(all ANSI colors)" green
while true; do
	prompt shell "Please enter the default shell after login" bash
	shell="$(jq -r '.shell' "$CONFIG_FILE")"
	if command -v "$shell"; then
		break
	else
		echo "Shell not found!"
		sleep 1.8
	fi
done
