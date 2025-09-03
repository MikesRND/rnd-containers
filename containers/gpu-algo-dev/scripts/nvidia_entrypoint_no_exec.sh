#!/bin/bash
# Modified NVIDIA entrypoint without exec to allow sourcing
# This script runs NVIDIA initialization but returns control to caller

# Run any NVIDIA-specific initialization
if [ -f /opt/nvidia/nvidia_entrypoint.sh ]; then
    # Source the original entrypoint but prevent it from exec'ing
    # by defining a function that overrides exec
    exec() {
        # Capture the command but don't actually exec
        echo "[nvidia_init] Would exec: $@" >&2
    }
    
    # Source the original script
    source /opt/nvidia/nvidia_entrypoint.sh || true
    
    # Restore exec
    unset -f exec
fi

# Additional NVIDIA environment setup if needed
export NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all}
export NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:-all}

# Return success
return 0 2>/dev/null || true