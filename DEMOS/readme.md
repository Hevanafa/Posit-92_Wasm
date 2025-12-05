# Demo Projects

Here, you can find how to make use of most of the features in this framework

Mostly the changes are in `game.pas`

If there are assets involved, you can take a look into both `assets.pas` and `loadAssets` method in the glue code

##

### Basics

- **hello_world** -- Contains most of the basic stuff covered: BMFont text, sprites, cursor rendering
- **fullscreen**
- **image_ptr** -- Shows sprite loading with TImageRef instead of TBitmap
- **lerp** -- Shows how to implement easing
- **loading** -- Loading screen with simulated delays
- **music** -- Shows a music player that can handle repeat song
  - **Sounds** mixin is used here
- **particles**
- **print_colour**
- **sound**
  - **Sounds** mixin is used here
- **sprites** -- Sprite loading & various rendering techniques
- **timing** -- Shows the difference between `getTimer` and `getFullTimer`
- **webgl_demo** -- Shows how to setup WebGL with Posit-92
  - **WebGLMixin** mixin is used here

### Input Handling

- **keyboard** -- Keyboard input (WASD movement)
- **mouse** -- Simple clicker to demonstrate mouse input

### Immediate GUI

- **immediate_gui**
- **nine_slice**
- **prompt_demo**

### Interop

- **bigint** -- Shows how big integers are handled
  - **BigIntMixin** mixin is used here
- **wasm_string** -- Shows how string interop (JS to Pascal) is done

The string interop from Pascal to JS is already demonstrated in `writeLog` mechanism in `LOGGER.PAS` unit

### Post-Processing

- **spr_post_processing**
- **scanlines**
- **vga_tint**

### Progressive Web App (PWA)

- **pwa_demo** -- Shows the most basic setup of an installable Progressive Web App
