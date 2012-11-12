DIR="$(dirname "$0")"

TIGHTDB_H="$1"

TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.codegen.XXXX)" || exit 1
if python "$DIR/tightdb.h.py" 15 >"$TEMP_DIR/tightdb.h"; then
    mv "$TEMP_DIR/tightdb.h" "$TIGHTDB_H"
else
    if [ -e "$TIGHTDB_H" ]; then
        echo "WARNING: Failed to update '$TIGHTDB_H'"
    else
        exit 1
    fi
fi
