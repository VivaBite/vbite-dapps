import path from "node:path";
import baseConfig from "@vivabite/eslint-config";

export default [
  {
    ignores: ["node_modules", "dist", "*.js", "*.mjs"],
  },
  {
    languageOptions: {
      parserOptions: {
        project: path.resolve("./tsconfig.json"),
        tsconfigRootDir: path.resolve(),
      },
    },
  },
  ...baseConfig,
];
