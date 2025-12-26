# Asset Generator

Generates Pascal boilerplate from `assets.json`

What it does:

1. Reads `assets.json`
2. Generates `AddAssets.pas` - copy interface / implementation to `assets.pas`
3. Generates `add_assets.js` - copy to your `#AssetManifest`

## Usage

This script requires `assets.json` to be in the same folder as the current working directory

```powershell
bun .\generate_assets.ts
```

## Example

Input: `"slime_girl": "assets/images/slime_girl.png"`

Output:

- `imgSlimeGirl` variable
- `setImgSlimeGirl` procedure
