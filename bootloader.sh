#!/data/data/com.termux/files/usr/bin/bash
readsilp () {
    local VAR="$1"
    shift
    printf "$@"
    stty -echo
    read "$VAR"
    stty echo
    printf "\n"
}

owner_count() {
    jq '[.users[] | select(.permission=="owner")] | length' "$CONFIG_FILE"
}

reload() {
    clear
    CONFIG_FILE="$HOME/.config/termux-bootloader/config.json"
    figlet_args="$(jq -r '.figlet_args' "$CONFIG_FILE")"
    figlet_text="$(jq -r '.figlet_text' "$CONFIG_FILE")"
    selected_theme="$(jq -r '.selected_theme' "$CONFIG_FILE")"
    unselected_theme="$(jq -r '.unselected_theme' "$CONFIG_FILE")"
    main_theme="$(jq -r '.main_theme' "$CONFIG_FILE")"
    users="$(jq -r '.users[] | .id' "$CONFIG_FILE")"
    SHELL="$(jq -r '.shell' "$CONFIG_FILE")"
    LOGFILE="$(jq -r '.logfile' "$CONFIG_FILE")"
    themefind() {
        local color="$1"
        color="$(echo "$color" | tr '[:upper:]' '[:lower:]')"
        case "$color" in
            black) printf "\033[30m" ;;
            red) printf "\033[31m" ;;
            green) printf "\033[32m" ;;
            yellow) printf "\033[33m" ;;
            blue) printf "\033[34m" ;;
            magenta) printf "\033[35m" ;;
            cyan) printf "\033[36m" ;;
            white) printf "\033[37m" ;;
            brightblack) printf "\033[90m" ;;
            brightred) printf "\033[91m" ;;
            brightgreen) printf "\033[92m" ;;
            brightyellow) printf "\033[93m" ;;
            brightblue) printf "\033[94m" ;;
            brightmagenta) printf "\033[95m" ;;
            brightcyan) printf "\033[96m" ;;
            brightwhite) printf "\033[97m" ;;
            *) printf "\033[0m" ;;
         esac
    }
    selected_theme=$(themefind "$selected_theme")
    unselected_theme=$(themefind "$unselected_theme")
    main_theme=$(themefind "$main_theme")
}
reload

diffU() {
    "$@" || sudo "$@" || su -c "$*" 
}

log() {
    date "+[%Y:%m:%d %H:%M:%S]" > "$LOGFILE"
    printf "%s" "$@" > "$LOGFILE"
}
ShowError() {
    clear
	local SEVERITY="$1"
	case "$SEVERITY" in
		"1") SEVERITY="Info" ;;
		"2") SEVERITY="Warning" ;;
		"3") SEVERITY="Fatal" ;;
	esac
	local DESC="$2"
	local figlet_text="Error"
	menu "Continue" "Info"
	local option="$selected"
	unset selected
	case "$option" in
		"Continue") return ;;
		"Info")
            clear
            printf "%b" "$main_theme"
            figlet -f big "Info"
            printf "\n%s\n\nSeverity: %s\n" "${DESC:-Unknown error}" "$SEVERITY"
            echo "Press any key to continue"
            read -rsn1
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
                printf "%b➤ %s%b\n" "$selected_theme" "${options[$i]}" "$unselected_theme"
            else
                printf "  %b%s\n" "$unselected_theme" "${options[$i]}"
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
        menu "Login" "Enter Shell" "Manage Users" "Settings" "Advanced Options"
        case "$selected" in
            "Enter Shell") enter_shell ;;
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
    menu "Add user" "Delete user" "My Info" "Back"
    [ "$selected" = "Back" ] && return
    local selected_user_op="$selected"
    unset selected
    clear
    printf "$main_theme"
    figlet $figlet_args "$figlet_text"
    case "$selected_user_op" in
	"Add user")
	    printf "Enter a ID: "
        read new_id
	    readsilp new_password "Enter a password: "
        readsilp new_confirm_pass "Confirm the new password: "
	    echo
        menu "owner" "member" "guest"
        local new_permission="$selected"
        unset selected
	    echo
        local salt="$(head -c 16 /dev/urandom | base64)"
	    if [ "$new_password" = "$new_confirm_pass" ]; then
	    	local pass="$(printf "%s%s" "$salt" "$new_confirm_pass" | sha256sum | awk '{print $1}')"
			jq --arg id "$new_id" --arg pass "$pass" --arg salt "$salt" --arg perm "$new_permission" --arg regdate "$(date)" '.users += [{"id": $id, "password": $pass, "salt": $salt, "permission": $perm, "regdate": $regdate}]' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
			reload
			clear
            log "User Added: $new_id"
			return
	    else
			echo "Passwords do not match."; unset selected_user_op; return
	    fi
	    ;;
	"Delete user")
	    clear
	    manage_users_pre
        [ "$selected" = "Back" ] && return
	    local selected_user="$selected"
        unset selected
	    local perm=$(jq -r --arg id "$selected_user" '.users[] | select(.id == $id) | .permission' "$CONFIG_FILE")
	    if [ "$perm" = "owner" ] && [ "$(owner_count)" -le 1 ]; then
			ShowError 1 "Cannot delete all owners"
			return
	    else
			printf "Enter password for \033[4m%s\033[0m: " "$selected_user"
			read delete_inputpass
	    fi
	    local delete_real_pass="$(get_user_password "$selected_user")"
        local salt="$(jq -r --arg id "$selected_user" '.users[] | select(.id==$id) | .salt' "$CONFIG_FILE")"
	    local delete_inputpass="$(printf "%s%s" "$salt" "$delete_inputpass" | sha256sum | awk '{print $1}')"
	    if [ "$delete_real_pass" = "$delete_inputpass" ]; then
			local randomconfirm="$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 12)"
			echo "$randomconfirm"
			printf "Enter the code above to remove this user: "
            read randomconfirm_input
			[ "$randomconfirm" = "$randomconfirm_input" ] && jq --arg id "$selected_user" 'del(.users[] | select(.id == $id))' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
			clear
			reload
			return
	    else
            unset selected_user
			ShowError "Password does not match."
			return
	    fi
	    ;;
    "My Info")
        if [ -z "$CURRENT_USER" ]; then
            ShowError 1 "No user logged in!"
            return
        else
            while true; do
                menu "Id: $CURRENT_USER" "Permission: $CURRENT_PERM" "Registered: $(jq -r --arg user "$CURRENT_USER" '.users[] | select(.id == $user) | .regdate' "$CONFIG_FILE")" "Back"
                [ "$selected" = "Back" ] && break
            done
        fi
        return
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
    if [ "$(jq -r --arg id "$selected_user" '.users[] | select(.id==$id) | .permission' "$CONFIG_FILE")" = "owner" ] && [ "$(owner_count)" -le 1 ]; then
        ShowError 1 "Cannot have zero owners!"
        log "Attempt to delete all owners through permission editor"
        return
    else
        jq --arg id "$selected_user" --arg perm "$selected_permission" '.users |= map(if .id==$id then .permission=$perm else . end)' "$CONFIG_FILE" > tmp.json && mv tmp.json "$CONFIG_FILE"
        log "changed permssion of $selected_user to $selected_permission"
        return
    fi
}

manage_settings() {
    clear
    while true; do
		menu "Manually edit config.json(unsafe)" "Manage a User's Permission" "Back"
		case "$selected" in
		    "Manually edit config.json(unsafe)")
                if [ "$CURRENT_PERM" = "owner" ]; then
                    diffU cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%s)"
                    diffU nano "$CONFIG_FILE"
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
    local user="$1"
    jq -r --arg user "$user" '.users[] | select(.id == $user) | .password' "$CONFIG_FILE"
}

run_login() {
    while true; do
	    clear
	    menu $users "Back"
	    if [ "$selected" = "Back" ]; then
	        return
	    fi
	    local selected_user="$selected"
	    local CURRENT_PASS="$(get_user_password "$selected_user")"
	    printf "\n%bEnter password for %s" "$main_theme" "$selected_user"
        stty -echo
        read inputpass
        stty echo
        printf "\n"
        local salt="$(jq -r --arg id "$selected_user" '.users[] | select(.id==$id) | .salt' "$CONFIG_FILE")"
	    local inputpass="$(printf "%s%s" "$salt" "$inputpass" | sha256sum | awk '{print $1}')"
	    if [ ! "$inputpass" = "$CURRENT_PASS" ]; then
	        printf "%b\nwrong password. retry\n\033[0m" "$main_theme"
	        sleep 3
	        continue
	    else
            CURRENT_USER="$selected_user"
            CURRENT_PERM="$(jq -r --arg user "$CURRENT_USER" '.users[] | select(.id == $user) | .permission' "$CONFIG_FILE")"
            log "User Login: $CURRENT_USER"
            return
	    fi
    done
}

enter_shell() {
    if [ "$CURRENT_PERM" = "member" ] || [ "$CURRENT_PERM" = "owner" ]; then
        clear
        exec "$SHELL"
        printf "%b" "$selected_theme"
        figlet -f big "Welcome"
        figlet -f small "$CURRENT_USER"
    else
        ShowError 1 "Cant access shell without being a member or owner"
        log "attempted to access shell without correct permissions"
    fi
}

advanced_options() {
    while true; do 
        clear
        menu "Temporary Shell" "Reload Configs" "Back"
        case "$selected" in
            "Temporary Shell")
                while true; do
                    printf "\n%bPlease enter a shell to use: " "$main_theme"
                    read SHELL
                    if [ -n "$SHELL" ] && command -v "$SHELL" >/dev/null 2>&1; then
                         printf "\033[1A\033[2K"
                        return
                    else
                        echo "Invalid shell!"
                        sleep 3.5
                        printf "\033[1A\033[2K\033[1A\033[2K"
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