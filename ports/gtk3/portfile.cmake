set(warning_length 24)
string(LENGTH "${CURRENT_BUILDTREES_DIR}" buildtrees_path_length)
if(buildtrees_path_length GREATER warning_length AND CMAKE_HOST_WIN32)
    message(WARNING "${PORT}'s buildsystem uses very long paths and may fail on your system.\n"
        "We recommend moving vcpkg to a short path such as 'C:\\vcpkg' or using the subst command."
    )
endif()

vcpkg_from_gitlab(
    OUT_SOURCE_PATH SOURCE_PATH
    GITLAB_URL https://gitlab.gnome.org
    REPO GNOME/gtk
    REF "${VERSION}"
    SHA512 19e5482e4e843aa946ab79c8ce283a7b44aaac43ad99b6913cbc3c91492bf722ebe0238457b75b82be6d6c65a394d32ebc8732832f3f800145e3cf69d5c1e77c
    PATCHES
        0001-build.patch
        cairo-cpp-linkage.patch
)

vcpkg_find_acquire_program(PKGCONFIG)
get_filename_component(PKGCONFIG_DIR "${PKGCONFIG}" DIRECTORY )
vcpkg_add_to_path("${PKGCONFIG_DIR}") # Post install script runs pkg-config so it needs to be on PATH
vcpkg_add_to_path("${CURRENT_HOST_INSTALLED_DIR}/tools/glib/")
vcpkg_add_to_path("${CURRENT_HOST_INSTALLED_DIR}/tools/gdk-pixbuf")
vcpkg_add_to_path("${CURRENT_HOST_INSTALLED_DIR}/tools/gettext/bin")


if("introspection" IN_LIST FEATURES)
    list(APPEND OPTIONS_RELEASE -Dintrospection=true)
    vcpkg_get_gobject_introspection_programs(PYTHON3 GIR_COMPILER GIR_SCANNER)
else()
    list(APPEND OPTIONS_RELEASE -Dintrospection=false)
endif()

vcpkg_configure_meson(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${OPTIONS}
        -Dwayland_backend=false
        -Ddemos=false
        -Dexamples=false
        -Dtests=false
        -Dgtk_doc=false
        -Dman=false
        -Dxinerama=no               # Enable support for the X11 Xinerama extension
        -Dcloudproviders=false      # Enable the cloudproviders support
        -Dprofiler=false            # include tracing support for sysprof
        -Dtracker3=false            # Enable Tracker3 filechooser search
        -Dcolord=no                 # Build colord support for the CUPS printing backend
    OPTIONS_RELEASE
        ${OPTIONS_RELEASE}
    OPTIONS_DEBUG
        -Dintrospection=false
    ADDITIONAL_BINARIES
        "glib-genmarshal='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-genmarshal'"
        "glib-mkenums='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-mkenums'"
        "glib-compile-resources='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-compile-resources${VCPKG_HOST_EXECUTABLE_SUFFIX}'"
        "gdbus-codegen='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/gdbus-codegen'"
        "glib-compile-schemas='${CURRENT_HOST_INSTALLED_DIR}/tools/glib/glib-compile-schemas${VCPKG_HOST_EXECUTABLE_SUFFIX}'"
        "g-ir-compiler='${GIR_COMPILER}'"
        "g-ir-scanner='${GIR_SCANNER}'"
)

# Reduce command line lengths, in particular for static windows builds.
foreach(dir IN ITEMS "${TARGET_TRIPLET}-dbg" "${TARGET_TRIPLET}-rel")
    if(EXISTS "${CURRENT_BUILDTREES_DIR}/${dir}/build.ninja")
        vcpkg_replace_string("${CURRENT_BUILDTREES_DIR}/${dir}/build.ninja" "/${dir}/../src/" "/src/")
    endif()
endforeach()
vcpkg_install_meson(ADD_BIN_TO_PATH)

vcpkg_copy_pdbs()

vcpkg_fixup_pkgconfig()

set(GTK_TOOLS
    gtk-builder-tool
    gtk-encode-symbolic-svg
    gtk-launch
    gtk-query-immodules-3.0
    gtk-query-settings
    gtk-update-icon-cache
)
vcpkg_copy_tools(TOOL_NAMES ${GTK_TOOLS} AUTO_CLEAN)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/etc")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
