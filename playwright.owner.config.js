import { defineConfig } from '@playwright/test'

// Isolated UI fixtures use simulated owner sessions and intercepted APIs.
// They never authenticate to, or mutate, the production backend.
export default defineConfig({
  testDir: './tests/owner-e2e',
  timeout: 20000,
  workers: 1,
  use: {
    baseURL: 'http://127.0.0.1:5175', trace: 'retain-on-failure',
    launchOptions: process.env.OWNER_TEST_CHROMIUM_PATH
      ? { executablePath: process.env.OWNER_TEST_CHROMIUM_PATH } : {},
  },
  webServer: {
    command: 'npm run dev -- --host 127.0.0.1 --port 5175 --strictPort',
    url: 'http://127.0.0.1:5175/tests/fixtures/owner.html',
    reuseExistingServer: !process.env.CI,
  },
})
