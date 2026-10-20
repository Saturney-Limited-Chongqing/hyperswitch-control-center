import { test, expect } from "@playwright/test";
import fs from "node:fs";

type Merchant = {
  merchant_id: string;
  profile_id: string;
  token: string;
  platform_token: string;
};
const fixturePath = process.env.COLLECTION_TEST_FIXTURES;
if (!fixturePath)
  throw new Error(
    "Set COLLECTION_TEST_FIXTURES to provisioned local test fixtures",
  );
const fixtures: { merchants: Merchant[] } = JSON.parse(
  fs.readFileSync(fixturePath, "utf8"),
);

function managementPath(currentURL: string, destination: string) {
  const current = new URL(currentURL);
  current.pathname = current.pathname.replace(
    /\/(?:v2\/)?home\/?$/,
    destination,
  );
  if (current.pathname === new URL(currentURL).pathname) {
    throw new Error(`Expected a home URL, received ${current.pathname}`);
  }
  return current.href;
}

test("two merchants receive distinct collection dashboards and cannot open administration", async ({
  browser,
  baseURL,
}) => {
  for (const [index, merchant] of fixtures.merchants.entries()) {
    const other = fixtures.merchants[index === 0 ? 1 : 0];
    const context = await browser.newContext();
    await context.addInitScript((token) => {
      if (!localStorage.getItem("USER_INFO")) {
        localStorage.setItem("USER_INFO", JSON.stringify({ token }));
      }
    }, merchant.token);
    const page = await context.newPage();
    await page.goto(baseURL!);
    await expect(page.getByTestId("collection-home")).toBeVisible({
      timeout: 60000,
    });
    await expect(page.getByTestId("dashboard-identity")).toContainText(
      "Merchant dashboard",
    );
    await expect(page.getByTestId("dashboard-identity")).toContainText(
      merchant.merchant_id,
    );
    await expect(page.getByTestId("dashboard-identity")).not.toContainText(
      other.merchant_id,
    );
    await expect(
      page.getByText("Merchant management", { exact: true }),
    ).toHaveCount(0);
    await expect(page.getByText("Workflow", { exact: true })).toHaveCount(0);
    await page.screenshot({
      path: test.info().outputPath(`${merchant.merchant_id}-home.png`),
    });
    const home = page.url();
    await page.goto(managementPath(home, "/customers"));
    const ownLabel = index === 0 ? "A" : "B";
    const otherLabel = index === 0 ? "B" : "A";
    await expect(
      page
        .getByText(`Merchant ${ownLabel} private customer`, { exact: true })
        .first(),
    ).toBeVisible({ timeout: 60000 });
    await expect(
      page.getByText(`Merchant ${otherLabel} private customer`, {
        exact: true,
      }),
    ).toHaveCount(0);

    for (const route of ["/connectors", "/routing", "/platform"]) {
      await page.goto(managementPath(home, route));
      await expect(
        page.getByText("This page is managed by your platform administrator."),
      ).toBeVisible({ timeout: 60000 });
    }
    await context.close();
  }
});

test("platform administrator can see both merchants and open the management hub", async ({
  browser,
  baseURL,
}) => {
  const context = await browser.newContext();
  await context.addInitScript((token) => {
    if (!localStorage.getItem("USER_INFO")) {
      localStorage.setItem("USER_INFO", JSON.stringify({ token }));
    }
  }, fixtures.merchants[0].platform_token);
  const page = await context.newPage();
  await page.goto(baseURL!);
  await expect(page.getByTestId("dashboard-identity")).toContainText(
    "Platform administration",
    { timeout: 60000 },
  );
  await page.getByText("Merchant management", { exact: true }).click();
  const hub = page.getByTestId("platform-management");
  await expect(hub).toBeVisible();
  for (const merchant of fixtures.merchants) {
    await expect(
      hub.getByText(merchant.merchant_id, { exact: true }),
    ).toBeVisible();
  }
  const secondMerchant = fixtures.merchants[1];
  const row = hub
    .getByText(secondMerchant.merchant_id, { exact: true })
    .locator("../..");
  await row
    .getByRole("button", { name: "Manage merchant", exact: true })
    .click();
  await expect(page.getByTestId("dashboard-identity")).toContainText(
    secondMerchant.merchant_id,
  );
  await page.goto(managementPath(page.url(), "/connectors"));
  await expect(
    page.getByText("isolation_stripe_b", { exact: true }),
  ).toBeVisible({ timeout: 60000 });
  await expect(
    page.getByText("isolation_stripe_a", { exact: true }),
  ).toHaveCount(0);
  await page.screenshot({
    path: test.info().outputPath("platform-channels.png"),
  });
  await context.close();
});
