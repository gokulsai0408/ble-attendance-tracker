require("dotenv").config();
const express = require("express");
const cors = require("cors");
const app = express();

app.set("trust proxy", true);
app.use(cors());
app.use(express.json());

// Routes
const authRouter = require("./routes/auth");
const sessionsRouter = require("./routes/sessions");
const attendanceRouter = require("./routes/attendance");

app.use("/auth", authRouter);
app.use("/sessions", sessionsRouter);
app.use("/attendance", attendanceRouter);

// basic health
app.get("/health", (req, res) => res.json({ ok: true }));

const port = process.env.PORT || 3000;
if (require.main === module) {
  app.listen(port, () => console.log(`Server running on port ${port}`));
}

module.exports = app;
