#!/usr/bin/env bash
# dependencies: hyprland (hyprctl), jq
set -euo pipefail

toml="$HOME/.config/monitor.toml"

focused() { hyprctl -j monitors | jq -r '.[] | select(.focused) | .name'; }

# The section header above the line holding this port.
section_of() {
    awk -v port="$1" '
        /^\[/ { sec = $0 }
        $1 == "port" && $0 ~ "\"" port "\"" { print sec; exit }
    ' "$toml"
}

get_key() {
    awk -v sec="$1" -v key="$2" '
        /^\[/ { in_sec = ($0 == sec) }
        in_sec && $1 == key { gsub(/"/, "", $3); print $3; exit }
    ' "$toml"
}

set_key() {
    awk -v sec="$1" -v key="$2" -v val="$3" '
        /^\[/ { in_sec = ($0 == sec) }
        in_sec && $1 == key { sub(/=.*/, "= " val) }
        { print }
    ' "$toml" > "$toml.tmp" && mv "$toml.tmp" "$toml"
}

# Left to right by index. A rotated output occupies its height as width.
sync_positions() {
    awk '
        /^\[/ {
            split($0, p, "."); profile = substr(p[1], 2)
            sec = $0; order[++n] = sec; prof[sec] = profile
        }
        $1 == "index"       { idx[sec]  = $3 }
        $1 == "resolution"  { gsub(/"/, "", $3); res[sec]  = $3 }
        $1 == "orientation" { ori[sec]  = $3 }
        END {
            for (p_ = 1; p_ <= n; p_++) {
                s = order[p_]
                for (q = 1; q <= n; q++) {
                    t = order[q]
                    if (prof[t] == prof[s] && idx[t] < idx[s]) {
                        split(res[t], d, "x")
                        x[s] += (ori[t] == 1 || ori[t] == 3) ? d[2] : d[1]
                    }
                }
                printf "%s\t%d\n", s, x[s] + 0
            }
        }
    ' "$toml" | while IFS=$'\t' read -r sec px; do
        set_key "$sec" position "\"${px}x0\""
    done
}

case "${1:-}" in
    flip)
        out="${2:-$(focused)}"
        sec=$(section_of "$out")
        [ -n "$sec" ] || { echo "$out not in $toml" >&2; exit 1; }
        [ "$(get_key "$sec" orientation)" = "0" ] && new=3 || new=0
        set_key "$sec" orientation "$new"
        sync_positions
        hyprctl reload >/dev/null
        ;;

    resolution)
        out="${2:?usage: monitor.sh resolution <output> <mode>}"
        mode="${3:?usage: monitor.sh resolution <output> <mode>}"
        sec=$(section_of "$out")
        [ -n "$sec" ] || { echo "$out not in $toml" >&2; exit 1; }
        res="${mode%@*}"
        set_key "$sec" resolution "\"$res\""
        if [ "$res" != "$mode" ]; then
            rate="${mode##*@}"
            set_key "$sec" refresh-rate "${rate%%.*}"
        fi
        sync_positions
        hyprctl reload >/dev/null
        ;;

    sync) sync_positions ;;
    list) hyprctl -j monitors ;;

    *)
        echo "usage: monitor.sh flip [output] | resolution <output> <mode> | sync | list" >&2
        exit 2
        ;;
esac
