# Build script for make

do_companion_tools_make_get()
{
    CT_Fetch MAKE
}

do_companion_tools_make_extract()
{
    CT_ExtractPatch MAKE
    _prog_name=mingw32-make
    if [ "${MSYSTEM}" = "MINGW64" ]; then
        if [ -f "${CT_SRC_DIR}/make/Makefile.am.orig" ]; then
            CT_DoLog DEBUG "Make already renamed"
        else
            CT_Pushd "${CT_SRC_DIR}/make"
            CT_DoLog EXTRA "Changing the program name from 'make' to '${_prog_name}' in Makefile.am. at ${CT_SRC_DIR}/make"
            test -f Makefile.am.orig || mv Makefile.am Makefile.am.orig
            local _prog_name_am=${_prog_name//[^a-zA-Z0-9@]/_}
            sed -e "/bin_PROGRAMS/ { s:\bmake\b:${_prog_name}:g };
                    s:\bmake_\(SOURCES\|LDADD\|LDFLAGS\)\b:${_prog_name_am}_\1:g ;
                    s:\bEXTRA_make_\([A-Z]\+\):EXTRA_${_prog_name_am}_\1:g ;" \
                    Makefile.am.orig > Makefile.am
            # log the changes made to Makefile.am by sed
            diff -u Makefile.am.orig Makefile.am > Makefile.am.diff || true
            CT_DoExecLog ALL autoreconf -vfi
            CT_Popd
        fi
    fi
}

do_companion_tools_make_for_build()
{
    CT_DoStep INFO "Installing make for build"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-make-build"
    do_make_backend \
        host=${CT_BUILD} \
        prefix="${CT_BUILD_COMPTOOLS_DIR}" \
        cflags="${CT_CFLAGS_FOR_BUILD}" \
        ldflags="${CT_LDFLAGS_FOR_BUILD}"
    CT_Popd
    if [ "${CT_MAKE_GMAKE_SYMLINK}" = "y" ]; then
        CT_DoExecLog ALL ln -sv make "${CT_BUILD_COMPTOOLS_DIR}/bin/gmake"
    fi
    if [ "${CT_MAKE_GNUMAKE_SYMLINK}" = "y" ]; then
        CT_DoExecLog ALL ln -sv make "${CT_BUILD_COMPTOOLS_DIR}/bin/gnumake"
    fi
    CT_EndStep
}

do_companion_tools_make_for_host()
{
    CT_DoStep INFO "Installing make for host"
    CT_mkdir_pushd "${CT_BUILD_DIR}/build-make-host"
    do_make_backend \
        host=${CT_HOST} \
        prefix="${CT_PREFIX_DIR}" \
        cflags="${CT_CFLAGS_FOR_HOST}" \
        ldflags="${CT_LDFLAGS_FOR_HOST}"
    CT_Popd
    if [ "${CT_MAKE_GMAKE_SYMLINK}" = "y" ]; then
        CT_DoExecLog ALL ln -sv make "${CT_PREFIX_DIR}/bin/gmake"
    fi
    if [ "${CT_MAKE_GNUMAKE_SYMLINK}" = "y" ]; then
        CT_DoExecLog ALL ln -sv make "${CT_PREFIX_DIR}/bin/gnumake"
    fi
    CT_EndStep
}

do_make_backend()
{
    local host
    local prefix
    local cflags
    local ldflags
    local -a extra_config

    for arg in "$@"; do
        eval "${arg// /\\ }"
    done

    if [ "${host}" != "${CT_BUILD}" ]; then
        extra_config+=( --without-guile )
    fi

    CT_SRC_DIR=$(realpath --relative-to="$PWD" "$CT_SRC_DIR")

    CT_DoLog EXTRA "Configuring make"
    CT_DoExecLog CFG \
                     CFLAGS="${cflags}" \
                     LDFLAGS="${ldflags}" \
                     ${CONFIG_SHELL} \
                     "${CT_SRC_DIR}/make/configure" \
                     --host="${host}" \
                     --prefix="${prefix}" \
                     "${extra_config[@]}"

    CT_DoLog EXTRA "Building make"
    CT_DoExecLog ALL make

    CT_DoLog EXTRA "Installing make"
    CT_DoExecLog ALL make install
}
