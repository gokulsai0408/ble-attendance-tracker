const admin = require("firebase-admin");

// The error was caused by a mismatch in firebase-admin SDK versions.
// Using cert() instead of applicationDefault() for better compatibility with local service keys.
const projectId = process.env.FIREBASE_PROJECT_ID;

// For now, let's initialize it in a way that doesn't crash if the key is missing
try {
  admin.initializeApp({
    credential: admin.credential.cert(process.env.GOOGLE_APPLICATION_CREDENTIALS || "./serviceAccountKey.json"),
    projectId,
  });
} catch (e) {
  console.log("Firebase Init Warning: Make sure serviceAccountKey.json exists in the backend folder.");
  // Fallback for development if credentials aren't ready yet
  admin.initializeApp({
    projectId: projectId || "demo-project",
  });
}

module.exports = admin;
