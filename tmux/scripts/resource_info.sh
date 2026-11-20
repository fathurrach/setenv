#!/usr/bin/env bash
# ==============================================================================
# TMUX SYSTEM RESOURCE & UPTIME MONITOR
# Compatible: macOS (Apple Silicon / Intel) & Linux
# Managed by setenv (https://github.com/fathurrach/setenv)
# ==============================================================================

CACHE_DIR="${HOME}/.tmux/cache"
mkdir -p "$CACHE_DIR" 2>/dev/null

get_bar() {
    local pct="${1%\%}"
    # Ensure numeric value
    pct="${pct%.*}"
    if [ -z "$pct" ] || ! [[ "$pct" =~ ^[0-9]+$ ]]; then
        echo " "
        return
    fi

    if [ "$pct" -ge 88 ]; then
        echo "█"
    elif [ "$pct" -ge 75 ]; then
        echo "▇"
    elif [ "$pct" -ge 63 ]; then
        echo "▆"
    elif [ "$pct" -ge 50 ]; then
        echo "▅"
    elif [ "$pct" -ge 38 ]; then
        echo "▄"
    elif [ "$pct" -ge 25 ]; then
        echo "▃"
    elif [ "$pct" -ge 12 ]; then
        echo "▂"
    else
        echo " "
    fi
}

get_cpu() {
    local cache_file="${CACHE_DIR}/cpu_val"
    local now
    now=$(date +%s)
    local last_mod=0

    if [ -f "$cache_file" ]; then
        last_mod=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    fi

    # Refresh in background if cache is older than 3 seconds or does not exist
    if [ $((now - last_mod)) -ge 3 ] || [ ! -f "$cache_file" ]; then
        (
            local cpu_pct=0
            if [ "$(uname)" = "Darwin" ]; then
                # macOS CPU calculation
                cpu_pct=$(top -l 1 -n 0 2>/dev/null | awk '/CPU usage/ { sub(/%/, "", $3); sub(/%/, "", $5); printf "%.0f", ($3 + $5) }')
                if [ -z "$cpu_pct" ] || [ "$cpu_pct" = "0" ]; then
                    cpu_pct=$(ps -A -o %cpu 2>/dev/null | awk '{s+=$1} END {printf "%.0f", s}')
                fi
                if [ -z "$cpu_pct" ] || [ "$cpu_pct" = "0" ]; then
                    # Fallback using loadavg
                    cpu_pct=$(sysctl -n vm.loadavg 2>/dev/null | awk '{sub(/\{/,""); printf "%.0f", $1 * 10}')
                fi
            else
                # Linux CPU calculation
                if [ -f /proc/stat ]; then
                    read -r _ u n s i w irq sirq st _ < /proc/stat
                    local prev_file="${CACHE_DIR}/proc_stat_prev"
                    if [ -f "$prev_file" ]; then
                        read -r pu pn ps pi pw pirq psirq pst < "$prev_file"
                        local prev_idle=$((pi + pw))
                        local idle=$((i + w))
                        local prev_non_idle=$((pu + pn + ps + pirq + psirq + pst))
                        local non_idle=$((u + n + s + irq + sirq + st))
                        local prev_total=$((prev_idle + prev_non_idle))
                        local total=$((idle + non_idle))
                        local totald=$((total - prev_total))
                        local idled=$((idle - prev_idle))
                        if [ "$totald" -gt 0 ]; then
                            cpu_pct=$(( (totald - idled) * 100 / totald ))
                        fi
                    fi
                    echo "$u $n $s $i $w $irq $sirq $st" > "$prev_file"
                else
                    cpu_pct=$(top -bn1 2>/dev/null | awk '/Cpu\(s\)/ {printf "%.0f", 100 - $8}')
                fi
            fi

            cpu_pct="${cpu_pct:-0}"
            if [ "$cpu_pct" -gt 100 ] 2>/dev/null; then
                cpu_pct=100
            fi

            local bar
            bar=$(get_bar "$cpu_pct")
            echo "${cpu_pct}% ${bar}" > "${cache_file}.tmp" 2>/dev/null && mv "${cache_file}.tmp" "$cache_file" 2>/dev/null
        ) &
    fi

    if [ -f "$cache_file" ] && [ -s "$cache_file" ]; then
        cat "$cache_file"
    else
        echo "0%  "
    fi
}

get_mem() {
    local used="0"
    local total="0"
    local pct="0"

    if [ "$(uname)" = "Darwin" ]; then
        local hw_mem
        hw_mem=$(sysctl -n hw.memsize 2>/dev/null)
        local total_gb=16
        if [ -n "$hw_mem" ] && [ "$hw_mem" -gt 0 ] 2>/dev/null; then
            total_gb=$(( hw_mem / 1073741824 ))
        fi

        local ps
        ps=$(vm_stat 2>/dev/null | awk '/page size of/ {print $8}')
        ps=${ps:-16384}

        read -r used total pct <<< $(vm_stat 2>/dev/null | awk -v ps="$ps" -v tot_gb="$total_gb" '
        /Pages free:/ { free = $3 }
        /Pages active:/ { active = $3 }
        /Pages inactive:/ { inactive = $3 }
        /Pages speculative:/ { spec = $3 }
        /Pages wired down:/ { wired = $4 }
        /Pages occupied by compressor:/ { comp = $5 }
        END {
            sub(/\./, "", free); sub(/\./, "", active); sub(/\./, "", inactive);
            sub(/\./, "", spec); sub(/\./, "", wired); sub(/\./, "", comp);
            used_gb = (active + wired + comp) * ps / 1073741824;
            p = (tot_gb > 0) ? int((used_gb / tot_gb) * 100) : 0;
            printf "%.1f %d %d\n", used_gb, tot_gb, p;
        }')
    else
        # Linux
        if [ -f /proc/meminfo ]; then
            read -r used total pct <<< $(awk '
            /MemTotal:/ { t = $2 / 1048576 }
            /MemAvailable:/ { a = $2 / 1048576 }
            END {
                u = t - a;
                p = (t > 0) ? int((u / t) * 100) : 0;
                printf "%.1f %.0f %d\n", u, t, p;
            }' /proc/meminfo)
        fi
    fi

    used="${used:-0}"
    total="${total:-0}"
    pct="${pct:-0}"
    local bar
    bar=$(get_bar "$pct")
    echo "${used}G/${total}G (${pct}%) ${bar}"
}

get_storage() {
    local line
    line=$(df -h "${HOME:-/}" 2>/dev/null | awk 'NR==2 {print $3, $2, $5}')
    local used total pct
    read -r used total pct <<< "$line"
    used=${used//i/}
    total=${total//i/}
    local clean_pct="${pct%\%}"
    used="${used:-0G}"
    total="${total:-0G}"
    pct="${pct:-0%}"
    clean_pct="${clean_pct:-0}"
    local bar
    bar=$(get_bar "$clean_pct")
    echo "${used}/${total} (${pct}) ${bar}"
}

get_uptime() {
    uptime 2>/dev/null | awk '{
        line = $0
        sub(/.*up[ ]+/, "", line)
        sub(/,[ ]+[0-9]+[ ]+user.*/, "", line)

        days = 0; hours = 0; has_days = 0; has_hours = 0

        if (line ~ /[0-9]+[ ]+day/) {
            has_days = 1
            match(line, /[0-9]+[ ]+day/)
            split(substr(line, RSTART, RLENGTH), arr, /[ ]+/)
            days = arr[1]
        }

        if (line ~ /[0-9]+:[0-9]+/) {
            has_hours = 1
            match(line, /[0-9]+:[0-9]+/)
            split(substr(line, RSTART, RLENGTH), arr, /:/)
            hours = arr[1] + 0
        } else if (line ~ /[0-9]+[ ]+hr/) {
            has_hours = 1
            match(line, /[0-9]+[ ]+hr/)
            split(substr(line, RSTART, RLENGTH), arr, /[ ]+/)
            hours = arr[1] + 0
        }

        if (has_days && has_hours) {
            printf "%dd %dh\n", days, hours
        } else if (has_days) {
            printf "%dd\n", days
        } else if (has_hours) {
            printf "%dh\n", hours
        } else {
            printf "0h\n"
        }
    }'
}

case "$1" in
    cpu)
        get_cpu
        ;;
    mem)
        get_mem
        ;;
    storage|disk)
        get_storage
        ;;
    uptime)
        get_uptime
        ;;
    *)
        echo "Usage: $0 {cpu|mem|storage|uptime}"
        exit 1
        ;;
esac
