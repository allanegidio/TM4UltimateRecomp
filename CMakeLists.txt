cmake_minimum_required(VERSION 3.20)
project(TwistedMetal4Recomp LANGUAGES C CXX)

set(PSXRECOMP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/psxrecomp" CACHE PATH
    "Path to psxrecomp")

# --- Opt-in product surfaces (OFF by default in the framework) -------------
# Scaffold prompts / flags fill these. Without recomp-ui, PSX_RECOMP_UI is OFF.
# Setup-host CI requires WIZARD_CMAKE_BLOCK / ENABLE_SETUP_WIZARD (FORCE_SETUP_HOST
# alone does not open first-run / Generate & rebuild).
# recomp-ui submodule present (PSX_RECOMP_UI defaults ON).
# Netplay stays off: this is a private modded build, so it must not join the
# public TwistedMetal4Recomp lobby.
set(PSX_SETUP_WIZARD ON CACHE BOOL
    "Advertise first-run setup wizard + Generate & rebuild in recomp-ui" FORCE)
include("${PSXRECOMP_ROOT}/runtime/runtime.cmake")

psxrecomp_add_game_runtime(psx-runtime
    ENABLE_SETUP_WIZARD
    # Kept as upstream: the exe name (TwistedMetal4_Recompiled) is derived from
    # it and the packaging scripts expect that name. game.toml sets the title.
    WINDOW_TITLE "TwistedMetal4 Recompiled"
    DEFAULT_GAME_CONFIG_PATH "game.toml"
    MAX_PLAYERS 4
    LAUNCHER_BOXART "${CMAKE_CURRENT_SOURCE_DIR}/launcher_assets/img/boxart.tga"
    APP_ICON "${CMAKE_CURRENT_SOURCE_DIR}/assets/psxrecomp.ico"
    GEN_MARKER "generated/SCUS_945.60_dispatch.c"
    GEN_FULL_GLOB "generated/SCUS_945.60_full_*.c"
    CODEGEN_SETUP_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/codegen_setup.c"
    # Overrides the builtin psx.enhancement.8mb-ram so it is on by default:
    # the inSAMity mod shows a black screen without 8 MB of main RAM.
    PRELOADED_MODS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/mods/preloaded"
)

# >>> psxrecomp:recomp-net-headers (managed by tools/update_cmake.{sh,ps1})
# runtime/src/main.cpp includes recomp_net/host_relay.h unconditionally (a
# plain-C types header). With PSX_NETPLAY off nothing adds recomp-net's include
# dir, so expose it whenever the submodule is checked out.
if(EXISTS "${PSXRECOMP_ROOT}/lib/recomp-net/include/recomp_net/host_relay.h")
    target_include_directories(psx-runtime PRIVATE
        "${PSXRECOMP_ROOT}/lib/recomp-net/include")
endif()
# <<< psxrecomp:recomp-net-headers

# Stage runtime configs next to the exe for direct build/ launches. Only copy
# files that exist — never fail POST_BUILD when game_options.toml is absent.
foreach(_PSX_RUNTIME_CONFIG game.toml game_options.toml)
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${_PSX_RUNTIME_CONFIG}")
        add_custom_command(TARGET psx-runtime POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CMAKE_CURRENT_SOURCE_DIR}/${_PSX_RUNTIME_CONFIG}"
                "$<TARGET_FILE_DIR:psx-runtime>/${_PSX_RUNTIME_CONFIG}"
            COMMENT "Staging ${_PSX_RUNTIME_CONFIG}"
            VERBATIM)
    endif()
endforeach()

