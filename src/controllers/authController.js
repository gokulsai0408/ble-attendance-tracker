const admin = require("../config/firebase");

// POST /auth/register
async function register(req, res) {
  try {
    const { email, password, name, role } = req.body;
    if (!email || !password || !name || !role) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const userRecord = await admin
      .auth()
      .createUser({ email, password, displayName: name });
    await admin.auth().setCustomUserClaims(userRecord.uid, { role });

    const userDoc = {
      uid: userRecord.uid,
      name,
      email: userRecord.email,
      role,
      enrolledSessions: [],
    };
    await admin
      .firestore()
      .collection("users")
      .doc(userRecord.uid)
      .set(userDoc);
    return res.json({ uid: userRecord.uid });
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }
}

// POST /auth/login - verify token and return basic user info
async function login(req, res) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Missing Authorization header" });
    }
    const token = authHeader.split(" ")[1];
    const decoded = await admin.auth().verifyIdToken(token);
    const uid = decoded.uid;
    const userDoc = await admin.firestore().collection("users").doc(uid).get();
    const user = userDoc.exists
      ? userDoc.data()
      : {
          uid,
          name: decoded.name || null,
          email: decoded.email || null,
          role: decoded.role || null,
        };
    return res.json({ uid: user.uid, role: user.role, name: user.name });
  } catch (err) {
    return res
      .status(401)
      .json({ error: "Invalid token", details: err.message });
  }
}

module.exports = { register, login };
