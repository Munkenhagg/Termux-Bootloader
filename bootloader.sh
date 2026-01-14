#!/data/data/com.termux/files/usr/bin/bash
reload() {
    clear
    CONFIG_FILE="$HOME/.config/termux-bootloader/config.json"
    figlet_args="$(jq -r '.figlet_args' "$CONFIG_FILE")"
    figlet_text="$(jq -r '.figlet_text' "$CONFIG_FILE")"
    selected_theme="$(jq -r '.selected_theme' "$CONFIG_FILE")"
    unselected_theme="$(jq -r '.unselected_theme' "$CONFIG_FILE")"
    main_theme="$(jq -r '.main_theme' "$CONFIG_FILE")"
    users="$(jq -r '.users[] | .id' "$CONFIG_FILE")"
    salt="qSvZ6su1dOeOEeOExVXBxVIYGIQOWX92SpGPL2WeMWXJ59nQRSqbf7WPM"
    owner_count="$(jq '[.users[] | select(.permission=="owner")] | length' "$CONFIG_FILE")"
    SHELL="$(jq -r '.shell' "$CONFIG_FILE")"
    themefind() {
        local color="$1"
        color="$(echo "$color" | tr '[:upper:]' '[:lower:]')"
        case "$color" in
            black) echo -e "\033[30m" ;;
            red) echo -e "\033[31m" ;;
            green) echo -e "\033[32m" ;;
            yellow) echo -e "\033[33m" ;;
            blue) echo -e "\033[34m" ;;
            magenta) echo -e "\033[35m" ;;
            cyan) echo -e "\033[36m" ;;
            white) echo -e "\033[37m" ;;
            brightblack) echo -e "\033[90m" ;;
            brightred) echo -e "\033[91m" ;;
            brightgreen) echo -e "\033[92m" ;;
            brightyellow) echo -e "\033[93m" ;;
            brightblue) echo -e "\033[94m" ;;
            brightmagenta) echo -e "\033[95m" ;;
            brightcyan) echo -e "\033[96m" ;;
            brightwhite) echo -e "\033[97m" ;;
            *) echo -e "\033[0m" ;;
         esac
    }
    selected_theme=$(themefind "$selected_theme")
    unselected_theme=$(themefind "$unselected_theme")
    main_theme=$(themefind "$main_theme")
}

reload

ShowError() {
    clear
	local SEVERITY="$1"
	case "$SEVERITY" in
		"1") SEVERITY="non-severe" ;;
		"2") SEVERITY="moderate" ;;
		"3") SEVERITY="Severe" ;;
	esac
	local DESC="$2"
	local figlet_text="Error"
	menu "Continue" "Info"
	local option="$selected"
	unset selected
	case "$option" in
		"Continue") return ;;
		"Info")
            trap 'break' SIGINT
            while true; do
                clear
                echo -en "$main_theme"
                figlet -f big "Info"
                echo -en "$\n${DESC:-Unknown error}\n\n${SEVERITY}\n"
                echo -en "\nPress CTRL + C to Continue"
                sleep 120
            done
            trap - SIGINT
            clear
            return
        ;;
	esac
}

menu() {
    local options=("$@")
    local current=0 key
    local last_lines=0
    draw_menu() {
	tput civis
        tput cup 0 0
        printf "${main_theme}"
        figlet $figlet_args "$figlet_text"
        local line_count=0
        for i in "${!options[@]}"; do
            tput el
            if [[ $i == $current ]]; then
                echo -e "➤ ${selected_theme}${options[$i]}${unselected_theme}"
            else
                echo "  ${options[$i]}"
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

main_menu() {
    while true; do
        menu "Login" "Manage Users" "Settings" "Advanced Options"
        case "$selected" in
            "Login") run_login  ;;
            "Manage Users") manage_users ;;
            "Settings") manage_settings ;;
            "Advanced Options") advanced_options ;;
        esac
    done
}

manage_users_pre() {
    clear
    menu $users "Back"
    [ "$selected" = "Back" ] && return
    echo "$selected"
}

manage_users() {
    clear
    menu "Add user" "Delete user" "Back"
    [ "$selected" = "Back" ] && return
    local selected_user_op="$selected"
    unset selected
    clear
    printf "$main_theme"
    figlet $figlet_args "$figlet_text"
    case "$selected_user_op" in
	"Add user")
	    read -p "Enter a ID: " new_id
	    read -sp "Enter a password: " new_password
	    echo
	    read -p "Enter the new user's permission: " new_permission
	    read -sp "Confirm the new password: " new_confirm_pass
	    echo
	    if [ "$new_password" = "$new_confirm_pass" ]; then
	    	local hash="$(printf "%s%s" "$salt" "$new_confirm_pass" | sha256sum | awk '{print $1}')"
			jq --arg id "$new_id" \
   			--arg pass "$hash" \
	   		--arg perm "$new_permission" \
   			'.users += [{"id": $id, "password": $pass, "permission": $perm}]' \
   			"$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
			reload
			clear
			return
	    else
			echo "Passwords do not match."; unset selected_user_op; return
	    fi
	    ;;
	"Delete user")
	    clear
	    manage_users_pre
        [ "$selected" = "Back" ] && return
	    selected_user="$selected"
        unset selected
	    local perm=$(jq -r --arg id "$selected_user" '.users[] | select(.id == $id) | .permission' "$CONFIG_FILE")
	    if [ "$perm" = "owner" ] && [ "$owner_count" -le 1 ]; then
			echo "Cannot delete all owners!"
			sleep 3.5
			return
	    else
			echo -en "Enter password for \033[4m${selected_user}\033[0m: "
			read delete_inputpass
	    fi
	    local delete_real_pass="$(get_user_password)"
	    local delete_inputpass="$(printf "%s%s" "$salt" "$delete_inputpass" | sha256sum | awk '{print $1}')"
	    if [ "$delete_real_pass" = "$delete_inputpass" ]; then
			local randomconfirm="$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 12)"
			echo "$randomconfirm"
			read -p "Enter the code above to remove this user: " randomconfirm_input
			[ "$randomconfirm" = "$randomconfirm_input" ] && jq --arg id "$selected_user" 'del(.users[] | select(.id == $id))' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
			clear
			reload
			return
	    else
			echo "Password does not match."
			sleep 4.5
            unset selected_user
			return
	    fi
	;;
    esac
}

userperm_menu() {
    clear
    [ ! "$CURRENT_PERM" = "owner" ] && ShowError 1 "You must be logged in as a owner to change others permission" && return
    menu $users "Back"
    local selected_user="$selected"
    [ "$selected" = "Back" ] && return
    unset selected
    menu "Owner" "Member" "Back"
    local selected_permission="$selected"
    unset selected
    [ "$selected_permission" = "Back" ] && return
    if [ "$(jq -r --arg id "$selected_user" '.users[] | select(.id==$id) | .permission' "$CONFIG_FILE")" = "owner" ] && [ "$owner_count" -le 1 ]; then
        ShowError 1 "Cannot have zero owners!"
    else
        jq --arg id "$selected_user" --arg perm "$selected_permission" '.users |= map(if .id==$id then .permission=$perm else . end)' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
    fi
}

manage_settings() {
    clear
    while true; do
		menu "Manually edit config.json(unsafe)" "Manage a User's Permission" "Back"
		case "$selected" in
		    "Manually edit config.json(unsafe)")
                if [ "$CURRENT_PERM" = "owner" ]; then
                    nano "$CONFIG_FILE" || sudo nano "$CONFIG_FILE" || su -c "$CONFIG_FILE"
                else
                    ShowError 1 "You must be logged in as a owner to edit the config"
                fi
            ;;
            "Manage a User's Permission") userperm_menu ;;
	    	"Back") clear; return ;;
		esac
    done
}

get_user_password() {
    jq -r --arg user "$selected_user" '.users[] | select(.id == $user) | .password' "$CONFIG_FILE"
}

run_login() {
    while true; do
	    clear
	    menu $users "Back"
	    if [ "$selected" = "Back" ]; then
	        return
	    fi
	    local selected_user="$selected"
	    local CURRENT_PASS="$(get_user_password)"
	    read -sp "${main_theme}  Enter password for ${selected_user}" inputpass
	    local inputpass="$(printf "%s%s" "$salt" "$inputpass" | sha256sum | awk '{print $1}')"
	    if [ ! "$inputpass" = "$CURRENT_PASS" ]; then
	        echo -e "${main_theme}\nwrong password. retry\n\033[0m"
	        sleep 3
	        continue
	    else
            CURRENT_USER="$selected_user"
            CURRENT_PERM="$(jq -r --arg user "$CURRENT_USER" '.users[] | select(.id == $user) | .permission' "$CONFIG_FILE")"
	    fi
    done
}

advanced_options() {
    while true; do 
        clear
        menu "Temporary Shell" "Reload Configs" "Back"
        case "$selected" in
            "Temporary Shell")
                while true; do
                    echo -en "\n${main_theme}Please enter a shell to use: "
                    read SHELL
                    if [ -n "$SHELL" ] && command -v "$SHELL" >/dev/null 2>&1; then
                         echo -en "\033[1A\033[2K"
                        return
                    else
                        echo "Invalid shell!"
                        sleep 3.5
                        echo -en "\033[1A\033[2K\033[1A\033[2K"
                        continue
                    fi
                done
            ;;
            "Reload Configs") reload ;;
            "Back") clear; return ;;
        esac
    done
}
main_menu