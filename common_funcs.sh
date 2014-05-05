# common functions for build.sh and similar tools

# Second argument is optional
realm_abort()
{
    local message message2
    message="$1"
    message2="$2"
    if [ "$INTERACTIVE" ]; then
        if ! [ "$message2" ]; then
            message2="$message"
        fi
        printf "%s\n" "$message2"
        exit 0
    fi

    echo "$message" 1>&2
    exit 1
}

realm_echo()
{
    local message
    message="$1"
    if ! [ "$INTERACTIVE" ]; then
        printf "%s\n" "$message"
    fi
}
