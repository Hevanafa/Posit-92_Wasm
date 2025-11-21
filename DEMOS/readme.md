# Demo Projects

Here, you can find how to make use of most of the features in this framework

Mostly the changes are in `game.pas`

If there are assets involved, you can take a look into both `assets.pas` and `loadAssets` method in the glue code

**Basic Rendering**

- **hello_world** -- Contains most of the basic stuff covered: BMFont text, sprites, cursor rendering

**Input Handling**

- **keyboard** -- Keyboard input (WASD movement)
- **mouse** -- Simple clicker to demonstrate mouse input

**Interop**
- **bigint** -- Shows how big integers are handled
- **wasm_string** -- Shows how string interop (JS to Pascal) is done

The string interop from Pascal to JS is already demonstrated in `writeLog` mechanism in `LOGGER.PAS` unit
