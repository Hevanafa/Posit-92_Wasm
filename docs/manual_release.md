# Manual release checklist

This document describes how to manually get a Posit-92 WASM game working as a proper release

This document is intended as a guideline rather than a rigid set of rules that you must follow

## Packaging

- Make a folder named `dist`
  - or clean it first
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

### Test `dist`

- Start a PowerShell window in `dist`
- Run `npx http-server -c-1 .`
  - or any HTTP serve that you prefer
- Open the localhost URL in the browser
