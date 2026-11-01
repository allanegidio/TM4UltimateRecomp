/*
 * TM4 Ultimate Edition: widescreen that fills the screen.
 *
 * On PSX the runtime clamps settings.toml aspect_ratio to 4:3 ("widescreen is
 * mod-owned"), so a game-owned plugin has to request the wider view. This one
 * opens at 16:10 (Steam Deck) and then follows the window, so a 16:9 TV also
 * fills. game.toml [widescreen] keeps the HUD and menus at their proportions.
 */
#include "mod_plugins.h"

static void tm4u_widescreen_activate(void) {
    (void)psx_mod_set_fixed_display_aspect(16, 10);
    (void)psx_mod_set_adaptive_display_aspect(0, 0);
}

PSX_MOD_CONSTRUCTOR(tm4u_register_widescreen_plugin) {
    (void)psx_mod_register_activation_plugin("tm4u.widescreen",
                                             tm4u_widescreen_activate);
}
