#! /bin/sh

set -e

has_errors="no"
errors="$(mktemp)"

trap 'rm -f "$errors"' EXIT

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
                echo "* $1 has meson.build, but uses autotools" >> "$errors"
                return 1
            elif [ -f sources/$name/CMakeLists.txt ]; then
                echo "* $1 has CMakeLists.txt, but uses autotools" >> "$errors"
                return 1
            fi
            ;;
        cmake)
            # Check for meson.build
            if [ -f sources/$name/meson.build ]; then
                echo "* $1 has meson.build, but uses cmake" >> "$errors"
                return 1
            fi
            ;;
        meson)
            # We're good :)
            ;;
    esac

    # If we're using autotools, the next checks are not needed
    if [ "$build_system" = "autotools" ]; then
        return 0
    fi

    # Make sure we're using meson/cmake build/install commands
    # instead of calling ninja directly
    if grep -q 'ninja -C' "$1" || grep -q 'ninja -j' "$1" || grep -q 'ninja install' "$1"; then
        echo "* $1 uses ninja directly, but should use $build_system" >> "$errors"
        return 1
    fi
}

lint_recipe() {
    recipe_has_errors="no"

    # Make sure recipe has a shebang
    if ! grep -q '^#! /bin/sh' "$1"; then
        echo "$1 does not have a shebang" >> "$errors"
        recipe_has_errors="yes"
    fi

    # Check given recipes for bashisms
    bashisms="$(checkbashisms -npfxl "$1")"
    if [ $? -ne 0 ]; then
        echo "* $1 contains bashisms" >> "$errors"
        echo "$bashisms" >> "$errors"
        recipe_has_errors="yes"
    fi

    # Check for trailing whitespace
    if grep -q '[[:space:]]$' "$1"; then
        echo "* $1 contains trailing whitespace" >> "$errors"
        recipe_has_errors="yes"
    fi

    # Make sure file is indented with spaces
    if grep -Pq '\t' "$1"; then
        echo "* $1 contains tabs" >> "$errors"
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
    printf "* linting $recipe"

    if ! lint_recipe "$recipe"; then
        printf ' \033[31;1mfailed\033[0m\n'
        has_errors="yes"
    else
        printf ' \033[32;1mok\033[0m\n'
    fi
done

if [ "$has_errors" = "yes" ]; then
    printf '\033[31;1m'
    cat "$errors"
    printf '\033[0m'
    exit 1
fi
