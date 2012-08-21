cd "$(dirname "$0")"
TIGHTDB_OBJC_HOME="$(pwd)"

MODE="$1"
[ $# -gt 0 ] && shift



case "$MODE" in

    "copy")
        # Copy to distribution package
        TARGET_DIR="$1"
        if ! [ "$TARGET_DIR" -a -d "$TARGET_DIR" ]; then
            echo "Unspecified or bad target directory '$TARGET_DIR'" 1>&2
            exit 1
        fi
        TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.copy.XXXX)" || exit 1
        git ls-files -z >"$TEMP_DIR/files" || exit 1
        tar czf "$TEMP_DIR/archive.tar.gz" --null -T "$TEMP_DIR/files" || exit 1
        (cd "$TARGET_DIR" && tar xzf "$TEMP_DIR/archive.tar.gz") || exit 1
        ;;

    "build")
        exit 1
        ;;

    "test")
        exit 1
        ;;

    "install")
        PREFIX="$1"
        exit 1
        ;;

    "test-installed")
        PREFIX="$1"
        exit 1
        ;;

    *)
        echo "Unspecified or bad mode '$MODE'" 1>&2
        exit 1
        ;;

esac
