# common functions for build.sh and similar tools

# Second parameter is optional
tightdb_abort()
{
    local message1, message2
    message1="$1"
    if [ -z "$2" ]; then
        message2=$2
    else
        message2="$2"
    fi
    if [ -z "$INTERACTIVE" ]; then
        echo "$message1" 1>&2
        exit 1
    else
        echo "$message2"
        exit 0
    fi 
}

tightdb_echo()
{
    local message="$1"
    if [ -z "$INTERACTIVE" ]; then
        echo "$message"
    fi
}
