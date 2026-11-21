import assert from "node:assert/strict";
import test from "node:test";

const { joinQrSize } = await import("../js/join_qr_size.mjs");

test("a laptop screen is limited by its height", () => {
  assert.equal(joinQrSize(1366, 768), 307);
  assert.equal(joinQrSize(1280, 720), 288);
});

test("a wide full HD screen keeps the QR code within 40% of the height", () => {
  assert.equal(joinQrSize(1920, 1080), 432);
});

test("a portrait screen is limited by its width", () => {
  assert.equal(joinQrSize(768, 1024), 192);
});

test("the QR code never gets too small to scan", () => {
  assert.equal(joinQrSize(320, 240), 120);
});
