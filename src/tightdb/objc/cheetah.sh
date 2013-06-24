source="$1"
target="$2"

if which cheetah >/dev/null 2>&1; then
    cheetah fill --stdout "$source" >"$target" || exit 1
    exit 0
fi

cat 1>&2 <<EOF

ERROR: Failed to update '$target' because the 'cheetah' command is
missing.

If you are sure that '$target' is already up to date, fix
this with:

    touch $(pwd)/$target  # ONLY IF YOU ARE SURE!

Otherwise, you must install the Cheetah Template package. See the
README file in the top-level directory of this repository for details.

EOF

exit 1
