import globals from "globals";
import tseslint from "typescript-eslint";
import { defineConfig } from "eslint/config";

export default defineConfig([
  { files: ["**/*.js"], languageOptions: { sourceType: "script" } },
  {
    files: ["**/*.{js,mjs,cjs,ts,mts,cts}"],
    languageOptions: { globals: globals.node },

    rules: {
      "consistent-return": "error",

      "semi": ["warn", "always"],
      "semi-style": ["error", "last"],

      "@typescript-eslint/explicit-function-return-type": "error",

      "@typescript-eslint/no-unused-vars": "off"
    }
  },

  tseslint.configs.recommended,
]);
