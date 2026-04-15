#!/data/data/com.termux/files/usr/bin/bash
:() {
    echo -e "$@"
}
R="\033[0m"
: "\033[32mthis is green$R"

: "\033[1mthis is thick text$R"

: "this is an arrow with a cyan background: \033[46m↓$R"

