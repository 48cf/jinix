#! /bin/sh

set -e

has_errors="no"

print_error() {
    printf '\033[31;1m* error: '"$1"'\033[0m\n'
}

verify_build_system() {
    # Determine the build system used by the configure step
    name=$(basename "$1")
    build_system=$(grep '_configure' "$1" | sed -E 's|.* ([a-z]+)_configure.*|\1|')

    # If no build system is found, return
    if [ -z "$build_system" ]; then
        return 0
    fi

    case "$build_system" in
        autotools)
            # Check for meson.build or CMakeLists.txt
            if [ -f sources/$name/meson.build ]; then
                print_error "$name has meson.build, but uses autotools"
                return 1
            elif [ -f sources/$name/CMakeLists.txt ]; then
                print_error "$name has CMakeLists.txt, but uses autotools"
                return 1
            fi
            ;;
        cmake)
            # Check for meson.build
            if [ -f sources/$name/meson.build ]; then
                print_error "$name has meson.build, but uses cmake"
                return 1
            fi
            ;;
        meson)
            # We're good :)
            ;;
    esac
}

lint_recipe() {
    recipe_has_errors="no"

    # Make sure recipe has a shebang
    if ! grep -q '^#! /bin/sh' "$1"; then
        print_error "$1 does not have a shebang"
        recipe_has_errors="yes"
    fi

    # Check given recipes for bashisms
    if ! checkbashisms -npfxl "$1"; then
        # checkbashisms returns 4 if no bashisms were found
        print_error "$1 contains bashisms"
        recipe_has_errors="yes"
    fi

    # Check for trailing whitespace
    if grep -q '[[:space:]]$' "$1"; then
        print_error "$1 contains trailing whitespace"
        recipe_has_errors="yes"
    fi

    # Make sure file is indented with spaces
    if grep -Pq '\t' "$1"; then
        print_error "$1 contains tabs"
        recipe_has_errors="yes"
    fi

    # Check if recipe has a configure step
    if grep -q 'configure() {' "$1"; then
        if ! verify_build_system "$1"; then
            recipe_has_errors="yes"
        fi
    fi

    if [ "$recipe_has_errors" = "yes" ]; then
        return 1
    fi
}

for recipe in "$@"; do
    echo "* linting $recipe"

    if ! lint_recipe "$recipe"; then
        has_errors="yes"
    fi
done

if [ "$has_errors" = "yes" ]; then
    exit 1
fi
