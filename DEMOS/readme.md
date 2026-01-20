# Demo Projects

Here, you can find how to make use of most of the features in this game engine

Mostly the changes are in `game.pas`

If there are assets involved, you can take a look into both `assets.pas` and `loadAssets` method in the glue code

##

### Boilerplates

- **hello_intro** -- The full boilerplate including the intro sequence and 2 other game states: loading & playing
- **hello_quick** -- Similar to `hello_intro` but without the intro sequence
- **hello_simple** -- Minimal boilerplate without the opinionated game states
- **hello_minimal** -- The bare minimum example without the asset loader and the rest of the boilerplate features


### Basics

- **bigint_demo** -- Shows how big integers are handled via browser API
  - **BigIntMixin** mixin is used here
- **chain_easing** -- Demonstrates how to chain easings
- **collision** -- Demonstrates how to implement simple arcade collisions: rectangle and circle
- **easings** -- Shows how to implement easing
- **fullscreen** -- Shows how to approach the fullscreen feature
- **gamepad_demo**
- **graphics_demo**
- **micro_tlist** -- Demonstrates how to use the built-in `TList` (without the RTL bloat)
- **music** -- Shows a music player that can handle repeat song
  - **Sounds** mixin is used here
- **particles**
- **print_colour**
- **rainbow_screen** -- Demonstrates how to use the `Colour` unit
- **square_screen** -- Demonstrates how to use a custom screen size
- **sound**
  - **Sounds** mixin is used here
- **sprites** -- Sprite loading & various rendering techniques
- **timing** -- Shows the difference between `getTimer` and `getFullTimer`
- **webgl_demo** -- Shows how to setup WebGL with Posit-92
  - **WebGLMixin** mixin is used here

### Advanced

- chase_game
- dos_display

### Immediate GUI

- **immediate_gui**
- **immedgui_nine_slice**
- **immedgui_prompt**

The string interop from Pascal to JS is already demonstrated in `writeLog` mechanism in `LOGGER.PAS` unit

### Sprite Effects

### Screen Effects

- **vga_crt_effect**

### Progressive Web App (PWA)

- **pwa_demo** -- Shows the most basic setup of an installable Progressive Web App
