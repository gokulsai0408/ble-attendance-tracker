const admin = require("firebase-admin");

// Prefer application default credentials via GOOGLE_APPLICATION_CREDENTIALS
// Fallback: if serviceAccountKey.json exists, the environment may already point to it.
const projectId = process.env.FIREBASE_PROJECT_ID || undefined;

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId,
});

module.exports = admin;
