#!/bin/bash
set -euf

# Forward SIGTERM to child
# Thank you https://unix.stackexchange.com/a/444676
prep_term() {
    unset term_child_pid
    unset term_kill_needed
    trap 'handle_term' TERM INT
}
handle_term() {
    if [ -n "${term_child_pid:-}" ]; then
        kill -TERM "${term_child_pid}" 2>/dev/null
    else
        term_kill_needed="yes"
    fi
}
wait_term() {
    term_child_pid=$!
    if [ -n "${term_kill_needed:-}" ]; then
        kill -TERM "${term_child_pid}" 2>/dev/null
    fi
    wait "${term_child_pid}"
    trap - TERM INT
    wait "${term_child_pid}"
}

# Copy default config if nonexistent
if ! [ -f "/data/config.json" ]; then
    cp /defaults/config.json /data/config.json
fi

# Gather prefixes if supplied
PREFIXES=""
if [ -n "${PREFIX5:-}" ]; then
    PREFIXES="--prefix ${PREFIX5} ${PREFIXES}"
    unset PREFIX5
fi
if [ -n "${PREFIX4:-}" ]; then
    PREFIXES="--prefix ${PREFIX4} ${PREFIXES}"
    unset PREFIX4
fi
if [ -n "${PREFIX3:-}" ]; then
    PREFIXES="--prefix ${PREFIX3} ${PREFIXES}"
    unset PREFIX3
fi
if [ -n "${PREFIX2:-}" ]; then
    PREFIXES="--prefix ${PREFIX2} ${PREFIXES}"
    unset PREFIX2
fi
if [ -n "${PREFIX:-}" ]; then
    PREFIXES="--prefix ${PREFIX} ${PREFIXES}"
    unset PREFIX
fi

# Set configurations
if [ -n "${OWNER:-}" ]; then
    echo "Setting bot owner..."
    redbot docker --edit --no-prompt --owner "${OWNER}"
    unset OWNER
fi

if [ -n "${TOKEN:-}" ]; then
    echo "Setting bot token..."
    redbot docker --edit --no-prompt --token "${TOKEN}"
    unset TOKEN
fi

if [ -n "${PREFIXES}" ]; then
    echo "Setting bot prefix(es)..."
    redbot docker --edit --no-prompt ${PREFIXES}
    unset PREFIXES
fi

# Main loop
echo "Starting Red-DiscordBot!"
RETURN_CODE=26
set +e
while [ "${RETURN_CODE}" -eq 26 ]; do
    # If we are running in an interactive shell, we can't (and don't need to) do any of the fancy interrupt catching
    if [ -t 0 ]; then
        redbot docker ${EXTRA_ARGS:-}
        RETURN_CODE=$?
    else
        prep_term
        redbot docker ${EXTRA_ARGS:-} &
        wait_term
        RETURN_CODE=$?
    fi
done
