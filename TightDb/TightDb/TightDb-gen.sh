TIGHTDB_H="$1"

if python TightDb-gen.py 8 >/tmp/objc-tightdb.h; then
	mv /tmp/objc-tightdb.h "$TIGHTDB_H"
else
	if [ -e "$TIGHTDB_H" ]; then
		echo "WARNING: Failed to update '$TIGHTDB_H'"
	else
		exit 1
	fi
fi
