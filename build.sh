#!/bin/zsh

set -e

readonly EXE_NAME="silicon"
readonly BUILD_DIR="build"
readonly SRC_DIR="src"

OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
TARGET_OS=${TARGET_OS:-$OS_TYPE}
TARGET_ARCH=${TARGET_ARCH:-amd64}

EXE_EXT=""
[[ "$TARGET_OS" == "windows" || "$OS_TYPE" == *"mingw"* || "$OS_TYPE" == *"msys"* ]] && EXE_EXT=".exe"

OUTPUT_PATH="$BUILD_DIR/$EXE_NAME$EXE_EXT"
ACTION=${1:-debug}

show_help() {
    echo "Usage: ./build.sh [command]"
    echo ""
    echo "Commands:"
    echo "  debug      (Default) Builds with debug symbols and runs the app."
    echo "  release    Builds with optimizations (-o:speed) and runs the app."
    echo "  check      Runs Odin's type-checker only (very fast, no binary produced)."
    echo "  profile    Builds with debug symbols and shows compiler timing statistics."
    echo "  clean      Removes the '$BUILD_DIR' directory."
    echo "  help       Shows this help message."
    echo ""
    echo "Environment Variables:"
    echo "  TARGET_OS    Set target OS (e.g., windows, linux, darwin). Default: $OS_TYPE"
    echo "  TARGET_ARCH  Set target architecture (e.g., amd64, arm64). Default: amd64"
    echo ""
    echo "Example:"
    echo "  TARGET_OS=windows ./build.sh release"
}

if [[ "$ACTION" == "help" || "$ACTION" == "--help" || "$ACTION" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$ACTION" == "clean" ]]; then
    echo "🧹 Cleaning..."
    rm -rf "$BUILD_DIR"
    exit 0
fi

echo "----------------------------------------------------------------"
echo "  ____ ___ _      ___ ____ ___  _   _ "
echo " / ___|_ _| |    |_ _/ ___/ _ \| \ | |"
echo " \___ \| || |     | | |  | | | |  \| |"
echo "  ___) | || |___  | | |__| |_| | |\  |"
echo " |____/___|_____|___\____\___/|_| \_|"
echo "       >> Engine Build System <<"
echo "----------------------------------------------------------------"

common_flags=(
    -vet-cast -vet-style -vet-using-param -strict-style
    -disallow-do -warnings-as-errors -collection:libs=./libs/
    -target:${TARGET_OS}_${TARGET_ARCH}
)

mkdir -p "$BUILD_DIR"
start_time=$(date +%s%N)

case "$ACTION" in
    release)
        mode_flags=(-o:speed)
        echo "🚀 MODE: RELEASE ($TARGET_OS)" ;;
    check)
        echo "🔍 MODE: CHECK"
        odin check "$SRC_DIR" "${common_flags[@]}"
        exit 0 ;;
    profile)
        mode_flags=(-debug -show-timings)
        echo "⏱️  MODE: PROFILE" ;;
    debug)
        mode_flags=(-debug)
        echo "🐞 MODE: DEBUG ($TARGET_OS)" ;;
    *)
        echo "❓ Unknown command: $ACTION"
        show_help
        exit 1 ;;
esac

if odin build "$SRC_DIR" "${mode_flags[@]}" "${common_flags[@]}" -out:"$OUTPUT_PATH"; then
    elapsed=$(( ($(date +%s%N) - start_time) / 1000000 ))
    echo "✅ Success in ${elapsed}ms"
    echo "----------------------------------------------------------------"

    if [[ "$ACTION" != "profile" && "$TARGET_OS" == "$OS_TYPE" ]]; then
        echo "🚀 Running..."
        "./$OUTPUT_PATH"
    fi
else
    echo -e "\n❌ Build failed."
    exit 1
fi
