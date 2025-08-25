# _DEBUG=true
# _BENCHMARK=true
_BENCHMARK_FILE=~/.tool-shell-integrations-benchmark.txt

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
    INTEGRATION_DIR=$1
    HOOK_TYPE=$2

    # detected if detect script is not found, to allow for "always detect" integrations
    DETECTED=0
    if [ -f $INTEGRATION_DIR/detect.sh ]; then
        bash $INTEGRATION_DIR/detect.sh
        DETECTED=$?
    fi

    if [ $DETECTED -eq 0 ]; then
        if [ "$HOOK_TYPE" = "env" ]; then
            _hook_shell_integration_single $INTEGRATION_DIR $HOOK_TYPE
        fi

        if [ "$HOOK_TYPE" = "rc" ]; then
            _hook_shell_integration_single $INTEGRATION_DIR $HOOK_TYPE
        fi

        if [ "$HOOK_TYPE" = "both" ]; then
            _hook_shell_integration_single $INTEGRATION_DIR "env"
            _hook_shell_integration_single $INTEGRATION_DIR "rc"
        fi
    fi
}

function _hook_shell_integrations() {
    TOOL_SHELL_INTEGRATIONS_DIR=$1
    HOOK_TYPE=$2

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
