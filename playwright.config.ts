import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  timeout: 90_000,
  expect: {
    timeout: 15_000,
  },
  reporter: [
    ['list'],
    ['json', { outputFile: 'tests/report.json' }],
  ],
  use: {
    baseURL: 'http://127.0.0.1:3749',
    trace: 'on-first-retry',
  },
  webServer: {
    command:
      'npx http-server apps/client/build/web -a 127.0.0.1 -p 3749 --silent',
    url: 'http://127.0.0.1:3749',
    reuseExistingServer: false,
    timeout: 120_000,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
