const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/verifyToken");
const ipGeoFence = require("../middleware/ipGeoFence");
const requireRole = require("../middleware/requireRole");
const ctrl = require("../controllers/attendanceController");

router.use(express.json());

// All attendance routes are protected and geo-fenced
router.post(
  "/report",
  verifyToken,
  ipGeoFence,
  requireRole("student"),
  ctrl.report,
);
router.post("/checkin", verifyToken, requireRole("student"), ctrl.checkin);
router.post("/checkout", verifyToken, requireRole("student"), ctrl.checkout);
router.get("/students/:uid/attendance", verifyToken, ctrl.getStudentAttendance);
router.get("/sessions/:id/headcount", verifyToken, ctrl.headcount);

module.exports = router;
