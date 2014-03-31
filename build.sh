# NOTE: THIS SCRIPT IS SUPPOSED TO RUN IN A POSIX SHELL

ORIG_CWD="$(pwd)" || exit 1
cd "$(dirname "$0")" || exit 1
TIGHTDB_OBJC_HOME="$(pwd)" || exit 1


# load command functions
if [ common_funcs.sh ]; then
    . $TIGHTDB_OBJC_HOME/common_funcs.sh
else
    echo "Cannot load common functions."
    exit 1
fi


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
MAKE="make"
NUM_PROCESSORS=""
if [ "$OS" = "Darwin" ]; then
    NUM_PROCESSORS="$(sysctl -n hw.ncpu)" || exit 1
else
    if [ -r "/proc/cpuinfo" ]; then
        NUM_PROCESSORS="$(cat /proc/cpuinfo | grep -E 'processor[[:space:]]*:' | wc -l)" || exit 1
    fi
fi
if [ "$NUM_PROCESSORS" ]; then
    word_list_prepend MAKEFLAGS "-j$NUM_PROCESSORS" || exit 1
    export MAKEFLAGS
fi


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


CONFIG_MK="src/config.mk"

require_config()
{
    cd "$TIGHTDB_OBJC_HOME" || return 1
    if ! [ -e "$CONFIG_MK" ]; then
        cat 1>&2 <<EOF
ERROR: Found no configuration!
You need to run 'sh build.sh config [PREFIX]'.
EOF
        return 1
    fi
    echo "Using existing configuration in $CONFIG_MK:"
    cat "$CONFIG_MK" | sed 's/^/    /' || return 1
}

auto_configure()
{
    cd "$TIGHTDB_OBJC_HOME" || return 1
    if [ -e "$CONFIG_MK" ]; then
        require_config || return 1
    else
        echo "No configuration found. Running 'sh build.sh config' for you."
        sh build.sh config || return 1
    fi
}

get_config_param()
{
    local name line value
    name="$1"
    cd "$TIGHTDB_OBJC_HOME" || return 1
    if ! [ -e "$CONFIG_MK" ]; then
        cat 1>&2 <<EOF
ERROR: Found no configuration!
You need to run 'sh build.sh config [PREFIX]'.
EOF
        return 1
    fi
    if ! line="$(grep "^$name *=" "$CONFIG_MK")"; then
        cat 1>&2 <<EOF
ERROR: Failed to read configuration parameter '$name'.
Maybe you need to rerun 'sh build.sh config [PREFIX]'.
EOF
        return 1
    fi
    value="$(printf "%s\n" "$line" | cut -d= -f2-)" || return 1
    value="$(printf "%s\n" "$value" | sed 's/^ *//')" || return 1
    printf "%s\n" "$value"
}



case "$MODE" in

    "config")
        install_prefix="$1"
        if ! [ "$install_prefix" ]; then
            install_prefix="/usr/local"
        fi

        # See
        # http://www.gc3.uzh.ch/blog/Compile_a_Objective-C_application_on_Ubuntu___40__Hobbes_instance__41__
        # for a possible way of getting it to work on Linux when
        # compiling with Clang.
        if [ "$OS" != "Darwin" ]; then
            echo "ERROR: Currently, the Objective-C extension is only available on Mac OS X" 1>&2
            exit 1
        fi

        install_exec_prefix="$(NO_CONFIG_MK="1" $MAKE --no-print-directory prefix="$install_prefix" get-exec-prefix)" || exit 1
        install_includedir="$(NO_CONFIG_MK="1" $MAKE --no-print-directory prefix="$install_prefix" get-includedir)" || exit 1
        install_bindir="$(NO_CONFIG_MK="1" $MAKE --no-print-directory prefix="$install_prefix" get-bindir)" || exit 1
        install_libdir="$(NO_CONFIG_MK="1" $MAKE --no-print-directory prefix="$install_prefix" get-libdir)" || exit 1
        install_libexecdir="$(NO_CONFIG_MK="1" $MAKE --no-print-directory prefix="$install_prefix" get-libexecdir)" || exit 1

        # Find TightDB
        if [ -z "$TIGHTDB_CONFIG" ]; then
            TIGHTDB_CONFIG="tightdb-config"
        fi
        if printf "%s\n" "$TIGHTDB_CONFIG" | grep -q '^/'; then
            if ! [ -x "$TIGHTDB_CONFIG" ]; then
                tightdb_abort "ERROR: TightDB config-program '$TIGHTDB_CONFIG' does not exist" "Cannot find '$TIGHTDB_CONFIG' - skipping"
            fi
            tightdb_config_cmd="$TIGHTDB_CONFIG"
        elif ! tightdb_config_cmd="$(which "$TIGHTDB_CONFIG" 2>/dev/null)"; then
            tightdb_abort "ERROR: TightDB config-program '$TIGHTDB_CONFIG' not found in PATH" "Cannot find '$TIGHTDB_CONFIG' - skipping"
        fi
        tightdb_config_dbg_cmd="$tightdb_config_cmd-dbg"
        if ! [ -x "$tightdb_config_dbg_cmd" ]; then
            tightdb_abort "ERROR: TightDB config-program '$tightdb_config_dbg_cmd' not found" "Cannot find '$tightdb_config_dbg_cmd' - skipping"
        fi
        tightdb_version="$($tightdb_config_cmd --version)" || exit 1

        tightdb_cflags="$($tightdb_config_cmd --cflags)"         || exit 1
        tightdb_cflags_dbg="$($tightdb_config_dbg_cmd --cflags)" || exit 1
        tightdb_ldflags="$($tightdb_config_cmd --libs)"          || exit 1
        tightdb_ldflags_dbg="$($tightdb_config_dbg_cmd --libs)"  || exit 1

        tightdb_includedir="$($tightdb_config_cmd --includedir)" || exit 1
        tightdb_libdir="$($tightdb_config_cmd --libdir)"         || exit 1
        tightdb_rpath="$tightdb_libdir"

        # `TIGHTDB_DIST_INCLUDEDIR` and `TIGHTDB_DIST_LIBDIR` are set
        # when configuration occurs in the context of a distribution
        # package.
        if [ "$TIGHTDB_DIST_INCLUDEDIR" ] && [ "$TIGHTDB_DIST_LIBDIR" ]; then
            tightdb_includedir="$TIGHTDB_DIST_INCLUDEDIR"
            tightdb_libdir="$TIGHTDB_DIST_LIBDIR"
        else
            tightdb_includedir="$($tightdb_config_cmd --includedir)" || exit 1
            tightdb_libdir="$($tightdb_config_cmd --libdir)"         || exit 1
        fi
        tightdb_rpath="$($tightdb_config_cmd --libdir)" || exit 1

        cflags="-I$tightdb_includedir"
        ldflags="-L$tightdb_libdir -Wl,-rpath,$tightdb_rpath"
        word_list_prepend "tightdb_cflags"      "$cflags"  || exit 1
        word_list_prepend "tightdb_cflags_dbg"  "$cflags"  || exit 1
        word_list_prepend "tightdb_ldflags"     "$ldflags" || exit 1
        word_list_prepend "tightdb_ldflags_dbg" "$ldflags" || exit 1

        # Find Xcode
        xcode_home="none"
        arm64_supported=""
        if [ "$OS" = "Darwin" ]; then
            if path="$(xcode-select --print-path 2>/dev/null)"; then
                xcode_home="$path"
            fi
            xcodebuild="$xcode_home/usr/bin/xcodebuild"
            version="$("$xcodebuild" -version)" || exit 1
            version="$(printf "%s" "$version" | grep -E '^Xcode +[0-9]+\.[0-9]' | head -n1)"
            version="$(printf "%s" "$version" | sed 's/^Xcode *\([0-9A-Z_.-]*\).*$/\1/')" || exit 1
            if ! printf "%s" "$version" | grep -q -E '^[0-9]+(\.[0-9]+)+$'; then
                echo "Failed to determine Xcode version using \`$xcodebuild -version\`" 1>&2
                exit 1
            fi
            major="$(printf "%s" "$version" | cut -d. -f1)" || exit 1
            if [ "$major" -ge "5" ]; then
                arm64_supported="1"
            fi
        fi

        # Find iPhone SDKs
        iphone_sdks=""
        iphone_sdks_avail="no"
        if [ "$xcode_home" != "none" ]; then
            # Xcode provides the iPhoneOS SDK
            iphone_sdks_avail="yes"
            for x in $IPHONE_PLATFORMS; do
                platform_home="$xcode_home/Platforms/$x.platform"
                if ! [ -e "$platform_home/Info.plist" ]; then
                    tightdb_echo "Failed to find '$platform_home/Info.plist'"
                    iphone_sdks_avail="no"
                else
                    sdk="$(find_iphone_sdk "$platform_home")" || exit 1
                    if ! [ "$sdk" ]; then
                        tightdb_echo "Found no SDKs in '$platform_home'"
                        iphone_sdks_avail="no"
                    else
                        if [ "$x" = "iPhoneSimulator" ]; then
                            archs="i386,x86_64"
                        elif [  "$x" = "iPhoneOS" ]; then
                            archs="armv7,armv7s"
                            if [ "$arm64_supported" ]; then
                                archs="$archs,arm64"
                            fi
                        else
                            continue
                        fi
                        word_list_append "iphone_sdks" "$x:$sdk:$archs" || exit 1
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
            tightdb_echo "Could not find home of TightDB core library built for iPhone"
        fi

	touch "$CONFIG_MK" || { echo "Can't overwrite $CONFIG_MK."; exit 1; }

        cat >"$CONFIG_MK" <<EOF
INSTALL_PREFIX      = $install_prefix
INSTALL_EXEC_PREFIX = $install_exec_prefix
INSTALL_INCLUDEDIR  = $install_includedir
INSTALL_BINDIR      = $install_bindir
INSTALL_LIBDIR      = $install_libdir
INSTALL_LIBEXECDIR  = $install_libexecdir
TIGHTDB_CONFIG      = $tightdb_config_cmd
TIGHTDB_VERSION     = $tightdb_version
TIGHTDB_CFLAGS      = $tightdb_cflags
TIGHTDB_CFLAGS_DBG  = $tightdb_cflags_dbg
TIGHTDB_LDFLAGS     = $tightdb_ldflags
TIGHTDB_LDFLAGS_DBG = $tightdb_ldflags_dbg
XCODE_HOME          = $xcode_home
IPHONE_SDKS         = ${iphone_sdks:-none}
IPHONE_SDKS_AVAIL   = $iphone_sdks_avail
IPHONE_CORE_LIB     = $iphone_core_lib
EOF
        if ! [ "$INTERACTIVE" ]; then
            echo "New configuration in $CONFIG_MK:"
            cat "$CONFIG_MK" | sed 's/^/    /' || exit 1
            echo "Done configuring"
        fi
        exit 0
        ;;

    "get-version")
	version_file="src/tightdb/objc/TDBVersion.h"
	tightdb_version_major="$(grep TDB_VERSION_MAJOR $version_file | awk '{print $3}' | tr -d ";")" || exit 1
	tightdb_version_minor="$(grep TDB_VERSION_MINOR $version_file | awk '{print $3}' | tr -d ";")" || exit 1
	tightdb_version_patch="$(grep TDB_VERSION_PATCH $version_file | awk '{print $3}' | tr -d ";")" || exit 1
	echo "$tightdb_version_major.$tightdb_version_minor.$tightdb_version_patch"
	exit 0
	;;

    "set-version")
	if [ "$OS" != "Darwin" ]; then
	    echo "You can only set version when running Mac OS X"
	    exit 1
	fi
        tightdb_version="$1"
        version_file="src/tightdb/objc/TDBVersion.h"
        tightdb_ver_major="$(echo "$tightdb_version" | cut -f1 -d.)" || exit 1
        tightdb_ver_minor="$(echo "$tightdb_version" | cut -f2 -d.)" || exit 1
        tightdb_ver_patch="$(echo "$tightdb_version" | cut -f3 -d.)" || exit 1

	sed -i '' -e "s/TDB_VERSION_MAJOR .*$/TDB_VERSION_MAJOR $tightdb_ver_major/" $version_file || exit 1
	sed -i '' -e "s/TDB_VERSION_MINOR .*$/TDB_VERSION_MINOR $tightdb_ver_minor/" $version_file || exit 1
	sed -i '' -e "s/TDB_VERSION_PATCH .*$/TDB_VERSION_PATCH $tightdb_ver_patch/" $version_file || exit 1
	exit 0
	;;

    "clean")
        auto_configure || exit 1
        $MAKE clean || exit 1
        if [ "$OS" = "Darwin" ]; then
            for x in $IPHONE_PLATFORMS; do
                $MAKE BASE_DENOM="$x" clean || exit 1
            done
            $MAKE BASE_DENOM="ios" clean || exit 1
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
#        TIGHTDB_ENABLE_FAT_BINARIES="1" $MAKE || exit 1
        $MAKE || exit 1
        tightdb_echo "Done building"
        exit 0
        ;;

    "build-iphone")
        auto_configure || exit 1
        iphone_sdks_avail="$(get_config_param "IPHONE_SDKS_AVAIL")" || exit 1
        if [ "$iphone_sdks_avail" != "yes" ]; then
            tightdb_abort "ERROR: iPhone SDKs were not found during configuration"
        fi
        iphone_core_lib="$(get_config_param "IPHONE_CORE_LIB")" || exit 1
        if [ "$iphone_core_lib" = "none" ]; then
            tightdb_abort "ERROR: TightDB core library for iPhone was not found during configuration"
        fi
        if ! [ -e "$iphone_core_lib/libtightdb-ios.a" ]; then
            tightdb_abort "ERROR: TightDB core library for iPhone is not available in '$iphone_core_lib'"
        fi
        temp_dir="$(mktemp -d /tmp/tightdb.objc.build-iphone.XXXX)" || exit 1
        xcode_home="$(get_config_param "XCODE_HOME")" || exit 1
        iphone_sdks="$(get_config_param "IPHONE_SDKS")" || exit 1
        iphone_include="$iphone_core_lib/include"
        path_list_prepend "PATH" "$iphone_core_lib" || exit 1
        export PATH
        for x in $iphone_sdks; do
            platform="$(printf "%s\n" "$x" | cut -d: -f1)" || exit 1
            sdk="$(printf "%s\n" "$x" | cut -d: -f2)" || exit 1
            archs="$(printf "%s\n" "$x" | cut -d: -f3 | sed 's/,/ /g')" || exit 1
            cflags_arch=""
            for y in $archs; do
                word_list_append "cflags_arch" "-arch $y" || exit 1
            done
            sdk_root="$xcode_home/Platforms/$platform.platform/Developer/SDKs/$sdk"
            $MAKE -C "src/tightdb/objc" "libtightdb-objc-$platform.a" "libtightdb-objc-$platform-dbg.a" BASE_DENOM="$platform" CFLAGS_ARCH="$cflags_arch -isysroot $sdk_root -I$iphone_include" || exit 1
            mkdir "$temp_dir/$platform" || exit 1
            cp "src/tightdb/objc/libtightdb-objc-$platform.a"     "$temp_dir/$platform/libtightdb-objc.a"     || exit 1
            cp "src/tightdb/objc/libtightdb-objc-$platform-dbg.a" "$temp_dir/$platform/libtightdb-objc-dbg.a" || exit 1
        done
        mkdir -p "$IPHONE_DIR" || exit 1
        tightdb_echo "Creating '$IPHONE_DIR/libtightdb-objc-ios.a'"
        lipo "$temp_dir"/*/"libtightdb-objc.a" -create -output "$temp_dir/libtightdb-objc-ios.a" || exit 1
        libtool -static -o "$IPHONE_DIR/libtightdb-objc-ios.a" "$temp_dir/libtightdb-objc-ios.a" $(tightdb-config --libs) -L"$iphone_core_lib" || exit 1
        tightdb_echo "Creating '$IPHONE_DIR/libtightdb-objc-ios-dbg.a'"
        lipo "$temp_dir"/*/"libtightdb-objc-dbg.a" -create -output "$temp_dir/libtightdb-objc-ios-dbg.a" || exit 1
        libtool -static -o "$IPHONE_DIR/libtightdb-objc-ios-dbg.a" "$temp_dir/libtightdb-objc-ios-dbg.a" $(tightdb-config-dbg --libs) -L"$iphone_core_lib" || exit 1
        tightdb_echo "Copying headers to '$IPHONE_DIR/include'"
        mkdir -p "$IPHONE_DIR/include/tightdb/objc" || exit 1
        inst_headers="$(cd src/tightdb/objc && $MAKE --no-print-directory get-inst-headers)" || exit 1
        (cd "src/tightdb/objc" && cp $inst_headers "$TIGHTDB_OBJC_HOME/$IPHONE_DIR/include/tightdb/objc/") || exit 1
        tightdb_echo "Done building"
        exit 0
        ;;

    "ios-framework")
        if [ "$OS" != "Darwin" ]; then
	    echo "Framework for iOS can only be generated under Mac OS X"
	    exit 0
	fi
	tightdb_version="$(sh build.sh get-version)"
	FRAMEWORK=Tightdb.framework
	rm -rf "$FRAMEWORK" tightdb-ios*.zip || exit 1
	mkdir -p "$FRAMEWORK/Headers" || exit 1
	cp iphone-lib/libtightdb-objc-ios.a "$FRAMEWORK/Tightdb" || exit 1
	cp iphone-lib/include/tightdb/objc/*.h "$FRAMEWORK/Headers" || exit 1
	(cd "$FRAMEWORK/Headers" && mv tightdb.h Tightdb.h) || exit 1
	find "$FRAMEWORK/Headers" -name '*.h' -exec sed -i '' -e 's/import <tightdb\/objc\/\(.*\)>/import "\1"/g' {} \; || exit 1
	find "$FRAMEWORK/Headers" -name '*.h' -exec sed -i '' -e 's/include <tightdb\/objc\/\(.*\)>/include "\1"/g' {} \; || exit 1
	zip -r -q tightdb-ios-$tightdb_version.zip $FRAMEWORK || exit 1
	echo "Framwork for iOS can be found in tightdb-ios-$tightdb_version.zip"
	exit 0
	;;

    "test")
        auto_configure || exit 1
        $MAKE check-norun || exit 1
        TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.test.XXXX)" || exit 1
        mkdir -p "$TEMP_DIR/unit-tests.octest/Contents/MacOS" || exit 1
        cp "src/tightdb/objc/test/unit-tests" "$TEMP_DIR/unit-tests.octest/Contents/MacOS/" || exit 1
        XCODE_HOME="$(xcode-select --print-path)" || exit 1
        path_list_prepend DYLD_LIBRARY_PATH "$TIGHTDB_OBJC_HOME/src/tightdb/objc" || exit 1
        export DYLD_LIBRARY_PATH
        OBJC_DISABLE_GC=YES "$XCODE_HOME/Tools/otest" "$TEMP_DIR/unit-tests.octest" || exit 1
        echo "Test passed"
        exit 0
        ;;

    "test-debug")
        auto_configure || exit 1
        $MAKE check-debug-norun || exit 1
        TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.test-debug.XXXX)" || exit 1
        mkdir -p "$TEMP_DIR/unit-tests-dbg.octest/Contents/MacOS" || exit 1
        cp "src/tightdb/objc/test/unit-tests-dbg" "$TEMP_DIR/unit-tests-dbg.octest/Contents/MacOS/" || exit 1
        XCODE_HOME="$(xcode-select --print-path)" || exit 1
        path_list_prepend DYLD_LIBRARY_PATH "$TIGHTDB_OBJC_HOME/src/tightdb/objc" || exit 1
        export DYLD_LIBRARY_PATH
        OBJC_DISABLE_GC=YES "$XCODE_HOME/Tools/otest" "$TEMP_DIR/unit-tests-dbg.octest" || exit 1
        echo "Test passed"
        exit 0
        ;;

    "test-gdb")
        auto_configure || exit 1
        $MAKE check-debug-norun || exit 1
        TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.test-gdb.XXXX)" || exit 1
        mkdir -p "$TEMP_DIR/unit-tests-dbg.octest/Contents/MacOS" || exit 1
        cp "src/tightdb/objc/test/unit-tests-dbg" "$TEMP_DIR/unit-tests-dbg.octest/Contents/MacOS/" || exit 1
        XCODE_HOME="$(xcode-select --print-path)" || exit 1
        path_list_prepend DYLD_LIBRARY_PATH "$TIGHTDB_OBJC_HOME/src/tightdb/objc" || exit 1
        export DYLD_LIBRARY_PATH
        OBJC_DISABLE_GC=YES gdb --args "$XCODE_HOME/Tools/otest" "$TEMP_DIR/unit-tests-dbg.octest"
        ;;

    "check-doc-examples")
        auto_configure || exit 1
        $MAKE check-doc-examples || exit 1
        ;;

    "test-cover")
        auto_configure || exit 1
        $MAKE check-cover-norun || exit 1
        TEMP_DIR="$(mktemp -d /tmp/tightdb.objc.check-cover.XXXX)" || exit 1
        mkdir -p "$TEMP_DIR/unit-tests-cov.octest/Contents/MacOS" || exit 1
        cp "src/tightdb/objc/test/unit-tests-cov" "$TEMP_DIR/unit-tests-cov.octest/Contents/MacOS/" || exit 1
        XCODE_HOME="$(xcode-select --print-path)" || exit 1
        DYLD_LIBRARY_PATH="$TIGHTDB_OBJC_HOME/src/tightdb/objc" OBJC_DISABLE_GC=YES "$XCODE_HOME/Tools/otest" "$TEMP_DIR/unit-tests-cov.octest" || exit 1
        echo "Generating 'gcovr.xml'.."
        gcovr -f '.*/tightdb_objc/src/.*' -e '.*/test/.*' -x > gcovr.xml
        echo "Test passed."
        exit 0
        ;;

    "test-examples")
        auto_configure || exit 1
        $MAKE test -C "examples" || exit 1
        ;;

    "install-report")
        has_installed=0
        install_libdir="$(get_config_param "INSTALL_LIBDIR")"
        find $install_libdir -name '*tightdb*' | while read f; do
            has_installed=1
            echo "  $f"
        done
        exit $has_installed
        ;;

    "show-install")
        temp_dir="$(mktemp -d /tmp/tightdb.objc.show-install.XXXX)" || exit 1
        mkdir "$temp_dir/fake-root" || exit 1
        DESTDIR="$temp_dir/fake-root" sh build.sh install >/dev/null || exit 1
        (cd "$temp_dir/fake-root" && find * \! -type d >"$temp_dir/list") || exit 1
        sed 's|^|/|' <"$temp_dir/list" || exit 1
        rm -fr "$temp_dir/fake-root" || exit 1
        rm "$temp_dir/list" || exit 1
        rmdir "$temp_dir" || exit 1
        exit 0
        ;;

    "install")
        require_config || exit 1
        $MAKE install-only DESTDIR="$DESTDIR" || exit 1
        tightdb_echo "Done installing"
        exit 0
        ;;

    "install-prod")
        require_config || exit 1
        $MAKE install-only DESTDIR="$DESTDIR" INSTALL_FILTER="shared-libs,progs" || exit 1
        tightdb_echo "Done installing"
        exit 0
        ;;

    "install-devel")
        require_config || exit 1
        $MAKE install-only DESTDIR="$DESTDIR" INSTALL_FILTER="static-libs,dev-progs,headers" || exit 1
        tigtdb_echo "Done installing"
        exit 0
        ;;

    "uninstall")
        require_config || exit 1
        $MAKE uninstall || exit 1
        echo "Done uninstalling"
        exit 0
        ;;

    "uninstall-prod")
        require_config || exit 1
        $MAKE uninstall INSTALL_FILTER="shared-libs,progs" || exit 1
        echo "Done uninstalling"
        exit 0
        ;;

    "uninstall-devel")
        require_config || exit 1
        $MAKE uninstall INSTALL_FILTER="static-libs,dev-progs,headers" || exit 1
        echo "Done uninstalling"
        exit 0
        ;;

    "test-installed")
        require_config || exit 1
        install_includedir="$(get_config_param "INSTALL_INCLUDEDIR")" || exit 1
        install_libdir="$(get_config_param "INSTALL_LIBDIR")" || exit 1
        export TIGHTDB_OBJC_INCLUDEDIR="$install_includedir"
        export TIGHTDB_OBJC_LIBDIR="$install_libdir"
        $MAKE -C "test-installed" clean || exit 1
        $MAKE -C "test-installed" check || exit 1
        echo "Test passed"
        exit 0
        ;;

    "build-test-core")
        ## Setup directories
        cd test-core

        DIR="iOSTestCoreAppTests"
        
        mkdir -p "$DIR" || exit 1
        rm -rf "$DIR/*" || exit 1
        rm -rf "iOSTestCoreApp.xcodeproj"
        rm -f "iOSTestCoreApp.gyp"

        ## Copy sources and unit tests
        function build_test_core_cp {
            mkdir -p "$DIR/$2" || exit 1
            find "../../tightdb/$1/" -maxdepth 1 \
                -type f -iregex "^.*\.[ch]\(pp\)\{0,1\}$" \
                -exec cp {} "$DIR/$2/" \; || exit 1
        }

        cp ../../tightdb/src/tightdb.hpp "$DIR/"
        build_test_core_cp src/tightdb tightdb
        build_test_core_cp src/tightdb/util tightdb/util
        build_test_core_cp src/tightdb/impl tightdb/impl
 
        build_test_core_cp test
        build_test_core_cp test/util util
        build_test_core_cp test/large_tests large_tests

        ## Remove breaking files (containing main or unportable code).
        rm "$DIR/main.cpp"
        rm "$DIR/tightdb/config_tool.cpp"
        rm "$DIR/tightdb/importer_tool.cpp"
        rm "$DIR/tightdb/tightdbd.cpp"
        rm "$DIR/tightdb/replication.cpp"

        ## Replace all dynamic includes with static includes
        find $DIR \
            -type f -iregex "^.*\.[ch]\(pp\)\{0,1\}$" \
            -exec sed -i '' \
                -e 's/<tightdb\(.*\)>/"tightdb\1"/g' \
                -e 's/<UnitTest++\.h>/"UnitTest++.h"/g' {} \; || exit 1

        ## Create an XCTestCase
        cat >"$DIR/iOSTestCoreAppTests.mm" <<EOF
#import <XCTest/XCTest.h>
#include "run_tests.hpp"

@interface iOSTestCoreAppTests : XCTestCase

@end

@implementation iOSTestCoreAppTests

-(void)testRunTests
{
    // Change working directory to somewhere we can write.
    [[NSFileManager defaultManager]
        changeCurrentDirectoryPath:(NSTemporaryDirectory())];
    run_tests(0, NULL);
}

@end
EOF

        ## Gather all the sources in a Python-friendly format.
        APP_TESTS_SOURCES=$(find iOSTestCoreAppTests -type f | \
            sed -E 's/^(.*)$/                "\1",/')

        ## Create a gyp file.
        # To use xctest, the project must have an app and a test target. The
        # app can be left fairly featureless, but enough must exist for us to
        # trick Xcode into thinking it's testing the app.
        cat >"iOSTestCoreApp.gyp" <<EOF
{
    'xcode_settings': {
        'ARCHS': [
            '\$(ARCHS_STANDARD_INCLUDING_64_BIT)',
        ],
        'SDKROOT': 'iphoneos',
        'TARGETED_DEVICE_FAMILY': '1,2', # iPhone/iPad
        'FRAMEWORK_SEARCH_PATHS': [
            '\$(SDKROOT)/Developer/Library/Frameworks',
        ],
        'CODE_SIGN_IDENTITY[sdk=iphoneos*]': 'iPhone Developer: Oleksandr(Alex Shturmov (CB4YV2W7W5)',
    },
    'targets': [
        {
            'target_name': 'iOSTestCoreApp',
            'type': 'executable',
            'mac_bundle': 1,
            'sources': [
                './iOSTestCoreApp/AppDelegate.h',
                './iOSTestCoreApp/AppDelegate.m',
                './iOSTestCoreApp/main.m',
            ],
            'mac_bundle_resources': [
                './iOSTestCoreApp/Images.xcassets',
                './iOSTestCoreApp/en.lproj/InfoPlist.strings',
                './iOSTestCoreApp/iOSTestCoreApp-Info.plist',
                './iOSTestCoreApp/iOSTestCoreApp-Prefix.pch',
            ],
            'link_settings': {
                'libraries': [
                    '\$(SDKROOT)/System/Library/Frameworks/Foundation.framework',
                    '\$(SDKROOT)/System/Library/Frameworks/CoreGraphics.framework',
                    '\$(SDKROOT)/System/Library/Frameworks/UIKit.framework',
                ],
            },
            'xcode_settings': {
                'SDKROOT': 'iphoneos',
                'WRAPPER_EXTENSION': 'app',
                'INFOPLIST_FILE': 'iOSTestCoreApp/iOSTestCoreApp-Info.plist',
                'GCC_PRECOMPILE_PREFIX_HEADER': 'YES',
                'GCC_PREFIX_HEADER': 'iOSTestCoreApp/iOSTestCoreApp-Prefix.pch',
            }
        },
        {
            'target_name': 'iOSTestCoreAppTests',

            # see pylib/gyp/generator/xcode.py
            'type': 'loadable_module',
            'mac_xctest_bundle': 1,
            'sources': [
$APP_TESTS_SOURCES
            ],
            'dependencies': [
                'iOSTestCoreApp'
            ],
            'include_dirs': [
                './iOSTestCoreAppTests/**'
            ],
            'link_settings': {
                'libraries': [
                    '\$(SDKROOT)/usr/lib/libc++.dylib',
                    '\$(DEVELOPER_DIR)/Library/Frameworks/XCTest.framework',
                ],
            },
            'xcode_settings': {
                'SDKROOT': 'iphoneos',
                'WRAPPER_EXTENSION': 'xctest',
                'BUNDLE_LOADER': '\$(BUILT_PRODUCTS_DIR)/iOSTestCoreApp.app/iOSTestCoreApp',
                'TEST_HOST': '\$(BUNDLE_LOADER)',
            },
        },
    ],
}
EOF
        ## Run gyp, generating an .xcodeproj folder with a project.pbxproj file.
        gyp --depth="." "iOSTestCoreApp.gyp" || exit 1

        ## Collect the main app id from the project.pbxproj file.
        APP_ID=$(cat iOSTestCoreApp.xcodeproj/project.pbxproj | tr -d '\n' | \
            egrep -o "remoteGlobalIDString.*?remoteInfo = iOSTestCoreApp;" | \
            head -n 1 | sed 's/remoteGlobalIDString = \([A-F0-9]*\);.*/\1/')

        ## Collect the test app id from the project.pbxproj file.
        APP_TEST_ID=$(cat iOSTestCoreApp.xcodeproj/project.pbxproj | tr -d '\n' | \
            egrep -o "remoteGlobalIDString.*?remoteInfo = iOSTestCoreAppTests;" | \
            head -n 1 | sed 's/remoteGlobalIDString = \([A-F0-9]*\);.*/\1/')

        ## Generate a scheme with a test action.
        USER=$(whoami)
        mkdir -p "iOSTestCoreApp.xcodeproj/xcuserdata"
        mkdir -p "iOSTestCoreApp.xcodeproj/xcuserdata/$USER.xcuserdatad"
        mkdir -p "iOSTestCoreApp.xcodeproj/xcuserdata/$USER.xcuserdatad/xcschemes"
        cat >"iOSTestCoreApp.xcodeproj/xcuserdata/$USER.xcuserdatad/xcschemes/iOSTestCoreApp.xcscheme" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "0500"
   version = "1.3">
   <TestAction
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      buildConfiguration = "Default">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "$APP_TEST_ID"
               BuildableName = "iOSTestCoreAppTests.xctest"
               BlueprintName = "iOSTestCoreAppTests"
               ReferencedContainer = "container:iOSTestCoreApp.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$APP_ID"
            BuildableName = "iOSTestCoreApp.app"
            BlueprintName = "iOSTestCoreApp"
            ReferencedContainer = "container:iOSTestCoreApp.xcodeproj">
         </BuildableReference>
      </MacroExpansion>
   </TestAction>
</Scheme>
EOF
        ## We are now ready to invoke the test action.
        echo "Done building"
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
/common_funcs.sh
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
        cat << EOF
Unspecified or bad mode '$MODE'.
Available modes are:
  config clean build build-iphone test test-debug test-gdb test-cover
  show-install install uninstall test-installed install-prod install-devel
  uninstall-prod uninstall-devel dist-copy ios-framework
  get-version set-version
EOF
        exit 1
        ;;

esac
