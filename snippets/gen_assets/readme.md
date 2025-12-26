# Asset Generator

Generates Pascal boilerplate from `assets.json`

What it does:

1. Reads `assets.json`
2. Generates `AddAssets.pas` - copy interface / implementation to `assets.pas`
3. Generates `add_assets.js` - copy to your `#AssetManifest`

## Example

Input: `"slime_girl": "assets/images/slime_girl.png"`

Output:

- `imgSlimeGirl` variable
- `setImgSlimeGirl` procedure
