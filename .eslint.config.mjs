// eslint.config.js
import pluginPrettier from "eslint-plugin-prettier";
import pluginTs from "@typescript-eslint/eslint-plugin";
import parserTs from "@typescript-eslint/parser";

export default [
    {
        ignores: [
          'node_modules',
          'clf',
          'typechain-types',
          'artifacts',
          'deployments',
          'cache',
        ],
    },
    {
        files: ["**/*.ts"],
        languageOptions: {
            parser: parserTs,
            parserOptions: {
                project: "./tsconfig.json",
            },
        },
        plugins: {
            "@typescript-eslint": pluginTs,
             prettier: pluginPrettier,
        },
        rules: {
            ...pluginTs.configs.recommended.rules,
        },
    },
];
