# NOTE: THIS SCRIPT IS SUPPOSED TO RUN IN A POSIX SHELL

ORIG_CWD="$(pwd)"
cd "$(dirname "$0")"
TIGHTDB_OBJC_HOME="$(pwd)"

MODE="$1"
[ $# -gt 0 ] && shift


IPHONE_PLATFORMS="iPhoneOS iPhoneSimulator"
IPHONE_DIR="iphone-lib"


word_list_append()
{
    local list_name new_word list
    list_name="$1"
    new_word="$2"
    list="$(eval "printf \"%s\\n\" \"\${$list_name}\"")" || return 1
    if [ "$list" ]; then
        eval "$list_name=\"\$list \$new_word\""
    else
        eval "$list_name=\"\$new_word\""
    fi
    return 0
}

word_list_prepend()
{
    local list_name new_word list
    list_name="$1"
    new_word="$2"
    list="$(eval "printf \"%s\\n\" \"\${$list_name}\"")" || return 1
    if [ "$list" ]; then
        eval "$list_name=\"\$new_word \$list\""
    else
        eval "$list_name=\"\$new_word\""
    fi
    return 0
}

path_list_prepend()
{
    local list_name new_path list
    list_name="$1"
    new_path="$2"
    list="$(eval "printf \"%s\\n\" \"\${$list_name}\"")" || return 1
    if [ "$list" ]; then
        eval "$list_name=\"\$new_path:\$list\""
    else
        eval "$list_name=\"\$new_path\""
    fi
    return 0
}



# Setup OS specific stuff
OS="$(uname)" || exit 1
NUM_PROCESSORS=""
if [ "$OS" = "Darwin" ]; then
    NUM_PROCESSORS="$(sysctl -n hw.ncpu)" || exit 1
else
    if [ -r /proc/cpuinfo ]; then
        NUM_PROCESSORS="$(cat /proc/cpuinfo | grep -E 'processor[[:space:]]*:' | wc -l)" || exit 1
    fi
fi
if [ "$NUM_PROCESSORS" ]; then
    word_list_prepend MAKEFLAGS "-j$NUM_PROCESSORS" || exit 1
fi
export MAKEFLAGS


find_iphone_sdk()
{
    local platform_home sdks version path x version2 sorted highest ambiguous
    platform_home="$1"
    sdks="$platform_home/Developer/SDKs"
    version=""
    dir=""
    ambiguous=""
    cd "$sdks" || return 1
    for x in *; do
        settings="$sdks/$x/SDKSettings"
        version2="$(defaults read "$sdks/$x/SDKSettings" Version)" || return 1
        if ! printf "%s\n" "$version2" | grep -q '^[0-9][0-9]*\(\.[0-9][0-9]*\)\{0,3\}$'; then
            echo "Uninterpretable 'Version' '$version2' in '$settings'" 1>&2
            return 1
        fi
        if [ "$version" ]; then
            sorted="$(printf "%s\n%s\n" "$version" "$version2" | sort -t . -k 1,1nr -k 2,2nr -k 3,3nr -k 4,4nr)" || return 1
            highest="$(printf "%s\n" "$sorted" | head -n 1)" || return 1
            if [ "$highest" = "$version2" ]; then
                if [ "$highest" = "$version" ]; then
                    ambiguous="1"
                else
                    version="$version2"
                    dir="$x"
                    ambiguous=""
                fi
            fi
        else
            version="$version2"
            dir="$x"
        fi
    done
    if [ "$ambiguous" ]; then
        echo "Ambiguous highest SDK version '$version' in '$sdks'" 1>&2
        return 1
    fi
    printf "%s\n" "$dir"
}


require_config()
{
    cd "$TIGHTDB_OBJC_HOME" || return 1
    if ! [ -e "config" ]; then
        cat 1>&2 <<EOF
ERROR: Found no configuration!
You need to run 'sh build.sh config [PREFIX]'.
EOF
        return 1
    fi
    echo "Using existing configuration:"
    cat "config" | sed 's/^/    /' || return 1
}

auto_configure()
{
    cd "$TIGHTDB_OBJC_HOME" || return 1
    if [ -e "config" ]; then
        require_config || return 1
    else
        echo "No configuration found. Running 'sh build.sh config'"
        sh build.sh config || return 1
    fi
}

get_config_param()
{
    local name line value
    cd "$TIGHTDB_OBJC_HOME" || return 1
    name="$1"
    if ! [ -e "config" ]; then
        cat 1>&2 <<EOF
ERROR: Found no configuration!
You need to run 'sh build.sh config [PREFIX]'.
EOF
        return 1
    fi
    if ! line="$(grep "^$name:" "config")"; then
        cat 1>&2 <<EOF
ERROR: Failed to read configuration parameter '$name'.
Maybe you need to rerun 'sh build.sh config [PREFIX]'.
EOF
        return 1
    fi
    value="$(printf "%s\n" "$line" | cut -d: -f2-)" || return 1
    value="$(printf "%s\n" "$value" | sed 's/^ *//')" || return 1
    printf "%s\n" "$value"
}



case "$MODE" in

    "config")
        install_prefix="$1"
        if [ -z "$install_prefix" ]; then
            install_prefix="/usr/local"
        fi
        install_libdir="$(make prefix="$install_prefix" get-libdir)" || exit 1

        if [ "$OS" != "Darwin" ]; then
            echo "ERROR: Currently, the Objective-C extension is only available on Mac OS X" 1>&2
            exit 1
        fi

        xcode_home="none"
        if [ "$OS" = "Darwin" ]; then
            if path="$(xcode-select --print-path 2>/dev/null)"; then
                xcode_home="$path"
            fi
        fi

        iphone_sdks=""
        iphone_sdks_avail="no"
        if [ "$xcode_home" != "none" ]; then
            # Xcode provides the iPhoneOS SDK
            iphone_sdks_avail="yes"
            for x in $IPHONE_PLATFORMS; do
                platform_home="$xcode_home/Platforms/$x.platform"
                if ! [ -e "$platform_home/Info.plist" ]; then
                    echo "Failed to find '$platform_home/Info.plist'"
                    iphone_sdks_avail="no"
                else
                    sdk="$(find_iphone_sdk "$platform_home")" || exit 1
                    if [ -z "$sdk" ]; then
                        echo "Found no SDKs in '$platform_home'"
                        iphone_sdks_avail="no"
                    else
                        if [ "$x" = "iPhoneSimulator" ]; then
                            arch="i386"
                        else
                            type="$(defaults read-type "$platform_home/Info" "DefaultProperties")" || exit 1
                            if [ "$type" != "Type is dictionary" ]; then
                                echo "Unexpected type of value of key 'DefaultProperties' in '$platform_home/Info.plist'" 1>&2
                                exit 1
                            fi
                            temp_dir="$(mktemp -d "/tmp/tmp.XXXXXXXXXX")" || exit 1
                            chunk="$temp_dir/chunk.plist"
                            defaults read "$platform_home/Info" "DefaultProperties" >"$chunk" || exit 1
                            arch="$(defaults read "$chunk" NATIVE_ARCH)" || exit 1
                            rm -f "$chunk" || exit 1
                            rmdir "$temp_dir" || exit 1
                        fi
                        word_list_append "iphone_sdks" "$x:$sdk:$arch" || exit 1
                    fi
                fi
            done
        fi

        iphone_core_lib="none"
        if [ "$TIGHTDB_IPHONE_CORE_LIB" ]; then
            iphone_core_lib="$TIGHTDB_IPHONE_CORE_LIB"
            if ! printf "%s\n" "$iphone_core_lib" | grep -q '^/'; then
                iphone_core_lib="$ORIG_CWD/$iphone_core_lib"
            fi
        elif [ -e "../tightdb/build.sh" ]; then
            path="$(cd "../tightdb" || return 1; pwd)" || exit 1
            iphone_core_lib="$path/$IPHONE_DIR"
        else
            echo "Could not find home of TightDB core library built for iPhone!"
        fi

        cat >"config" <<EOF
install-prefix:    $install_prefix
install-libdir:    $install_libdir
xcode-home:        $xcode_home
iphone-sdks:       ${iphone_sdks:-none}
iphone-sdks-avail: $iphone_sdks_avail
iphone-core-lib:   $iphone_core_lib
EOF
        echo "New configuration:"
        cat "config" | sed 's/^/    /' || exit 1
        echo "Done configuring"
        exit 0
        ;;

    "clean")
        auto_configure || exit 1
        make clean || exit 1
        if [ "$OS" = "Darwin" ]; then
            for x in $IPHONE_PLATFORMS; do
                make BASE_DENOM="$x" clean || exit 1
            done
            make BASE_DENOM="ios" clean || exit 1
            if [ -e "$IPHONE_DIR" ]; then
                echo "Removing '$IPHONE_DIR'"
                rm -fr "$IPHONE_DIR/include" || exit 1
                rm -f "$IPHONE_DIR/libtightdb-objc-ios.a" "$IPHONE_DIR/libtightdb-objc-ios-dbg.a" || exit 1
                rmdir "$IPHONE_DIR" || exit 1
            fi
        fi
        echo "Done cleaning"
        exit 0
        ;;

    "build")
        auto_configure || exit 1
# FIXME: Our language binding requires that Objective-C ARC is enabled, which, in turn, is only available on a 64-bit architecture, so for now we cannot build a "fat" version.
#        TIGHTDB_ENABLE_FAT_BINARIES="1" make || exit 1
        make || exit 1
        echo "Done building"
        exit 0
        ;;

    "build-iphone")
        auto_configure || exit 1
        iphone_sdks_avail="$(get_config_param "iphone-sdks-avail")" || exit 1
        if [ "$iphone_sdks_avail" != "yes" ]; then
            echo "ERROR: iPhone SDKs were not found during configuration!" 1>&2
            exit 1
        fi
        iphone_core_lib="$(get_config_param "iphone-core-lib")" || exit 1
        if [ "$iphone_core_lib" = "none" ]; then
            echo "ERROR: TightDB core library for iPhone was not found during configuration!" 1>&2
            exit 1
        fi
        if ! [ -e "$iphone_core_lib/libtightdb-ios.a" ]; then
            echo "ERROR: TightDB core library for iPhone is not available in '$iphone_core_lib'!" 1>&2
            exit 1
        fi
        temp_dir="$(mktemp -d /tmp/tightdb.objc.build-iphone.XXXX)" || exit 1
        xcode_home="$(get_config_param "xcode-home")" || exit 1
        iphone_sdks="$(get_config_param "iphone-sdks")" || exit 1
        iphone_include="$iphone_core_lib/include"
        path_list_prepend "PATH" "$iphone_core_lib" || exit 1
        export PATH
        for x in $iphone_sdks; do
            platform="$(printf "%s\n" "$x" | cut -d: -f1)" || exit 1
            sdk="$(printf "%s\n" "$x" | cut -d: -f2)" || exit 1
            arch="$(printf "%s\n" "$x" | cut -d: -f3)" || exit 1
            sdk_root="$xcode_home/Platforms/$platform.platform/Developer/SDKs/$sdk"
            make -C "src/tightdb/objc" BASE_DENOM="$platform" CFLAGS_ARCH="-arch $arch -isysroot $sdk_root -I$iphone_include" "libtightdb-objc-$platform.a" "libtightdb-objc-$platform-dbg.a" || exit 1
            mkdir "$temp_dir/$platform" || exit 1
            cp "src/tightdb/objc/libtightdb-objc-$platform.a"     "$temp_dir/$platform/libtightdb-objc.a"     || exit 1
            cp "src/tightdb/objc/libtightdb-objc-$platform-dbg.a" "$temp_dir/$platform/libtightdb-objc-dbg.a" || exit 1
        done
        mkdir -p "$IPHONE_DIR" || exit 1
        echo "Creating '$IPHONE_DIR/libtightdb-objc-ios.a'"
        lipo "$temp_dir"/*/"libtightdb-objc.a" -create -output "$temp_dir/libtightdb-objc-ios.a" || exit 1
        libtool -static -o "$IPHONE_DIR/libtightdb-objc-ios.a" "$temp_dir/libtightdb-objc-ios.a" $(tightdb-config --libs) -L"$iphone_core_lib" || exit 1
        echo "Creating '$IPHONE_DIR/libtightdb-objc-ios-dbg.a'"
        lipo "$temp_dir"/*/"libtightdb-objc-dbg.a" -create -output "$temp_dir/libtightdb-objc-ios-dbg.a" || exit 1
        libtool -static -o "$IPHONE_DIR/libtightdb-objc-ios-dbg.a" "$temp_dir/libtightdb-objc-ios-dbg.a" $(tightdb-config-dbg --libs) -L"$iphone_core_lib" || exit 1
        echo "Copying headers to '$IPHONE_DIR/include'"
        mkdir -p "$IPHONE_DIR/include/tightdb/objc" || exit 1
        inst_headers="$(cd src/tightdb/objc && make get-inst-headers)" || exit 1
        (cd "src/tightdb/objc" && cp $inst_headers "$TIGHTDB_OBJC_HOME/$IPHONE_DIR/include/tightdb/objc/") || exit 1
        echo "Done building"
        exit 0
        ;;

    "test")
        require_config || exit 1
        make test-norun || exit 1
        TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.test.XXXX)" || exit 1
        mkdir -p "$TEMP_DIR/unit-tests.octest/Contents/MacOS" || exit 1
        cp "src/tightdb/objc/test/unit-tests" "$TEMP_DIR/unit-tests.octest/Contents/MacOS/" || exit 1
        XCODE_HOME="$(xcode-select --print-path)" || exit 1
        OBJC_DISABLE_GC=YES "$XCODE_HOME/Tools/otest" "$TEMP_DIR/unit-tests.octest" || exit 1
        echo "Test passed"
        exit 0
        ;;

    "test-debug")
        require_config || exit 1
        make test-debug-norun || exit 1
        TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.test-debug.XXXX)" || exit 1
        mkdir -p "$TEMP_DIR/unit-tests-dbg.octest/Contents/MacOS" || exit 1
        cp "src/tightdb/objc/test/unit-tests-dbg" "$TEMP_DIR/unit-tests-dbg.octest/Contents/MacOS/" || exit 1
        XCODE_HOME="$(xcode-select --print-path)" || exit 1
        OBJC_DISABLE_GC=YES "$XCODE_HOME/Tools/otest" "$TEMP_DIR/unit-tests-dbg.octest" || exit 1
        echo "Test passed"
        exit 0
        ;;

    "test-gdb")
        require_config || exit 1
        make test-debug-norun || exit 1
        TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.test-gdb.XXXX)" || exit 1
        mkdir -p "$TEMP_DIR/unit-tests-dbg.octest/Contents/MacOS" || exit 1
        cp "src/tightdb/objc/test/unit-tests-dbg" "$TEMP_DIR/unit-tests-dbg.octest/Contents/MacOS/" || exit 1
        XCODE_HOME="$(xcode-select --print-path)" || exit 1
        OBJC_DISABLE_GC=YES gdb --args "$XCODE_HOME/Tools/otest" "$TEMP_DIR/unit-tests-dbg.octest"
        ;;

    "install")
        require_config || exit 1
        install_prefix="$(get_config_param "install-prefix")" || exit 1
        make install-only DESTDIR="$DESTDIR" prefix="$install_prefix" || exit 1
        echo "Done installing"
        exit 0
        ;;

    "install-shared")
        require_config || exit 1
        install_prefix="$(get_config_param "install-prefix")" || exit 1
        make install-only DESTDIR="$DESTDIR" prefix="$install_prefix" INSTALL_FILTER=shared-libs || exit 1
        echo "Done installing"
        exit 0
        ;;

    "install-devel")
        require_config || exit 1
        install_prefix="$(get_config_param "install-prefix")" || exit 1
        make install-only DESTDIR="$DESTDIR" prefix="$install_prefix" INSTALL_FILTER=static-libs,progs,headers || exit 1
        echo "Done installing"
        exit 0
        ;;

    "uninstall")
        require_config || exit 1
        install_prefix="$(get_config_param "install-prefix")" || exit 1
        make uninstall prefix="$install_prefix" || exit 1
        echo "Done uninstalling"
        exit 0
        ;;

    "uninstall-shared")
        require_config || exit 1
        install_prefix="$(get_config_param "install-prefix")" || exit 1
        make uninstall prefix="$install_prefix" INSTALL_FILTER=shared-libs || exit 1
        echo "Done uninstalling"
        exit 0
        ;;

    "uninstall-devel")
        require_config || exit 1
        install_prefix="$(get_config_param "install-prefix")" || exit 1
        make uninstall prefix="$install_prefix" INSTALL_FILTER=static-libs,progs,extra || exit 1
        echo "Done uninstalling"
        exit 0
        ;;

    "test-installed")
        require_config || exit 1
        install_libdir="$(get_config_param "install-libdir")" || exit 1
        export LD_RUN_PATH="$install_libdir"
        make -C "test-installed" clean || exit 1
        make -C "test-installed" test  || exit 1
        echo "Test passed"
        exit 0
        ;;

    "dist-copy")
        # Copy to distribution package
        TARGET_DIR="$1"
        if ! [ "$TARGET_DIR" -a -d "$TARGET_DIR" ]; then
            echo "Unspecified or bad target directory '$TARGET_DIR'" 1>&2
            exit 1
        fi
        TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.copy.XXXX)" || exit 1
        cat >"$TEMP_DIR/include" <<EOF
/README.md
/build.sh
/generic.mk
/config.mk
/Makefile
/src
/test-installed
/test-iphone
/doc
EOF
        cat >"$TEMP_DIR/exclude" <<EOF
.gitignore
EOF
        grep -E -v '^(#.*)?$' "$TEMP_DIR/include" >"$TEMP_DIR/include2" || exit 1
        grep -E -v '^(#.*)?$' "$TEMP_DIR/exclude" >"$TEMP_DIR/exclude2" || exit 1
        sed -e 's/\([.\[^$]\)/\\\1/g' -e 's|\*|[^/]*|g' -e 's|^\([^/]\)|^\\(.*/\\)\\{0,1\\}\1|' -e 's|^/|^|' -e 's|$|\\(/.*\\)\\{0,1\\}$|' "$TEMP_DIR/include2" >"$TEMP_DIR/include.bre" || exit 1
        sed -e 's/\([.\[^$]\)/\\\1/g' -e 's|\*|[^/]*|g' -e 's|^\([^/]\)|^\\(.*/\\)\\{0,1\\}\1|' -e 's|^/|^|' -e 's|$|\\(/.*\\)\\{0,1\\}$|' "$TEMP_DIR/exclude2" >"$TEMP_DIR/exclude.bre" || exit 1
        git ls-files >"$TEMP_DIR/files1" || exit 1
        grep -f "$TEMP_DIR/include.bre" "$TEMP_DIR/files1" >"$TEMP_DIR/files2" || exit 1
        grep -v -f "$TEMP_DIR/exclude.bre" "$TEMP_DIR/files2" >"$TEMP_DIR/files3" || exit 1
        tar czf "$TEMP_DIR/archive.tar.gz" -T "$TEMP_DIR/files3" || exit 1
        (cd "$TARGET_DIR" && tar xzmf "$TEMP_DIR/archive.tar.gz") || exit 1
        if ! [ "$TIGHTDB_DISABLE_MARKDOWN_TO_PDF" ]; then
            (cd "$TARGET_DIR" && pandoc README.md -o README.pdf) || exit 1
        fi
        exit 0
        ;;

    *)
        echo "Unspecified or bad mode '$MODE'" 1>&2
        echo "Available modes are: config clean build build-iphone test test-debug test-gdb install uninstall test-installed" 1>&2
        echo "As well as: install-shared install-devel uninstall-shared uninstall-devel dist-copy" 1>&2
        exit 1
        ;;

esac
