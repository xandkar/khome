#! /bin/bash

## open : string -> unit
##
## Fork xdg-open so we don't block current terminal session when opening
## things like pdf files. For example:
##
##    open book.pdf
##
open() {
    (xdg-open "$1" &) &
}

emoji() {
    khomenu < ~/emoji.txt | awk '{print $1}' | xsel --input --clipboard
}

links() {
    local -r file="$DIR_ARCHIVE"/doc/links/"$(date +%F)"

    case "$1" in
        '') "$EDITOR" "$file";;
        *) echo "$1" >> "$file";;
    esac
}

links_aggregate_md() {
    printf 'Daily Links\n'
    printf '%s\n' "$(bar 78 '=')"
    find "$DIR_ARCHIVE"/doc/links -maxdepth 1 -mindepth 1 -type f \
    | sort -r \
    | while read -r file_path; do
        printf '\n'
        basename $file_path
        printf '%s\n' "$(bar 78 '-')"
        printf '\n'
        while read -r url; do
            printf '- <%s>\n' "$url"
        done < "$file_path"
    done
}

## notify_done : unit -> unit
notify_done() {
    local -r _status_code="$?"
    local -r _program="$1"
    local _timestamp
    _timestamp="$(timestamp)"
    local -r _msg="$_timestamp [$_program] done "
    if [[ "$_status_code" -eq 0 ]]
    then
        notify-send -u normal "$_msg OK: $_status_code"
    else
        notify-send -u critical "$_msg ERROR: $_status_code"
    fi
}

_dl_script() {
cat << EOF
#! /bin/bash
wget -c \$(< ./url)
EOF
}

dl() {
    local -r name="$1"
    local -r url="$2"

    local -r timestamp="$(date --iso-8601=ns)"
    local -r dir="$HOME"/dl/adhoc/"$timestamp"--"$name"
    local -r url_file_path="${dir}/url"
    local -r dl_file_path="${dir}/dl"

    mkdir -p "$dir"
    touch "$url_file_path"
    if [ "$url" != '' ]
    then
        echo "$url" > "$url_file_path"
    fi
    _dl_script > "$dl_file_path"
    chmod +x "$dl_file_path"
    cd "$dir"
}

## web search
## ws : string -> unit
ws() {
    local line search_string0 search_string

    search_string0="$*"
    case "$search_string0" in
        '')
            while read -r line; do
                search_string="${search_string} ${line}"
            done;;
         *)
            search_string="$search_string0";;
    esac

    firefox --search "$search_string"
}


## dictionary
## d : string -> string list
d() {
    local -r word=$(fzf < /usr/share/dict/words)
    dict "$word"
}

## shell_activity_report : (mon | dow) -> string list
shell_activity_report() {
    # TODO: optional concrete number output
    # TODO: optional combinations of granularities: hour, weekday, month, year
    local group_by="$1"
    case "$group_by" in
        'mon') ;;
        'dow') ;;
        '') group_by='dow';;
        *)
            echo "Usage: $0 [mon|dow]" >&2
            kill -INT $$
    esac
    history \
    | awk -v group_by="$group_by" '
        function date2dow(y, m, d,    _t, _i) {
            # Contract:
            #   y > 1752,  1 <= m <= 12.
            # Source:
            #   Sakamoto`s methods
            #   https://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week#Sakamoto%27s_methods
            _t[ 0] = 0
            _t[ 1] = 3
            _t[ 2] = 2
            _t[ 3] = 5
            _t[ 4] = 0
            _t[ 5] = 3
            _t[ 6] = 5
            _t[ 7] = 1
            _t[ 8] = 4
            _t[ 9] = 6
            _t[10] = 2
            _t[11] = 4
            y -= m < 3
            _i = int(y + y/4 - y/100 + y/400 + _t[m - 1] + d) % 7
            _i = _i == 0 ? 7 : _i  # Make Sunday last
            return _i

        }

        {
            # NOTE: $2 & $3 are specific to oh-my-zsh history output
            date = $2
            time = $3
            d_fields = split(date, d, "-")
            t_fields = split(time, t, ":")
            if (t_fields && d_fields) {
                # +0 to coerce number from string
                year  = d[1] + 0
                month = d[2] + 0
                day   = d[3] + 0
                hour = t[1] + 0
                dow = date2dow(year, month, day)
                g = group_by == "mon" ? month : dow  # dow is default
                c = count[g, hour]++
            }
            if (c > max)
                max = c
        }

        END {
            w[1] = "Monday"
            w[2] = "Tuesday"
            w[3] = "Wednesday"
            w[4] = "Thursday"
            w[5] = "Friday"
            w[6] = "Saturday"
            w[7] = "Sunday"

            m[ 1] = "January"
            m[ 2] = "February"
            m[ 3] = "March"
            m[ 4] = "April"
            m[ 5] = "May"
            m[ 6] = "June"
            m[ 7] = "July"
            m[ 8] = "August"
            m[ 9] = "September"
            m[10] = "October"
            m[11] = "November"
            m[12] = "December"

            n = group_by == "mon" ? 12 : 7  # dow is default

            for (gid = 1; gid <= n; gid++) {
                group = group_by == "mon" ? m[gid] : w[gid]
                printf "%s\n", group;
                for (hour=0; hour<24; hour++) {
                    c = count[gid, hour]
                    printf "  %2d ", hour
                    for (i = 1; i <= (c * 100) / max; i++)
                        printf "|"
                    printf "\n"
                }
            }
        }'
}

## top_commands : unit -> (command:string * count:number * bar:string) list
top_commands() {
    history \
    | awk '
        {
            count[$4]++
        }

        END {
            for (cmd in count)
                print count[cmd], cmd
        }' \
    | sort -n -r -k 1 \
    | head -50 \
    | awk '
        {
            cmd[NR] = $2
            c = count[NR] = $1 + 0  # + 0 to coerce number from string
            if (c > max)
                max = c
        }

        END {
            for (i = 1; i <= NR; i++) {
                c = count[i]
                printf "%s %d ", cmd[i], c
                scaled = (c * 100) / max
                for (j = 1; j <= scaled; j++)
                    printf "|"
                printf "\n"
            }
        }' \
    | column -t
}

## Top Disk-Using directories
## tdu : path-string -> (size:number * directory:path-string) list
tdu() {
    local -r root_path="$1"

    du -h "$root_path" \
    | sort -r -h -k 1 \
    | head -50 \
    | tac
    # A slight optimization: head can exit before traversing the full input.
}

## Top Disk-Using Files
## tduf : path-string list -> (size:number * file:path-string) list
tduf() {
    find "$@" -type f -printf '%s\t%p\0' \
    | sort -z -n -k 1 \
    | tail -z -n 50 \
    | numfmt -z --to=iec \
    | tr '\0' '\n'
}

# Most-recently modified file system objects
## recent : ?(path-string list) -> path-string list
recent() {
    # NOTES:
    # - %T+ is a GNU extension;
    # - gawk is able to split records on \0, while awk cannot.
    find "$@" -printf '%T@ %T+ %p\0' \
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

## recent_dirs : ?(path-string list) -> path-string list
recent_dirs() {
    recent "$@" -type d
}

## recent_files : ?(path-string list) -> path-string list
recent_files() {
    recent "$@" -type f
}

## pa_def_sink : unit -> string
pa_def_sink() {
    pactl info | awk '/^Default Sink:/ {print $3}'
}

## void_pkgs : ?(string) -> json
void_pkgs() {
    curl "https://xq-api.voidlinux.org/v1/query/x86_64?q=$1" | jq '.data'
}

## Colorful man
## man : string -> string
man() {
    # mb: begin blink
    # md: begin bold
    # me: end   bold, blink and underline
    #
    # so: begin standout (reverse video)
    # se: end   standout
    #
    # us: begin underline
    # ue: end   underline

    LESS_TERMCAP_md=$'\e[01;30m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    command man "$@"
}

## new experiment
## x : string list -> unit
x() {
    cd "$(~/bin/x $@)" || kill -INT $$
}

## ocaml repl
## hump : unit -> unit
hump() {
    ledit -l "$(stty size | awk '{print $2}')" ocaml $@
}

## search howtos
## howto : unit -> string
howto() {
    local -r file=$(find  "$DIR_ARCHIVE"/doc/HOWTOs -mindepth 1 -maxdepth 1 | sort | fzf)
    cat "$file"
}

_yt() {
    local -r base_dir="$1"
    local -r uri="$2"
    local -r opts="$3"

    # local -r yt=youtube-dl
    local -r yt=yt-dlp
    local -r id=$("$yt" --get-id "$uri")
    local -r title=$("$yt" --get-title "$uri" | sed 's/[^А-Яа-яA-Za-z0-9._-]/_/g')
    local -r dir="${base_dir}/${title}--${id}"

    mkdir -p "$dir"
    cd "$dir" || kill -INT $$
    echo "$uri" > 'uri'
    "$yt" $opts -c --write-all-thumbnails --write-description --write-info-json "$uri"
}

yt_audio() {
    local -r uri="$1"
    _yt "${DIR_YOUTUBE_AUDIO}/individual" "$uri" '-f 140'
}

yt_video() {
    local -r uri="$1"
    _yt "${DIR_YOUTUBE_VIDEO}/individual" "$uri"
}

gh_fetch_repos() {
    local -r user_type="$1"
    local -r user_name="$2"

    curl "https://api.github.com/$user_type/$user_name/repos?page=1&per_page=10000"
}

gh_clone() {
    local -r gh_user_type="$1"
    local -r gh_user_name="$2"

    local -r gh_dir="${DIR_GITHUB}/${gh_user_name}"
    mkdir -p "$gh_dir"
    cd "$gh_dir" || kill -INT $$
    gh_fetch_repos "$gh_user_type" "$gh_user_name" \
    | jq --raw-output '.[] | select(.fork | not) | .clone_url' \
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
    gh_dir="${DIR_GITHUB}/${gh_username}"
    mkdir -p "$gh_dir"
    cd "$gh_dir" || kill -INT $$
    git clone "$1"
}

bar() {
    local -r len="${1:-79}" # 1st arg or 79.
    local -r char="${2:--}" # 2nd arg or a dash.
    for _ in {1.."$len"}; do
        printf '%c' "$char";
    done
}

daily_todo_file_template() {
cat << EOF
===============================================================================
$(date '+%F %A')
===============================================================================

-------------------------------------------------------------------------------
TODAY
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
CURRENT
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
BLOCKED
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
BACKLOG
-------------------------------------------------------------------------------
EOF
}

today() {
    local date
    date="$(date +%F)"
    local -r dir="$DIR_TODO/daily"
    local -r file="$dir/$date.txt"

    mkdir -p "$dir"
    if [ ! -f "$file" ]
    then
        daily_todo_file_template > "$file"
    fi
    cd "$DIR_TODO" && "$EDITOR" $EDITOR_ARGS "$file"
}

todo() {
    cd "$DIR_TODO" && "$EDITOR" TODO
}

work_log_template() {
cat << EOF
$(date '+%F %A')
==========

Morning report
--------------

### Prev

### Curr

### Next

### Blockers

Day's notes
-----------
EOF
}

work_log() {
    mkdir -p "$DIR_WORK_LOG"
    local -r file_work_log_today="${DIR_WORK_LOG}/daily-$(date +%F).md"
    if [ ! -f "$file_work_log_today" ]
    then
        work_log_template > "$file_work_log_today"
    fi
    vim -c 'set spell' "$file_work_log_today"

}

note() {
    mkdir -p "$DIR_NOTES"
    vim -c 'set spell' "$DIR_NOTES/$(date +'%Y_%m_%d--%H_%M_%S%z')--$1.md"
}

_bt_devs_infos() {
    # grep's defintion of a line does not include \r, wile awk's does and
    # which bluetoothctl outputs
    awk '/^Device +/ {print $2}' \
    | xargs -I% sh -c 'echo info % | bluetoothctl' \
    | awk '/^Device |^\t[A-Z][A-Za-z0-9]+: /'
}

bt_devs_paired() {
    echo 'paired-devices' | bluetoothctl | _bt_devs_infos
}

bt_devs() {
    echo 'devices' | bluetoothctl | _bt_devs_infos
}

run() {
    local -r stderr="$(mktemp)"

    local code urgency

    $@ 2> >(tee "$stderr")
    code="$?"
    case "$code" in
        0) urgency='normal';;
        *) urgency='critical'
    esac
    notify-send -u "$urgency" "Job done: $code" "$(cat $stderr)"
    rm "$stderr"
}

bar_gauge() {
    awk "$@" '
        BEGIN {
            # CLI options
            width    = width    ? width    : 80
            ch_left  = ch_left  ? ch_left  : "["
            ch_right = ch_right ? ch_right : "]"
            ch_blank = ch_blank ? ch_blank : "-"
            ch_used  = ch_used  ? ch_used  : "|"
            num      = num      ? 1        : 0
            pct      = pct      ? 1        : 0
        }

        {
            cur = $1
            max = $2
            lab = $3

            cur_scaled = num_scale(cur, max, 1, width)

            printf \
                "%s%s%s%s", \
                lab ? lab         " " : "", \
                num ? cur "/" max " " : "", \
                pct ? sprintf("%3.0f%% ", cur / max * 100) : "", \
                ch_left
            for (i=1; i<=width; i++) {
                c = i <= cur_scaled ? ch_used : ch_blank
                printf "%s", c
            }
            printf "%s\n", ch_right
        }

        function num_scale(src_cur, src_max, dst_min, dst_max) {
            return dst_min + ((src_cur * (dst_max - dst_min)) / src_max)
        }
    '
}

flat_top_5() {
    sort -n -k 1 -r \
    | head -5 \
    | awk '
        {
            cur  = $1
            max  = $2
            name = $3
            pct  = cur / max * 100
            printf "%s%s %.2f%%", sep, name, pct
            sep = ",  "
        }

        END {printf "\n"}
        '
}

internet_addr() {
    curl --silent --show-error --max-time "${1:=1}" 'https://api.ipify.org' 2>&1
}

status_batt() {
    case "$(uname)" in
        'Linux')
            if which upower > /dev/null
            then
                upower --dump \
                | awk '
                    /^Device:[ \t]+/ {
                        device["path"] = $2
                        next
                    }

                    /  battery/ && device["path"] {
                        device["is_battery"] = 1
                        next
                    }

                    /    percentage:/ && device["is_battery"] {
                        device["battery_percentage"] = $2
                        sub("%$", "", device["battery_percentage"])
                        next
                    }

                    /^$/ {
                        if (device["is_battery"] && device["path"] == "/org/freedesktop/UPower/devices/DisplayDevice")
                            print device["battery_percentage"], 100, "batt"
                        delete device
                    }
                '
            fi
        ;;
    esac
}

indent() {
    awk -v unit="$1" '{printf "%s%s\n", unit, $0}'
}

status() {
    local -r indent_unit='    '

    uname -srvmo
    hostname | figlet
    uptime

    echo

    echo 'accounting'

    # TODO Bring back seesion and client listing, but per server/socket.
    printf '%stmux\n' "$indent_unit"
    ps -eo comm,cmd \
    | awk '
        # Expecting lines like:
        #     "tmux: server    tmux -L pistactl new-session -d -s pistactl"
        #     "tmux: client    tmux -L foo"
        #     "tmux: client    tmux -Lbar"
        #     "tmux: client    tmux"
        #     "tmux: server    tmux -L foo -S bar" <-- -S takes precedence
        /^tmux:/ {
            # XXX This of course assumes pervasive usage of -L
            # TODO Handle -S
            role=$2

            split($0, sides_of_S, "-S")
            split(sides_of_S[2], words_right_of_S, FS)

            split($0, sides_of_L, "-L")
            split(sides_of_L[2], words_right_of_L, FS)

            if (words_right_of_S[1]) {
                sock = "path." words_right_of_S[1]
            } else if (words_right_of_L[1]) {
                sock = "name." words_right_of_L[1]
            } else {
                sock = "default"
            }

            roles[role]++
            socks[sock]++
            count[role, sock]++
        }

        END {
            for (sock in socks) {
                clients = count["client", sock]
                printf "%s ", sock
                if (clients) {
                    printf "<-> %d", clients
                }
                printf "\n"
            }
            printf "\n"
        }' \
    | sort \
    | column -t \
    | indent "${indent_unit}${indent_unit}"

    echo

    printf '%sprocs by user\n' "${indent_unit}"
    ps -eo user \
    | awk '
        NR > 1 {
            count_by_user[$1]++
            total++
        }

        END {
            for (user in count_by_user)
                print count_by_user[user], total, user
        }
        ' \
    | flat_top_5 \
    | indent "${indent_unit}${indent_unit}"

    echo

    echo 'resources'
    (
        free | awk '$1 == "Mem:" {print $3, $2, "mem"}'
        df ~ | awk 'NR == 2 {print $3, $3 + $4, "disk"}'
        status_batt
    ) \
    | bar_gauge -v width=60 -v pct=1 \
    | column -t \
    | indent "$indent_unit"

    echo

    printf '%smem by proc\n' "$indent_unit"
    ps -eo rss,comm \
    | awk -v total="$(free | awk '$1 == "Mem:" {print $2; exit}')" '
        NR > 1 {
            rss = $1
            proc = $2
            by_proc[proc] += rss
        }

        END {
            for (proc in by_proc)
                print by_proc[proc], total, proc
            }
        ' \
        | flat_top_5 \
        | indent "${indent_unit}${indent_unit}"

    echo

    local _dir temp_input label_file label

    printf '%sthermal\n' "$indent_unit"
    for _dir in /sys/class/hwmon/hwmon*; do
        cat "$_dir"/name
        find "$_dir"/ -name 'temp*_input' \
            | while read -r temp_input; do
                label_file=${temp_input//_input/_label}
                if [ -f "$label_file" ]; then
                    label=$(< "$label_file")
                else
                    label=''
                fi
                awk -v label="$label" '{
                        if (label)
                            label = sprintf(" (%s)", label)
                            printf("%.2f°C%s\n", $1 / 1000, label)
                    }' \
                    "$temp_input"
            done \
            | sort \
            | indent "$indent_unit"
    done \
    | indent "${indent_unit}${indent_unit}"

    echo 'net'
    #local -r internet_addr=$(internet_addr 0.5)
    #local -r internet_ptr=$(host -W 1 "$internet_addr" | awk 'NR == 1 {print $NF}' )

    #echo "${indent_unit}internet"
    #echo "${indent_unit}${indent_unit}$internet_addr  $internet_ptr"
    echo "${indent_unit}if"
    (ifconfig; iwconfig) 2> /dev/null \
    | awk '
        /^[^ ]/ {
            device = $1
            sub(":$", "", device)
            if ($4 ~ "ESSID:") {
                _essid = $4
                sub("^ESSID:\"", "", _essid)
                sub("\"$", "", _essid)
                essid[device] = _essid
            }
            next
        }

        /^ / && $1 == "inet" {
            address[device] = $2
            next
        }

        /^ +Link Quality=[0-9]+\/[0-9]+ +Signal level=/ {
            split($2, lq_parts_eq, "=")
            split(lq_parts_eq[2], lq_parts_slash, "/")
            cur = lq_parts_slash[1]
            max = lq_parts_slash[2]
            link[device] = cur / max * 100
            next
        }

        END {
            for (device in address)
                if (device != "lo") {
                    l = link[device]
                    e = essid[device]
                    l = l ? sprintf("%.0f%%", l) : "--"
                    e = e ? e : "--"
                    print device, address[device], e, l
                }
        }
        ' \
    | column -t \
    | indent "${indent_unit}${indent_unit}"

    # WARN: ensure: $USER ALL=(ALL) NOPASSWD:/bin/netstat

    echo "${indent_unit}-->"

    # TODO Populate pid->cmd dict from `ps -eo pid,comm` and lookup progs there
    #      since netstat -p output comes out truncated.

    sudo -n netstat -tulnp \
    | awk -v indent="${indent_unit}${indent_unit}" '
        NR > 2 && ((/^tcp/ && proc = $7) || (/^udp/ && proc = $6)) {
            protocol = $1
            addr = $4
            port = a[split(addr, a, ":")]
            name = p[split(proc, p, "/")]
            names[name] = 1
            protocols[protocol] = 1
            if (!seen[protocol, name, port]++)
                ports[protocol, name, ++seen[protocol, name]] = port
        }

        END {
            for (protocol in protocols) {
                printf "%s%s\t", indent, toupper(protocol)
                for (name in names) {
                    if (n = seen[protocol, name]) {
                        sep = ""
                        printf "%s:", name
                        for (i = 1; i <= n; i++) {
                            printf "%s%d", sep, ports[protocol, name, i]
                            sep = ","
                        }
                        printf "  "
                    }
                }
                printf "\n"
            }
        }'

    echo "${indent_unit}<->"

    printf '%sTCP\t' "${indent_unit}${indent_unit}"
    sudo -n netstat -tnp \
    | awk 'NR > 2 && $6 == "ESTABLISHED" {print $7}' \
    | awk '{sub("^[0-9]+/", ""); print}' \
    | sort -u \
    | xargs \
    | column -t

    # TODO: iptables summary
}

ssh_invalid_by_addr() {
    awk '
        /: Invalid user/ && $5 ~ /^sshd/ {
            addr=$10 == "port" ? $9 : $10
            max++
            by_addr[addr]++
        }

        END {
            for (addr in by_addr)
                if ((c = by_addr[addr]) > 1)
                    printf "%d %d %s\n", c, max, addr
        }
        ' \
        /var/log/auth.log \
        /var/log/auth.log.1 \
    | sort -n -k 1 \
    | bar_gauge -v width="$(stty size | awk '{print $2}')" -v num=1 -v ch_right=' ' -v ch_left=' ' -v ch_blank=' ' \
    | column -t
}

ssh_invalid_by_day() {
    awk '
        BEGIN {
            m["Jan"] = "01"
            m["Feb"] = "02"
            m["Mar"] = "03"
            m["Apr"] = "04"
            m["May"] = "05"
            m["Jun"] = "06"
            m["Jul"] = "07"
            m["Aug"] = "08"
            m["Sep"] = "09"
            m["Oct"] = "10"
            m["Nov"] = "11"
            m["Dec"] = "12"
        }

        /: Invalid user/ && $5 ~ /^sshd/ {
            day = m[$1] "-" $2
            max++
            by_day[day]++
        }

        END {
            for (day in by_day)
                if ((c = by_day[day]) > 1)
                    printf "%d %d %s\n", c, max, day
        }
        ' \
        /var/log/auth.log \
        /var/log/auth.log.1 \
    | sort -k 3 \
    | bar_gauge -v width="$(stty size | awk '{print $2}')" -v num=1 -v ch_right=' ' -v ch_left=' ' -v ch_blank=' ' \
    | column -t
}

ssh_invalid_by_user() {
    awk '
        /: Invalid user/ && $5 ~ /^sshd/ {
            user=$8
            max++
            by_user[user]++
        }

        END {
            for (user in by_user)
                if ((c = by_user[user]) > 1)
                    printf "%d %d %s\n", c, max, user
        }
        ' \
        /var/log/auth.log \
        /var/log/auth.log.1 \
    | sort -n -k 1 \
    | bar_gauge -v width="$(stty size | awk '{print $2}')" -v num=1 -v ch_right=' ' -v ch_left=' ' -v ch_blank=' ' \
    | column -t
}

loggers() {
    awk '
        {
            split($5, prog, "[")
            sub(":$", "", prog[1]) # if there were no [], than : will is left behind
            print prog[1]
        }' /var/log/syslog /var/log/syslog.1 \
    | awk '
        {
            n = split($1, path, "/")  # prog may be in path form
            prog = path[n]
            total++
            count[prog]++
        }

        END {
            for (prog in count)
                print count[prog], total, prog
        }' \
    | sort -n -k 1 \
    | bar_gauge -v num=1 -v ch_right=' ' -v ch_left=' ' -v ch_blank=' ' \
    | column -t
}

load() {
    awk -v n="$(nproc)" 'NR == 1 {printf "%.2f %.2f %.2f\n", $1 / n, $2 / n, $3 / n}' /proc/loadavg
}
