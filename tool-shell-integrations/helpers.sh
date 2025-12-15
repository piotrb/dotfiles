# _DEBUG=true
# _BENCHMARK=true
_BENCHMARK_FILE=~/.tool-shell-integrations-benchmark.txt

# Track which integrations have been hooked at which level
# Format: associative array with keys like "integration_name:hook_type"
# Only declare if not already declared (to preserve state across multiple sourcing)
if [ -z "${_HOOKED_INTEGRATIONS+x}" ]; then
    declare -A _HOOKED_INTEGRATIONS
fi

function _mark_integration_hooked() {
    local INTEGRATION_NAME=$1
    local HOOK_TYPE=$2
    local key="${INTEGRATION_NAME}:${HOOK_TYPE}"
    _HOOKED_INTEGRATIONS[$key]=1
}

function _is_integration_hooked() {
    local INTEGRATION_NAME=$1
    local HOOK_TYPE=$2
    local key="${INTEGRATION_NAME}:${HOOK_TYPE}"
    local result="${_HOOKED_INTEGRATIONS[$key]}"
    [ -n "$result" ]
}

function _current_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

current_shell=$(_current_shell)

function _hook_shell_integration_single() {
    INTEGRATION_DIR=$1
    HOOK_TYPE=$2

    CURRENT_SHELL=$(_current_shell)

    if [ -f $INTEGRATION_DIR/hook.$HOOK_TYPE.sh ]; then
        if [ "$_DEBUG" = true ]; then
            tool_name=$(basename $INTEGRATION_DIR)
            echo " [debug] hooking $tool_name ($HOOK_TYPE) ..."
        fi
        . $INTEGRATION_DIR/hook.$HOOK_TYPE.sh
    fi

    if [ -f $INTEGRATION_DIR/hook.$HOOK_TYPE.$CURRENT_SHELL ]; then
        if [ "$_DEBUG" = true ]; then
            tool_name=$(basename $INTEGRATION_DIR)
            echo " [debug] hooking $tool_name ($HOOK_TYPE) [$CURRENT_SHELL] ..."
        fi
        . $INTEGRATION_DIR/hook.$HOOK_TYPE.$CURRENT_SHELL
    fi
}

function _hook_shell_integration_detect() {
    local INTEGRATION_DIR=$1
    local HOOK_TYPE=$2
    local INTEGRATION_NAME=$(basename $INTEGRATION_DIR)

    # detected if detect script is not found, to allow for "always detect" integrations
    local DETECTED=0
    if [ -f $INTEGRATION_DIR/detect.sh ]; then
        bash $INTEGRATION_DIR/detect.sh
        DETECTED=$?
    fi

    if [ $DETECTED -eq 0 ]; then
        if [ "$HOOK_TYPE" = "env" ]; then
            _hook_shell_integration_single $INTEGRATION_DIR $HOOK_TYPE
            _mark_integration_hooked $INTEGRATION_NAME "env"
        fi

        if [ "$HOOK_TYPE" = "rc" ]; then
            _hook_shell_integration_single $INTEGRATION_DIR $HOOK_TYPE
            _mark_integration_hooked $INTEGRATION_NAME "rc"
        fi

        if [ "$HOOK_TYPE" = "both" ]; then
            # Hook env if not already hooked
            if ! _is_integration_hooked $INTEGRATION_NAME "env"; then
                _hook_shell_integration_single $INTEGRATION_DIR "env"
                _mark_integration_hooked $INTEGRATION_NAME "env"
            fi
            
            # Hook rc if not already hooked
            if ! _is_integration_hooked $INTEGRATION_NAME "rc"; then
                _hook_shell_integration_single $INTEGRATION_DIR "rc"
                _mark_integration_hooked $INTEGRATION_NAME "rc"
            fi
        fi
    fi
}

function _hook_shell_integrations() {
    local TOOL_SHELL_INTEGRATIONS_DIR=$1
    local HOOK_TYPE=$2

    if [ "$_BENCHMARK" = true ]; then
        rm -f $_BENCHMARK_FILE
        touch $_BENCHMARK_FILE
        echo "--- Benchmark ---" >> $_BENCHMARK_FILE
        echo "--- $(date) ---" >> $_BENCHMARK_FILE

        all_start_time=$(($(date +%s)*1000 + $(date +%N)/1000000))
    fi

    for i in $(find $TOOL_SHELL_INTEGRATIONS_DIR/* -type d); do
        if [ "$_BENCHMARK" = true ]; then
            # Capture the start time in milliseconds for each item
            start_time=$(($(date +%s)*1000 + $(date +%N)/1000000))
        fi

        _hook_shell_integration_detect $i $HOOK_TYPE

        if [ "$_BENCHMARK" = true ]; then
            # Capture the end time in milliseconds for each item
            end_time=$(($(date +%s)*1000 + $(date +%N)/1000000))

            # Calculate the duration for each item
            duration=$((end_time - start_time))

            tool_name=$(basename $i)

            echo "   [debug] Execution time for $tool_name: ${duration} ms" >> $_BENCHMARK_FILE
        fi
    done

    if [ "$_BENCHMARK" = true ]; then
        all_end_time=$(($(date +%s)*1000 + $(date +%N)/1000000))
        all_duration=$((all_end_time - all_start_time))
        echo "--- Total execution time: ${all_duration} ms ---" >> $_BENCHMARK_FILE
    fi
}
