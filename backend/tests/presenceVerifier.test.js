const {
  verifyPresence,
  _store,
  reset,
} = require("../src/services/presenceVerifier");

beforeEach(() => reset());

test("student with 2 anchors above threshold returns present true", () => {
  process.env.RSSI_THRESHOLD = "-75";
  process.env.MIN_ANCHORS = "2";
  const uid = "student1";
  // two anchors strong
  const res1 = verifyPresence(uid, [
    { anchorId: "front", rssi: -60 },
    { anchorId: "mid", rssi: -65 },
  ]);
  expect(res1.present).toBe(true);
});

test("student with only 1 anchor above threshold returns present false", () => {
  process.env.RSSI_THRESHOLD = "-75";
  process.env.MIN_ANCHORS = "2";
  const uid = "student2";
  const res = verifyPresence(uid, [
    { anchorId: "front", rssi: -60 },
    { anchorId: "mid", rssi: -90 },
  ]);
  expect(res.present).toBe(false);
});

test("rolling average smooths a single bad RSSI reading", () => {
  const uid = "student3";
  // five good readings then one bad
  for (let i = 0; i < 5; i++)
    verifyPresence(uid, [{ anchorId: "front", rssi: -60 }]);
  const res = verifyPresence(uid, [{ anchorId: "front", rssi: -120 }]);
  // mean should still be above threshold (-75)
  expect(
    res.anchorMeans.find((a) => a.anchorId === "front").mean,
  ).toBeGreaterThan(-75);
});

test("windows are trimmed to 5 readings", () => {
  const uid = "student4";
  for (let i = 0; i < 7; i++)
    verifyPresence(uid, [{ anchorId: "front", rssi: -60 + i }]);
  const arr = _store[uid]["front"];
  expect(arr.length).toBeLessThanOrEqual(5);
});
