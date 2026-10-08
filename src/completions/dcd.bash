# bash completion for dcd

# Reads "name<TAB>description" lines from stdin and fills COMPREPLY with the
# ones whose name starts with $1. Bash has no notion of descriptions, so when
# several candidates are listed each one is rendered as "name  -- description"
# and padded to the terminal width, which forces one candidate per line. Names
# never share a prefix that reaches into the description, so what bash inserts
# on the command line is still only the name.
_dcd_reply() {
    local cur=$1 name desc line i width=0
    local -a names=() descs=()
    while IFS=$'\t' read -r name desc; do
        [[ $name == "$cur"* ]] || continue
        names+=("$name")
        descs+=("$desc")
        (( ${#name} > width )) && width=${#name}
    done

    # A single match is inserted as is; menu-complete (COMP_TYPE 37) inserts
    # each candidate in turn, so it must get bare names as well.
    if (( ${#names[@]} <= 1 || ${COMP_TYPE:-9} == 37 )); then
        COMPREPLY=("${names[@]}")
        return
    fi

    local cols=$(( ${COLUMNS:-80} - 1 ))
    for i in "${!names[@]}"; do
        printf -v line '%-*s  -- %s' "$width" "${names[i]}" "${descs[i]}"
        printf -v line '%-*s' "$cols" "$line"
        COMPREPLY+=("$line")
    done
}

# Prints the configured directories as "name<TAB>path" lines. Extra arguments
# (the --config override, if any) are passed through to dcd.
_dcd_directories() {
    local name path
    while IFS=$'\t' read -r name path; do
        case $name in
            add | rm | list | completions) continue ;;
        esac
        printf '%s\t%s\n' "$name" "$path"
    done < <("$@" list 2>/dev/null)
}

_dcd() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local -a dcd=("${COMP_WORDS[0]}")
    local i=1 flag='' sub=''
    COMPREPLY=()

    # Skip the global flags to find the subcommand.
    while (( i < COMP_CWORD )); do
        case ${COMP_WORDS[i]} in
            --config)
                flag=--config
                (( i + 1 < COMP_CWORD )) && dcd+=(--config "${COMP_WORDS[i + 1]/#\~/$HOME}")
                (( i += 2 ))
                ;;
            --launch)
                flag=--launch
                (( i += 2 ))
                ;;
            *)
                sub=${COMP_WORDS[i]}
                break
                ;;
        esac
    done

    # The current word is the value of a global flag.
    if (( i > COMP_CWORD )); then
        case $flag in
            --config)
                compopt -o filenames
                COMPREPLY=($(compgen -f -- "$cur"))
                ;;
            --launch)
                COMPREPLY=($(compgen -W 'exec exec_quit spawn' -- "$cur"))
                ;;
        esac
        return
    fi

    case $sub in
        '')
            if [[ $cur == -* ]]; then
                _dcd_reply "$cur" <<'EOF'
--config	use another config file
--launch	override the launch mode
EOF
                return
            fi
            _dcd_reply "$cur" < <(
                printf '%s\t%s\n' \
                    add 'add a directory' \
                    list 'list directories' \
                    rm 'remove a directory'
                _dcd_directories "${dcd[@]}"
            )
            ;;
        rm)
            (( COMP_CWORD == i + 1 )) && _dcd_reply "$cur" < <(_dcd_directories "${dcd[@]}")
            ;;
        add)
            if [[ $cur == -* ]]; then
                COMPREPLY=($(compgen -W '-r' -- "$cur"))
                return
            fi
            # Only the second positional argument (the path) is completed.
            local j positional=0
            for (( j = i + 1; j < COMP_CWORD; j++ )); do
                [[ ${COMP_WORDS[j]} == -r ]] || (( positional++ ))
            done
            if (( positional == 1 )); then
                compopt -o filenames
                COMPREPLY=($(compgen -d -- "$cur"))
            fi
            ;;
        completions)
            (( COMP_CWORD == i + 1 )) && COMPREPLY=($(compgen -W 'bash' -- "$cur"))
            ;;
    esac
}
