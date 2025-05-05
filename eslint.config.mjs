import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import globals from 'globals';
import prettierPlugin from 'eslint-plugin-prettier';
import prettierConfig from './prettier.config.js';

export default tseslint.config(
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
    eslint.configs.recommended,
    ...tseslint.configs.recommendedTypeChecked,
    {
      plugins: {
        prettier: prettierPlugin
      },
      rules: {
        'prettier/prettier': ['error', prettierConfig]
      }
    },
    {
      languageOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
        globals: {
          ...globals.node,
          ...globals.browser,
        },
        parserOptions: {
          projectService: true,
        },
      },
      rules: {
        '@typescript-eslint/ban-ts-comment': 'off',
        '@typescript-eslint/require-await': 'off',
        '@typescript-eslint/no-explicit-any': 'off',
        '@typescript-eslint/no-floating-promises': 'off',
        '@typescript-eslint/no-misused-promises': 'off',
        '@typescript-eslint/no-unsafe-assignment': 'off',
        '@typescript-eslint/no-unsafe-member-access': 'off',
        '@typescript-eslint/no-unsafe-call': 'off',
        '@typescript-eslint/no-unsafe-return': 'off',
        '@typescript-eslint/no-unsafe-argument': 'off',
        '@typescript-eslint/no-unused-vars': [
          'warn',
          {
            argsIgnorePattern: '^_',
            varsIgnorePattern: '^_',
          },
        ],
        '@typescript-eslint/naming-convention': [
          'error',
          {
            selector: ['parameter', 'variable'],
            leadingUnderscore: 'forbid',
            filter: { regex: '_*', match: false },
            format: null,
          },
          {
            selector: 'parameter',
            leadingUnderscore: 'require',
            format: null,
            modifiers: ['unused'],
          },
        ],
      },
    },
    {
      ignores: ['eslint.config.mjs', 'prettier.config.js'],
    },
)
