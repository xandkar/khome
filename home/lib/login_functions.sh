# Top Disk-Using directories
# TODO: Consider using numfmt instead of awk
tdu() {
    du "$1" \
    | sort -n -k 1 -r --parallel="$(nproc)" \
    | head -50 \
    | awk '
        {
            size = $1
            path = $0
            sub("^" $1 "\t+", "", path)
            gb = size / 1024 / 1024
            printf("%f\t%s\n", gb, path)
        }' \
    | cut -c 1-115
}

# Most-recently modified file system objects
recent() {
    # NOTES:
    # - intentionally not quoting the parameters, so that some can be ignored
    #   if not passed, rather than be passed to find as an empty string;
    # - %T+ is a GNU extension;
    # - gawk is able to split records on \0, while awk cannot.
    find $@ -printf '%T@ %T+ %p\0' \
    | tee >(gawk -v RS='\0' 'END { printf("[INFO] Total found: %d\n", NR); }') \
    | sort -z -k 1 -n -r \
    | head -n "$(stty size | awk 'NR == 1 {print $1 - 5}')" -z \
    | gawk -v RS='\0' '
        {
            sub("^" $1 " +", "")  # Remove epoch time
            sub("+", " ")         # Blank-out the default separator
            sub("\\.[0-9]+", "")  # Remove fractional seconds
            print
        }'
}

recent_dirs() {
    recent "$1" -type d
}

recent_files() {
    recent "$1" -type f
}

pa_def_sink() {
    pactl info | awk '/^Default Sink:/ {print $3}'
}

void_pkgs() {
    curl "https://xq-api.voidlinux.org/v1/query/x86_64?q=$1" | jq '.data'
}

# Colorful man
man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}

experiment() {
    cd "$(~/bin/experiment $@)" || exit 1
}

hump() {
    ledit -l $(stty size | awk '{print $2}') ocaml $@
}

howto() {
    cat "$(find  ~/Archives/Documents/HOWTOs -mindepth 1 -maxdepth 1 | sort | fzf)"
}

gh_fetch_repos() {
    curl "https://api.github.com/$1/$2/repos?page=1&per_page=10000"
}

gh_clone() {
    gh_fetch_repos "$1" "$2" \
    | jq --raw-output '.[] | select(.fork | not) | .git_url' \
    | parallel -j 25 \
    git clone {}
}

gh_clone_user() {
    gh_clone 'users' "$1"
}

gh_clone_org() {
    gh_clone 'orgs' "$1"
}

gh_clone_repo() {
    gh_username=$(echo "$1" | awk -F / '"$1 == "https" && $3 == github.com" {print $4}')
    gh_dir="${HOME}/Archives/Software/src/repos/remote/github.com/${gh_username}"
    mkdir -p "$gh_dir"
    cd "$gh_dir" || exit 1
    git clone "$1"
    cd - || exit 1
}

work_log_template() {
cat << EOF
$(date +%F)
==========

Morning report
--------------

### Previous

### Current

### Blockers

Day's notes
-----------
EOF
}

work_log() {
    mkdir -p "$DIR_WORK_LOG"
    file_work_log_today="${DIR_WORK_LOG}/$(date +%F).md"
    if [ ! -f "$file_work_log_today" ]
    then
        work_log_template > "$file_work_log_today"
    fi
    vim "$file_work_log_today"

}

weather() {
    curl "http://wttr.in/$WEATHER_LOCATION"
}

bt_devs_paired() {
    bluetoothctl -- paired-devices \
    | awk '{print $2}' \
    | xargs bluetoothctl -- info
}

bt_devs() {
    bluetoothctl -- devices \
    | awk '{print $2}' \
    | xargs bluetoothctl -- info
}