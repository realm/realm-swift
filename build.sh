# NOTE: THIS SCRIPT IS SUPPOSED TO RUN IN A POSIX SHELL

cd "$(dirname "$0")"
TIGHTDB_OBJC_HOME="$(pwd)"

MODE="$1"
[ $# -gt 0 ] && shift


# Setup OS specific stuff
OS="$(uname)" || exit 1
NUM_PROCESSORS=""
if [ "$OS" = "Darwin" ]; then
    if [ "$CC" = "" ] && which clang >/dev/null; then
        export CC=clang
    fi
    NUM_PROCESSORS="$(sysctl -n hw.ncpu)" || exit 1
else
    if [ -r /proc/cpuinfo ]; then
        NUM_PROCESSORS="$(cat /proc/cpuinfo | egrep 'processor[[:space:]]*:' | wc -l)" || exit 1
    fi
fi
if [ "$NUM_PROCESSORS" ]; then
    export MAKEFLAGS="-j$NUM_PROCESSORS"
fi



case "$MODE" in

    "clean")
        make -C "TightDb/TightDb" clean
        exit 0
        ;;

    "build")
        TIGHTDB_ENABLE_FAT_BINARIES="1" make -C "TightDb/TightDb" || exit 1
        exit 0
        ;;

    "test")
        make -C "TightDb/TightDb" test || exit 1
        exit 0
        ;;

    "install")
        PREFIX="$1"
        if [ -z "$PREFIX" ]; then
            PREFIX="/usr/local"
        fi
        make -C "TightDb/TightDb" prefix="$PREFIX" install || exit 1
        exit 0
        ;;

    "test-installed")
        PREFIX="$1"
        echo "Not yet implemented" 1>&2
        exit 1
        ;;

    "dist-copy")
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
        exit 0
        ;;

    *)
        echo "Unspecified or bad mode '$MODE'" 1>&2
        echo "Available modes are: clean build test install test-installed" 1>&2
        echo "As well as: dist-copy" 1>&2
        exit 1
        ;;

esac
