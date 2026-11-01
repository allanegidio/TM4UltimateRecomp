# TM4 Ultimate Edition Recompiled (unofficial)

An unofficial build of [TwistedMetal4Recomp](https://github.com/TechnicallyComputers/TwistedMetal4Recomp)
for **inSAMity's TM4 Ultimate Edition mod** (v4.19). It runs the mod as a native
recompiled game, for example on the Steam Deck, instead of only in DuckStation.

- The mod is by [inSAMity](https://www.youtube.com/@inSAMity). All mod content and credit are theirs.
- The recompilation is TechnicallyComputers' TwistedMetal4Recomp v0.3.37, built on psxrecomp `2a4824f`.

**You need the mod's own disc image**, `TM4_TM3_v4_19` as BIN/CUE (33 tracks). It is
not included here. On first launch, pick `TM4_TM3_v4_19.cue`. The stock TM4 disc does
not work with this build. Use the stock TwistedMetal4Recomp for that.

Changes from upstream:

- `game.toml` identity, `text_size` and `seeds/` come from the mod's disc. The mod
  enlarges the boot EXE from `0x49800` to `0x61800`.
- `generated/` was regenerated from the mod's `SCUS_945.60`.
- 8 MB main RAM is on by default (`mods/preloaded`). The mod shows a black screen without it.
- `[timing] guest_cycle_scale = 3` is the DuckStation-style overclock the mod's 45/60 FPS
  modes need. Set `PSX_GUEST_CYCLE_SCALE=<n>` to try other values.
- Netplay is off, so this build never joins the public TwistedMetal4Recomp lobby.
- Release CI builds Linux x64 only.

Install it in its own folder, never over the stock TwistedMetal4Recomp, because the files
have the same names. To rebuild from your own copy of the mod's disc, see `tm4u.sh`.

---

# TwistedMetal4 Recompiled

<!-- retcomm-readme-metrics -->
[![GitHub downloads (all assets, all releases)](https://img.shields.io/github/downloads/TechnicallyComputers/TwistedMetal4Recomp/total)](https://github.com/TechnicallyComputers/TwistedMetal4Recomp/releases)
[![GitHub downloads (latest release)](https://img.shields.io/github/downloads/TechnicallyComputers/TwistedMetal4Recomp/latest/total)](https://github.com/TechnicallyComputers/TwistedMetal4Recomp/releases/latest)
[![GitHub release](https://img.shields.io/github/v/release/TechnicallyComputers/TwistedMetal4Recomp)](https://github.com/TechnicallyComputers/TwistedMetal4Recomp/releases/latest)
<!-- /retcomm-readme-metrics -->

<!-- retcomm-readme-boxart -->
<p align="center">
  <img src="launcher_assets/img/boxart.png" alt="TwistedMetal4 box art" width="280">
</p>
<!-- /retcomm-readme-boxart -->

Static recompilation of **TwistedMetal4** built on
[psxrecomp](https://github.com/mstan/psxrecomp) and
[recomp-ui](https://github.com/mstan/recomp-ui).

Twisted Metal 4 is the fourth installment in the Twisted Metal series and the second and last installment to be developed by 989 Studios. The game's plot centers on Sweet Tooth, the long-time mascot of the titular Twisted Metal competition, overthrowing Calypso, the mysterious organizer of the competition, in a coup d'état. He then takes over the mantle of granting the winner of the competition a single wish, regardless of price, size or even reality.

| | |
|---|---|
| Players | 4 |
| Region | USA |
| Publisher | 989 Studios |
| Year | 1999 |

Scaffolded with the New Project Layout. See
`psxrecomp/docs/GAME_PROJECT_SETUP.md` for the full flow.

<!-- retcomm-readme-launcher -->
## Retro Launcher

You can run this title **standalone** (release zip + the built-in recomp-ui
Generate & Build flow), or manage installs, updates, ROM/BIOS wiring, and queued
builds more intuitively with
**[Retro Launcher](https://github.com/RetroPortingToolKit/Retro-Launcher)** —
the Retro Compilation Manager hub for self-compiling recomps.

[Downloads](https://github.com/RetroPortingToolKit/Retro-Launcher/releases) ·
[Full README & features](https://github.com/RetroPortingToolKit/Retro-Launcher#readme)

<p align="center">
  <img src="https://raw.githubusercontent.com/RetroPortingToolKit/Retro-Launcher/main/docs/screenshots/hub-and-game-launcher.png" alt="Retro hub with a background build, next to a title’s recomp-ui launcher" width="720">
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/RetroPortingToolKit/Retro-Launcher/main/docs/screenshots/queue-and-background-build.png" alt="Background cmake build with titles queued" width="720">
</p>

Retro checks for updates, rebuilds with existing build data when possible,
shares the portable toolchain used by per-title launchers, and automates
BIOS/ROM/save plumbing so you are not stuck repeating each game’s wizard by hand.
<!-- /retcomm-readme-launcher -->

## Legal

You must own the original game. Disc images under `disc/` are gitignored and
must never be committed. Retail BIOS dumps are not redistributed; OpenBIOS is
used for Generate unless you supply your own SCPH locally.

Optional box art under `launcher_assets/img/` may come from
[libretro-thumbnails](https://github.com/libretro-thumbnails/libretro-thumbnails)
(`Named_Boxarts`); see `BOXART_SOURCE.txt` when present.

## Quick start (dev)

```bash
git submodule update --init --recursive
./psxrecomp/tools/ci/build_emitters.sh
python3 psxrecomp/psxrecomp_cli.py generate \
  --config game.toml --project-root . --disc disc/<your>.cue
cmake -S . -B build-release -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build-release --target psx-runtime
```

Zip prefix for CI artifacts: `twistedmetal4`.

## Symbols

Progressive map: `symbols.toml` → `python3 tools/sync_symbols.py` →
`psx_symbols.h` (`PSX_FN_*`). See `psxrecomp/docs/SYMBOLS.md`.

## Framework pins

Submodule gitlinks (`psxrecomp`, optional `recomp-ui`, nested `recomp-net`)
are authoritative. `framework_pins.txt` is an optional scaffold snapshot;
release CI logs SHAs with `record_pins.sh` but builds whatever the gitlinks
resolve to. Bump submodules deliberately — do not float on `main`/`master`
in release CI.

<!-- retcomm-readme-raid -->
---

<p align="center">
  <sub><b>R.A.I.D. — Retro AI Development</b> · a Discord for AI-assisted retro reverse-engineering, decomp &amp; recomp</sub>
</p>

<p align="center">
  <a href="https://discord.gg/Ad9BwSzctP"><img src=".github/raid-discord.png" alt="Join the Retro AI Development (R.A.I.D.) Discord" width="200"></a>
</p>
<!-- /retcomm-readme-raid -->
