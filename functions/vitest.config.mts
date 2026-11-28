import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    globals: false,
    fileParallelism: false,
    testTimeout: 30000,
    hookTimeout: 30000,
    server: {
      deps: {
        inline: [/^@firebase\//, /^firebase(\/|$)/],
      },
    },
  },
});
