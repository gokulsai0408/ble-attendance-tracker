const express = require("express");
const router = express.Router();
const verifyToken = require("../middleware/verifyToken");
const requireRole = require("../middleware/requireRole");
const ctrl = require("../controllers/sessionController");

router.use(express.json());

router.post("/", verifyToken, requireRole("professor"), ctrl.createSession);
router.post(
  "/:id/start",
  verifyToken,
  requireRole("professor"),
  ctrl.startSession,
);
router.post(
  "/:id/advance",
  verifyToken,
  requireRole("professor"),
  ctrl.advanceSession,
);
router.post("/:id/end", verifyToken, requireRole("professor"), ctrl.endSession);
router.get("/:id", verifyToken, requireRole("professor"), ctrl.getSession);
router.get(
  "/:id/attendance",
  verifyToken,
  requireRole("professor"),
  ctrl.getAttendanceList,
);

module.exports = router;
