import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./playwright-tests/collection",
  workers: 1,
  retries: 0,
  timeout: 90000,
  use: {
    baseURL: process.env.COLLECTION_TEST_UI_URL || "http://127.0.0.1:19000",
    launchOptions: process.env.PLAYWRIGHT_CHROME_EXECUTABLE
      ? {
          executablePath: process.env.PLAYWRIGHT_CHROME_EXECUTABLE,
          args: ["--no-sandbox"],
        }
      : undefined,
    viewport: { width: 1440, height: 1000 },
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
  },
  reporter: [["list"]],
});
