#!/usr/bin/env bash
# tm4u.sh - build steps for the TM4 Ultimate Edition recomp (inSAMity mod v4.19).
#
# Everything runs inside this folder. Build tools (cmake, ninja, pkg-config)
# come from .tools/venv, so nothing is installed system-wide. The disc lives in
# disc/ and is git-ignored: it never goes to GitHub.
#
# Usage: ./tm4u.sh <step> [extra args]
#   emitters   build the recompiler (psxrecomp-game + psxrecomp-bios)
#   probe      read the mod's disc identity, EXE header and seeds into probe/
#   analyze    run static function discovery over the mod's boot EXE
#   generate   generate the game C from the mod's disc
#   build      compile the game for this Mac (build-mac/)
#   run        start the compiled game
#   build-test compile a test build with the TCP debug server (build-mac-test/)
#   run-test   start the test build headless, debug server on port 4370
#   run-test-gl same, but OpenGL in a hidden window (present_shot works)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export PATH="$ROOT/.tools/venv/bin:$PATH"
PY="$ROOT/.tools/venv/bin/python"
DISC="$ROOT/disc/TM4_TM3_v4_19.cue"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || nproc)"

step="${1:-}"
[[ $# -gt 0 ]] && shift

case "$step" in
  emitters)
    bash psxrecomp/tools/ci/build_emitters.sh --framework psxrecomp --build-dir build-recompiler "$@"
    ;;
  probe)
    mkdir -p probe
    "$PY" psxrecomp/tools/new_project_layout/probe_disc.py "$DISC" \
      --json-out probe/disc_probe.json --write-catalog probe/catalog_identity.json \
      --write-seeds probe/probe_seeds.txt --write-game-toml probe/game.probe.toml \
      --write-boot-exe probe --disc-rel disc/TM4_TM3_v4_19.cue --out-dir disc \
      --players 4 "$@"
    ;;
  analyze)
    "$PY" psxrecomp/psxrecomp_cli.py analyze --project-root . --config game.toml "$@"
    ;;
  generate)
    "$PY" psxrecomp/psxrecomp_cli.py generate --project-root . --config game.toml --disc "$DISC" "$@"
    ;;
  build)
    cmake -S . -B build-mac -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DPSXRECOMP_REQUIRE_GAME_C=ON -DPSX_SETUP_WIZARD=ON "$@"
    cmake --build build-mac --target psx-runtime -j"$JOBS"
    ;;
  run)
    exe="$(find build-mac -maxdepth 2 -type f -perm -u+x -name 'TwistedMetal4*' | head -1)"
    [[ -n "$exe" ]] || { echo "no built game under build-mac/ - run ./tm4u.sh build first" >&2; exit 1; }
    cd "$(dirname "$exe")"
    exec "./$(basename "$exe")" "$@"
    ;;
  build-test)
    cmake -S . -B build-mac-test -G Ninja -DCMAKE_BUILD_TYPE=Release -DPSX_DEBUG_TOOLS=ON \
      -DPSXRECOMP_REQUIRE_GAME_C=ON -DPSX_SETUP_WIZARD=ON "$@"
    cmake --build build-mac-test --target psx-runtime -j"$JOBS"
    ;;
  run-test)
    cd build-mac-test
    exec ./TwistedMetal4_Recompiled --no-launcher --headless --disc "$DISC" --debug-port 4370 "$@"
    ;;
  run-test-gl)
    cd build-mac-test
    exec ./TwistedMetal4_Recompiled --no-launcher --hidden-window --disc "$DISC" --debug-port 4370 "$@"
    ;;
  *)
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
