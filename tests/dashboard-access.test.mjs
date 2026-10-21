import assert from "node:assert/strict";
import test from "node:test";
import {
  canVisit,
  isCollectionRole,
  isPlatformRole,
} from "../src/entryPoints/DashboardAccess.res.js";

const path = (value) =>
  value
    .split("/")
    .filter(Boolean)
    .reduceRight((tl, hd) => ({ hd, tl }), 0);

for (const role of [
  "collection_merchant_admin",
  "collection_merchant_view_only",
]) {
  test(`${role}: collection pages remain accessible`, () => {
    for (const url of [
      "/home",
      "/v2/home",
      "/payments",
      "/payments/payment_a",
      "/refunds",
      "/customers/customer_a",
      "/developer-api-keys",
      "/webhooks",
      "/users",
      "/analytics-payments",
    ]) {
      assert.equal(canVisit(role, path(url)), true, url);
    }
  });
  test(`${role}: direct management paths are denied`, () => {
    for (const url of [
      "/platform",
      "/platform/channel-limits",
      "/connectors",
      "/connectors/new",
      "/routing",
      "/routing-workspace",
      "/payouts",
      "/organization-chart",
      "/organization-settings",
      "/payment-settings",
      "/configure-pmts",
      "/superposition",
      "/future-admin-page",
    ]) {
      assert.equal(canVisit(role, path(url)), false, url);
    }
  });
}

test("platform entry is restricted to platform administrators", () => {
  assert.equal(isPlatformRole("tenant_admin"), true);
  assert.equal(canVisit("tenant_admin", path("/platform")), true);
  assert.equal(canVisit("tenant_admin", path("/connectors")), true);
  assert.equal(canVisit("merchant_admin", path("/platform")), false);
  assert.equal(isCollectionRole("merchant_admin"), false);
  assert.equal(canVisit("merchant_admin", path("/connectors")), true);
});
