const express = require("express");
const { register, login } = require("../controllers/authController");
const verifyToken = require("../middleware/verifyToken");

const router = express.Router();

router.use(express.json());

// Public endpoint for simple health check
router.get("/api/public", (req, res) => {
  res.json({ message: "This data is available to everyone." });
});

// Signup and login endpoints
router.post("/register", register);
router.post("/login", login);

// Protected endpoint example
router.get("/api/private", verifyToken, (req, res) => {
  res.json({
    message: "Welcome to the secret data room!",
    userId: req.user.uid,
    email: req.user.email,
  });
});

module.exports = router;
