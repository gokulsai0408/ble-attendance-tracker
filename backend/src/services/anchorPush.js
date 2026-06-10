const axios = require("axios");

const ANCHOR_IPS = (process.env.ANCHOR_IPS || "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

async function pushSequence(uuids) {
  const promises = ANCHOR_IPS.map(async (ip) => {
    const url = `http://${ip}/config`;
    try {
      const resp = await axios.post(url, { uuids }, { timeout: 5000 });
      return { ip, ok: true, data: resp.data };
    } catch (err) {
      return { ip, ok: false, error: err.message };
    }
  });
  return Promise.all(promises);
}

async function advanceIndex(seq) {
  const promises = ANCHOR_IPS.map(async (ip) => {
    const url = `http://${ip}/advance`;
    try {
      const resp = await axios.post(url, { seq }, { timeout: 3000 });
      return { ip, ok: true, data: resp.data };
    } catch (err) {
      return { ip, ok: false, error: err.message };
    }
  });
  return Promise.all(promises);
}

module.exports = { pushSequence, advanceIndex };
