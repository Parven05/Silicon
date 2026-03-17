#!/bin/zsh

set -e

readonly EXE_NAME="silicon"
readonly BUILD_DIR="build"
readonly SRC_DIR="src"

# Command options: debug (default), release, check, clean, profile
ACTION=${1:-debug}

common_flags=(
    -vet-cast -vet-style -vet-using-param -strict-style
    -disallow-do -warnings-as-errors -collection:libs=./libs/
)

# 1. Handle Clean
if [[ "$ACTION" == "clean" ]]; then
    echo "🧹 Cleaning build directory..."
    rm -rf "$BUILD_DIR"
    echo "✨ Done."
    exit 0
fi

echo "----------------------------------------------------------------"
echo "  ____ ___ _      ___ ____ ___  _   _ "
echo " / ___|_ _| |    |_ _/ ___/ _ \| \ | |"
echo " \___ \| || |     | | |  | | | |  \| |"
echo "  ___) | || |___  | | |__| |_| | |\  |"
echo " |____/___|_____|___\____\___/|_| \_|"
echo "        >> Engine Build System <<"
echo "----------------------------------------------------------------"

mkdir -p "$BUILD_DIR"
start_time=$(date +%s%N)

# 2. Handle Build Modes & Profiling
case "$ACTION" in
    release)
        mode_flags=(-o:speed)
        echo "🚀 MODE: RELEASE" ;;
    check)
        echo "🔍 MODE: CHECK"
        odin check "$SRC_DIR" "${common_flags[@]}"
        exit 0 ;;
    profile)
        mode_flags=(-debug -show-timings)
        echo "⏱️  MODE: PROFILE (Showing Build Timings)" ;;
    *)
        mode_flags=(-debug)
        echo "🐞 MODE: DEBUG" ;;
esac

echo "🔨 Compiling $EXE_NAME..."

if odin build "$SRC_DIR" "${mode_flags[@]}" "${common_flags[@]}" -out:"$BUILD_DIR/$EXE_NAME"; then
    elapsed=$(( ($(date +%s%N) - start_time) / 1000000 ))
    echo "✅ Build successful in ${elapsed}ms"
    echo "----------------------------------------------------------------"

    # Don't run the exe if we are just profiling/checking
    if [[ "$ACTION" != "profile" ]]; then
        echo "🚀 Running $EXE_NAME..."
        "./$BUILD_DIR/$EXE_NAME"
    fi
else
    echo -e "\n❌ Build failed."
    exit 1
fi
