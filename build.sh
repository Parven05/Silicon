#!/bin/zsh

set -e

readonly EXE_NAME="silicon"
readonly BUILD_DIR="build"
readonly SRC_DIR="src"

MODE=${1:-debug}

common_flags=(
    -vet-cast -vet-style -vet-using-param -strict-style
    -disallow-do -warnings-as-errors -collection:libs=./libs/
)

if [[ "$MODE" == "release" ]]; then
    mode_flags=(-o:speed)
    MODE_MSG="🚀 MODE: RELEASE (Optimized)"
else
    mode_flags=(-debug)
    MODE_MSG="🐞 MODE: DEBUG (Symbols Enabled)"
fi

echo "----------------------------------------------------------------"
echo "  ____ ___ _     ___ ____ ___  _   _ "
echo " / ___|_ _| |   |_ _/ ___/ _ \| \ | |"
echo " \___ \| || |    | | |  | | | |  \| |"
echo "  ___) | || |___ | | |__| |_| | |\  |"
echo " |____/___|_____|___\____\___/|_| \_|"
echo "       >> Engine Build System <<"
echo "----------------------------------------------------------------"

mkdir -p "$BUILD_DIR"

echo "$MODE_MSG"
echo "🔨 Compiling $EXE_NAME..."

start_time=$(date +%s%N)

if odin build "$SRC_DIR" "${mode_flags[@]}" "${common_flags[@]}" -out:"$BUILD_DIR/$EXE_NAME"; then
    elapsed=$(( ($(date +%s%N) - start_time) / 1000000 ))

    echo "✅ Build successful in ${elapsed}ms"
    echo "----------------------------------------------------------------"
    echo "🚀 Running $EXE_NAME..."
    "./$BUILD_DIR/$EXE_NAME"
else
    echo -e "\n❌ Build failed."
    exit 1
fi
