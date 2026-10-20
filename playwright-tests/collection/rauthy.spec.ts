import { test, expect, type Page } from "@playwright/test";
import fs from "node:fs";

type Identity = {
  email: string;
  password: string;
  role_id: string;
  merchant_id?: string;
};
type Fixtures = {
  auth_id: string;
  api_url: string;
  users: Identity[];
  unbound: Identity;
};
const path = process.env.RAUTHY_TEST_FIXTURES;
const fixtures: Fixtures | undefined = path
  ? JSON.parse(fs.readFileSync(path, "utf8"))
  : undefined;

test.describe("Rauthy OIDC", () => {
  test.skip(
    !fixtures,
    "Set RAUTHY_TEST_FIXTURES for the dedicated remote Rauthy instance",
  );
  test.setTimeout(120000);

  async function authenticate(page: Page, user: Identity, baseURL: string) {
    await page.goto(
      `${baseURL}/?auth_id=${encodeURIComponent(fixtures!.auth_id)}`,
    );
    await page
      .getByRole("button", { name: "Continue with Rauthy", exact: true })
      .click();
    await page.waitForURL(/localhost:18090\/auth\/v1\/oidc\/authorize/);
    const authorization = new URL(page.url());
    expect(authorization.searchParams.get("code_challenge_method")).toBe(
      "S256",
    );
    expect(authorization.searchParams.get("nonce")).toBeTruthy();
    await page.waitForLoadState("networkidle");
    await page.locator('input[type="email"]').fill(user.email);
    await page.locator('input[type="email"]').press("Tab");
    await page
      .locator("button:visible")
      .filter({ hasText: /^Login$/ })
      .first()
      .click();
    await page.locator('input[type="password"]:visible').fill(user.password);
    await page.locator('input[type="password"]:visible').press("Tab");
    const response = page.waitForResponse((r) =>
      new URL(r.url()).pathname.endsWith("/user/oidc"),
    );
    await page
      .locator("button:visible")
      .filter({ hasText: /^Login$/ })
      .first()
      .click();
    return response;
  }

  for (const index of [0, 1, 2]) {
    test(`bound identity ${index} receives only its local dashboard role`, async ({
      page,
      baseURL,
      request,
    }) => {
      const user = fixtures!.users[index];
      let callback: { code: string | null; state: string | null } | undefined;
      page.on("request", (r) => {
        const url = new URL(r.url());
        if (url.pathname === "/redirect/oidc/rauthy")
          callback = {
            code: url.searchParams.get("code"),
            state: url.searchParams.get("state"),
          };
      });
      // An otherwise valid callback cannot be used from another browser.
      await page.route("**/redirect/oidc/rauthy?**", async (route) => {
        const url = new URL(route.request().url());
        const foreign = await request.post(`${fixtures!.api_url}/user/oidc`, {
          data: {
            code: url.searchParams.get("code"),
            state: url.searchParams.get("state"),
          },
        });
        expect(foreign.status()).toBe(400);
        expect((await foreign.json()).token).toBeUndefined();
        await route.continue();
      });
      const response = await authenticate(page, user, baseURL!);
      expect(response.status()).toBe(200);
      const tokenResponse = await response.json();
      expect(tokenResponse.token_type).toBe("user_info");
      const info = await request.get(`${fixtures!.api_url}/user`, {
        headers: { Authorization: `Bearer ${tokenResponse.token}` },
      });
      expect(info.status()).toBe(200);
      expect((await info.json()).role_id).toBe(user.role_id);
      await expect(page).toHaveURL(/\/(?:v2\/)?home\/?$/);
      if (user.merchant_id) {
        await expect(page.getByTestId("collection-home")).toBeVisible({
          timeout: 60000,
        });
        await expect(page.getByTestId("dashboard-identity")).toContainText(
          user.merchant_id,
        );
        const home = new URL(page.url());
        home.pathname = home.pathname.replace(
          /\/(?:v2\/)?home\/?$/,
          "/platform",
        );
        await page.goto(home.href);
        await expect(
          page.getByText(
            "This page is managed by your platform administrator.",
          ),
        ).toBeVisible();
        const other =
          user.merchant_id === "collection_a" ? "collection_b" : "collection_a";
        const cross = await request.get(
          `${fixtures!.api_url}/accounts/${other}`,
          { headers: { Authorization: `Bearer ${tokenResponse.token}` } },
        );
        expect(cross.status()).toBeGreaterThanOrEqual(400);
        expect(cross.status()).toBeLessThan(500);
      } else {
        await expect(page.getByTestId("dashboard-identity")).toContainText(
          "Platform administration",
          { timeout: 60000 },
        );
      }
      // A successful callback consumes its nonce: the same code/state cannot sign in again.
      expect(callback).toBeTruthy();
      const replay = await page.request.post(`${fixtures!.api_url}/user/oidc`, {
        data: callback,
      });
      expect(replay.status()).toBe(400);
    });
  }

  test("same-email local account without an explicit subject binding is rejected", async ({
    page,
    baseURL,
  }) => {
    const response = await authenticate(page, fixtures!.unbound, baseURL!);
    expect(response.status()).toBe(400);
    const body = await response.json();
    expect(body.token).toBeUndefined();
    await expect(page.getByTestId("dashboard-identity")).toHaveCount(0);
  });

  test("unknown state cannot create a dashboard session", async ({
    request,
  }) => {
    const response = await request.post(`${fixtures!.api_url}/user/oidc`, {
      data: {
        state: "not-a-real-authorization-state",
        code: "not-a-real-code",
      },
    });
    expect(response.status()).toBe(400);
    expect((await response.json()).token).toBeUndefined();
  });
});
