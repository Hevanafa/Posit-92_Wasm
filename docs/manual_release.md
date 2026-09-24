# Manual release checklist

## Project Structure

(TBA)

## Packaging

- Make a folder named `dist`
- Build the WASM binary (`Ctrl+F9` in Lazarus)
  - Enable `{$DEFINE Release}` if applicable
- Copy these to `dist`:
  - `assets` dir
  - `game.wasm`
  - HTML entry point:
    - index.html
    - game.js
    - favicon.ico
    - posit-92.js
    - posit-92.css
  - Mixin files: `.mixin.js`

**Test `dist`**

(TBA)
