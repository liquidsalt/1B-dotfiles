#!/usr/bin/env bash
# dependencies: nvidia-utils (nvidia-smi)
set -euo pipefail

# Fail loudly on a missing dependency rather than halfway through.
need() {
    local miss=
    for c in "$@"; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
    [ -z "$miss" ] || { echo "${0##*/}: missing dependency:$miss" >&2; exit 127; }
}

need nvidia-smi

# util%, mem used, mem total, temp C, clock MHz, name -- name last, it can hold a comma
nvidia-smi \
    --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,clocks.current.graphics,name \
    --format=csv,noheader,nounits
