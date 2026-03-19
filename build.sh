#!/bin/zsh
set -e

# ── Config ────────────────────────────────────────────────────────────────────
readonly EXE_NAME="silicon"
readonly BUILD_DIR="build"
readonly SRC_DIR="src"
readonly DOC_DIR="docs"

OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
TARGET_OS=${TARGET_OS:-$OS_TYPE}
TARGET_ARCH=${TARGET_ARCH:-amd64}

[[ "$TARGET_OS" == "windows" || "$OS_TYPE" == *"mingw"* || "$OS_TYPE" == *"msys"* ]] \
    && EXE_EXT=".exe" || EXE_EXT=""

OUTPUT_PATH="$BUILD_DIR/$EXE_NAME$EXE_EXT"
ACTION=${1:-debug}

# ── Common compiler flags ─────────────────────────────────────────────────────
common_flags=(
    -vet-cast -vet-style -vet-using-param -strict-style
    -disallow-do -warnings-as-errors
    -collection:libs=./libs/
    -target:${TARGET_OS}_${TARGET_ARCH}
)

# ── Banner ────────────────────────────────────────────────────────────────────
banner() {
    echo "-------------------------------------------"
    echo "  SILICON  >>  Engine Build System"
    echo "-------------------------------------------"
}

# ── Help ──────────────────────────────────────────────────────────────────────
show_help() {
    echo "Usage: ./build.sh [command]"
    echo ""
    echo "Commands:"
    echo "  debug      Build with debug symbols and run  (default)"
    echo "  release    Build optimized (-o:speed) and run"
    echo "  check      Type-check only, no binary"
    echo "  profile    Build with debug symbols + compiler timings"
    echo "  doc        Generate documentation site via doc-gen/gen.py"
    echo "  clean      Remove the '$BUILD_DIR' directory"
    echo "  help       Show this message"
    echo ""
    echo "Env vars:"
    echo "  TARGET_OS    Target OS  (default: $OS_TYPE)"
    echo "  TARGET_ARCH  Target arch (default: amd64)"
    echo ""
    echo "Examples:"
    echo "  ./build.sh"
    echo "  ./build.sh release"
    echo "  ./build.sh doc"
    echo "  TARGET_OS=windows ./build.sh release"
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
case "$ACTION" in

    help|-h|--help)
        show_help
        exit 0 ;;

    clean)
        echo "🧹 Cleaning $BUILD_DIR..."
        rm -rf "$BUILD_DIR"
        echo "✅ Done"
        exit 0 ;;

    doc)
        banner
        echo "📖 Generating documentation..."
        if ! command -v python3 &>/dev/null; then
            echo "❌ python3 not found — required to generate docs"
            exit 1
        fi
        python3 "$DOC_DIR/gen.py"
        echo "✅ Docs written to $DOC_DIR/index.html"
        exit 0 ;;

    check)
        banner
        echo "🔍 MODE: CHECK"
        odin check "$SRC_DIR" "${common_flags[@]}"
        echo "✅ No errors"
        exit 0 ;;

    debug)   mode_flags=(-debug);               label="🐞 DEBUG ($TARGET_OS)" ;;
    release) mode_flags=(-o:speed);             label="🚀 RELEASE ($TARGET_OS)" ;;
    profile) mode_flags=(-debug -show-timings); label="⏱  PROFILE" ;;

    *)
        echo "❓ Unknown command: '$ACTION'"
        echo "   Run './build.sh help' for usage"
        exit 1 ;;
esac

# ── Build ─────────────────────────────────────────────────────────────────────
banner
echo "$label"
mkdir -p "$BUILD_DIR"
start=$(date +%s%N)

if odin build "$SRC_DIR" "${mode_flags[@]}" "${common_flags[@]}" -out:"$OUTPUT_PATH"; then
    elapsed=$(( ($(date +%s%N) - start) / 1000000 ))
    echo "✅ Built in ${elapsed}ms → $OUTPUT_PATH"
    echo "-------------------------------------------"
    if [[ "$ACTION" != "profile" && "$TARGET_OS" == "$OS_TYPE" ]]; then
        echo "▶  Running..."
        "./$OUTPUT_PATH"
    fi
else
    echo "❌ Build failed"
    exit 1
fi
