const ipRangeCheck = require("ip-range-check");

const campusRange = process.env.CAMPUS_IP_RANGE;

function ipGeoFence(req, res, next) {
  // If campus range not configured (e.g. in tests/local), skip the check
  if (!campusRange) return next();
  const ip = req.ip || req.connection.remoteAddress;
  if (!ipRangeCheck(ip, campusRange)) {
    return res
      .status(403)
      .json({ error: "Access denied: outside campus network" });
  }
  return next();
}

module.exports = ipGeoFence;
