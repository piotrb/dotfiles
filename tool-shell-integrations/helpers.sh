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

# Inline assignment - no fork
if [[ -n $ZSH_VERSION ]]; then
    current_shell="zsh"
elif [[ -n $BASH_VERSION ]]; then
    current_shell="bash"
else
    current_shell="unknown"
fi

function _hook_shell_integration_single() {
    local INTEGRATION_DIR=$1
    local HOOK_TYPE=$2

    if [[ -f $INTEGRATION_DIR/hook.$HOOK_TYPE.sh ]]; then
        . "$INTEGRATION_DIR/hook.$HOOK_TYPE.sh"
    fi

    if [[ -f $INTEGRATION_DIR/hook.$HOOK_TYPE.$current_shell ]]; then
        . "$INTEGRATION_DIR/hook.$HOOK_TYPE.$current_shell"
    fi
}

function _debug() {
    echo "$@" >> ~/.shell-debug-log.txt
}

function _detect_integration() {
    local dir=$1
    local name
    name=$(basename "$dir")
    local ec=0
    local method=""

    if [[ -f $dir/detect.command ]]; then
        method="command"
        local cmd
        read -r cmd < "$dir/detect.command"
        command -v "$cmd" >/dev/null 2>&1
        ec=$?
    elif [[ -f $dir/detect.path ]]; then
        method="path"
        local path_to_check
        read -r path_to_check < "$dir/detect.path"
        path_to_check="${path_to_check/#\~/$HOME}"
        [[ -e $path_to_check ]]
        ec=$?
    elif [[ -f $dir/detect.env ]]; then
        method="env"
        local detect_content
        read -r detect_content < "$dir/detect.env"
        local var="${detect_content%%=*}"
        local val="${detect_content#*=}"
        if [[ -n $ZSH_VERSION ]]; then
            [[ ${(P)var} == $val ]]
        else
            [[ ${!var} == $val ]]
        fi
        ec=$?
    elif [[ -f $dir/detect.sh ]]; then
        method="detect.sh"
        ( . $dir/detect.sh ) 1>/dev/null 2>/dev/null
        ec=$?
    else
        return 0  # no detect = always enabled
    fi

    local status_str
    (( ec == 0 )) && status_str="detected" || status_str="not detected"
    _debug "$name (via $method) $status_str"
    return $ec
}

function _hook_shell_integration_detect() {
    local INTEGRATION_DIR=$1
    local HOOK_TYPE=$2
    local INTEGRATION_NAME
    INTEGRATION_NAME=$(basename "$INTEGRATION_DIR")

    _detect_integration "$INTEGRATION_DIR" || return 0

    if [ "$HOOK_TYPE" = "env" ]; then
        _hook_shell_integration_single "$INTEGRATION_DIR" "$HOOK_TYPE"
        _mark_integration_hooked "$INTEGRATION_NAME" "env"
    fi

    if [ "$HOOK_TYPE" = "rc" ]; then
        _hook_shell_integration_single "$INTEGRATION_DIR" "$HOOK_TYPE"
        _mark_integration_hooked "$INTEGRATION_NAME" "rc"
    fi

    if [ "$HOOK_TYPE" = "both" ]; then
        if ! _is_integration_hooked "$INTEGRATION_NAME" "env"; then
            _hook_shell_integration_single "$INTEGRATION_DIR" "env"
            _mark_integration_hooked "$INTEGRATION_NAME" "env"
        fi

        if ! _is_integration_hooked "$INTEGRATION_NAME" "rc"; then
            _hook_shell_integration_single "$INTEGRATION_DIR" "rc"
            _mark_integration_hooked "$INTEGRATION_NAME" "rc"
        fi
    fi
}

function _hook_shell_integrations() {
    local TOOL_SHELL_INTEGRATIONS_DIR=$1
    local HOOK_TYPE=$2

    local i
    for i in "$TOOL_SHELL_INTEGRATIONS_DIR"/*/; do
        [[ -d "$i" ]] || continue
        _hook_shell_integration_detect "${i%/}" "$HOOK_TYPE"
    done
}
