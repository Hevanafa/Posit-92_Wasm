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
- **particles**
- **print_colour**
- **sound**
- **sprites** -- Sprite loading & various rendering techniques
- **timing** -- Shows the difference between `getTimer` and `getFullTimer`

### Input Handling

- **keyboard** -- Keyboard input (WASD movement)
- **mouse** -- Simple clicker to demonstrate mouse input

### Immediate GUI

- **immediate_gui**
- **nine_slice**
- **prompt_demo**

### Interop

- **bigint** -- Shows how big integers are handled
- **wasm_string** -- Shows how string interop (JS to Pascal) is done

The string interop from Pascal to JS is already demonstrated in `writeLog` mechanism in `LOGGER.PAS` unit

### Progressive Web App (PWA)

- **pwa_demo** -- Shows the most basic setup of an installable Progressive Web App
