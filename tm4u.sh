#!/usr/bin/env bash
# tm4u.sh - build steps for the TM4 Ultimate Edition recomp (inSAMity mod V2.2, disc v4.31).
#
# Everything runs inside this folder. Build tools (cmake, ninja, pkg-config)
# come from .tools/venv, so nothing is installed system-wide. The disc lives in
# disc/ and is git-ignored: it never goes to GitHub.
#
# Usage: ./tm4u.sh <step> [extra args]
#   emitters   build the recompiler (psxrecomp-game + psxrecomp-bios)
#   probe      read the mod's disc identity, EXE header and seeds into probe/
#   analyze    run static function discovery over the mod's boot EXE
#   overlays <captures.json>
#              bake captured overlays into the executable (generated/overlays_static*.c)
#   pack-overlays   pack generated/overlays_static*.c into generated/overlays_static.tar.xz
#                   (the archive is what git keeps; the .c files are git-ignored)
#   unpack-overlays unpack that archive back into generated/ (CI does the same)
#   apply-patches   apply patches/psxrecomp/*.patch to the psxrecomp checkout
#                   (skips the ones already applied; CI applies them too)
#   generate   generate the game C from the mod's disc
#   build      compile the game for this Mac (build-mac/)
#   run        start the compiled game
#   build-test compile a test build with the TCP debug server (build-mac-test/)
#   run-test   start the test build headless, debug server on port 4370
#   run-test-gl same, but OpenGL in a hidden window (present_shot works)
#
# JOBS=<n> limits the parallel compile jobs of build / build-test (default: all
# cores). The baked overlay units are large, so fewer jobs need less memory.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export PATH="$ROOT/.tools/venv/bin:$PATH"
PY="$ROOT/.tools/venv/bin/python"
DISC="$ROOT/disc/TM4_TM3_v4_31.cue"
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc)}"

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
      --write-boot-exe probe --disc-rel disc/TM4_TM3_v4_31.cue --out-dir disc \
      --players 4 "$@"
    ;;
  analyze)
    "$PY" psxrecomp/psxrecomp_cli.py analyze --project-root . --config game.toml "$@"
    ;;
  overlays)
    captures="${1:?usage: ./tm4u.sh overlays <captures.json>}"
    shift
    mkdir -p probe
    "$PY" psxrecomp/tools/enrich_overlay_captures.py \
      --captures "$captures" --out probe/overlay_captures.enriched.json
    "$PY" psxrecomp/tools/compile_overlays.py --static --cps --force \
      --captures probe/overlay_captures.enriched.json --game-toml game.toml \
      --recompiler build-recompiler/psxrecomp-game \
      --runtime-include psxrecomp/runtime/include \
      --out-dir generated --gcc "$(command -v clang || command -v gcc)" "$@"
    # git keeps only the archive: repack whenever the bake wrote into generated/.
    out_dir=generated
    for a in "$@"; do [[ "$a" == --out-dir* ]] && out_dir=other; done
    [[ "$out_dir" == other ]] || "$ROOT/tm4u.sh" pack-overlays
    ;;
  pack-overlays)
    # The dispatcher alone is over 100 MB, GitHub's file limit, so git keeps
    # one xz archive. No macOS metadata, so GNU tar unpacks it without
    # warnings.
    shopt -s nullglob
    files=(generated/overlays_static.c generated/overlays_static_[0-9][0-9][0-9][0-9].c)
    [[ -f generated/overlays_static.c ]] || { echo "no generated/overlays_static.c - run ./tm4u.sh overlays first" >&2; exit 1; }
    COPYFILE_DISABLE=1 tar --no-xattrs --no-mac-metadata -cf - "${files[@]}" \
      | xz -9 -T0 > generated/overlays_static.tar.xz
    echo "packed ${#files[@]} files"
    ls -la generated/overlays_static.tar.xz
    ;;
  unpack-overlays)
    a=generated/overlays_static.tar.xz
    [[ -f "$a" ]] || { echo "no $a - run ./tm4u.sh pack-overlays first" >&2; exit 1; }
    xz -t "$a"
    rm -f generated/overlays_static.c generated/overlays_static_[0-9][0-9][0-9][0-9].c
    # -m: fresh mtimes, so Ninja recompiles what the archive brought back
    tar -xmJf "$a"
    ;;
  apply-patches)
    shopt -s nullglob
    for p in patches/psxrecomp/*.patch; do
      if git -C psxrecomp apply --reverse --check "../$p" 2>/dev/null; then
        echo "already applied: $p"
      else
        git -C psxrecomp apply --verbose "../$p"
      fi
    done
    ;;
  generate)
    "$PY" psxrecomp/psxrecomp_cli.py generate --project-root . --config game.toml --disc "$DISC" "$@"
    ;;
  build)
    # A fresh clone (or a checkout of v4.19.3/v4.19.4) has the archive only.
    [[ -f generated/overlays_static.c || ! -f generated/overlays_static.tar.xz ]] || "$ROOT/tm4u.sh" unpack-overlays
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
    [[ -f generated/overlays_static.c || ! -f generated/overlays_static.tar.xz ]] || "$ROOT/tm4u.sh" unpack-overlays
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
    sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
