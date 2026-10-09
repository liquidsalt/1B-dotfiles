#!/usr/bin/env bash
# dependencies: nvidia-utils (nvidia-smi)
set -euo pipefail

# util%, mem used, mem total, temp C, clock MHz, name -- name last, it can hold a comma
nvidia-smi \
    --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,clocks.current.graphics,name \
    --format=csv,noheader,nounits
