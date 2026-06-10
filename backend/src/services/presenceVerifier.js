const DEFAULT_THRESHOLD = parseInt(process.env.RSSI_THRESHOLD || "-75", 10);
const MIN_ANCHORS = parseInt(process.env.MIN_ANCHORS || "1", 10);

// in-memory store: { [studentUid]: { [anchorId]: number[] } }
const store = {};

function mean(arr) {
  if (!arr || arr.length === 0) return -Infinity;
  return arr.reduce((s, v) => s + v, 0) / arr.length;
}

function verifyPresence(studentUid, scanResults) {
  if (!store[studentUid]) store[studentUid] = {};
  const sid = store[studentUid];

  scanResults.forEach(({ anchorId, rssi }) => {
    if (!sid[anchorId]) sid[anchorId] = [];
    sid[anchorId].push(rssi);
    if (sid[anchorId].length > 5) sid[anchorId].shift();
  });

  const anchorMeans = Object.entries(sid).map(([anchorId, vals]) => ({
    anchorId,
    mean: mean(vals),
  }));
  const count = anchorMeans.filter((a) => a.mean >= DEFAULT_THRESHOLD).length;
  return { present: count >= MIN_ANCHORS, anchorMeans };
}

function reset() {
  for (const k of Object.keys(store)) delete store[k];
}

module.exports = { verifyPresence, _store: store, reset };
