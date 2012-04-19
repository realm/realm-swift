TIGHTDB_H="$1"

if python tightdb-gen.py 8 >/tmp/tightdb.h; then
	mv /tmp/tightdb.h "$TIGHTDB_H"
else
	if [ -e tightdb.h ]; then
		echo "WARNING: Failed to update '$TIGHTDB_H'"
	else
		exit 1
	fi
fi
