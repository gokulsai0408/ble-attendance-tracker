const admin = require("../config/firebase");
const { verifyPresence } = require("../services/presenceVerifier");

async function report(req, res) {
  try {
    const { sessionId, studentUid, scanResults } = req.body;
    if (!sessionId || !studentUid || !Array.isArray(scanResults))
      return res.status(400).json({ error: "Invalid body" });

    const { present, anchorMeans } = verifyPresence(studentUid, scanResults);

    // append to presenceLog
    const id = `${sessionId}_${studentUid}`;
    const attendanceRef = admin.firestore().collection("attendance").doc(id);
    const now = admin.firestore.Timestamp.now();
    await attendanceRef.set(
      {
        sessionId,
        studentUid,
        presenceLog: admin.firestore.FieldValue.arrayUnion({
          ts: now,
          anchorCount: anchorMeans.length,
          rssiMap: Object.fromEntries(
            anchorMeans.map((a) => [a.anchorId, a.mean]),
          ),
        }),
      },
      { merge: true },
    );

    // auto checkin if present and not already checked in
    let checkedIn = false;
    const doc = await attendanceRef.get();
    if (!doc.exists || !doc.data().checkInTime) {
      if (present) {
        await attendanceRef.set({ checkInTime: now }, { merge: true });
        checkedIn = true;
      }
    }

    return res.json({ present, checkedIn });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
}

async function checkin(req, res) {
  try {
    const { sessionId } = req.body;
    const studentUid = req.user.uid;
    if (!sessionId)
      return res.status(400).json({ error: "sessionId required" });
    const id = `${sessionId}_${studentUid}`;
    const ref = admin.firestore().collection("attendance").doc(id);
    const doc = await ref.get();
    if (doc.exists && doc.data().checkInTime) {
      return res.json({
        attendanceId: id,
        checkInTime: doc.data().checkInTime,
        alreadyCheckedIn: true,
      });
    }
    const now = admin.firestore.Timestamp.now();
    await ref.set(
      {
        sessionId,
        studentUid,
        checkInTime: now,
        checkOutTime: null,
        duration: null,
      },
      { merge: true },
    );
    return res.json({
      attendanceId: id,
      checkInTime: now,
      alreadyCheckedIn: false,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
}

async function checkout(req, res) {
  try {
    const { sessionId } = req.body;
    const studentUid = req.user.uid;
    if (!sessionId)
      return res.status(400).json({ error: "sessionId required" });
    const id = `${sessionId}_${studentUid}`;
    const ref = admin.firestore().collection("attendance").doc(id);
    await admin.firestore().runTransaction(async (t) => {
      const doc = await t.get(ref);
      if (!doc.exists || !doc.data().checkInTime)
        throw new Error("Not checked in");
      const now = admin.firestore.Timestamp.now();
      const checkIn = doc.data().checkInTime;
      const duration = now.seconds - checkIn.seconds;
      t.update(ref, { checkOutTime: now, duration });
    });
    const updated = await ref.get();
    return res.json({
      checkOutTime: updated.data().checkOutTime,
      duration: updated.data().duration,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
}

async function getStudentAttendance(req, res) {
  try {
    const { uid } = req.params;
    const q = admin
      .firestore()
      .collection("attendance")
      .where("studentUid", "==", uid);
    const snaps = await q.get();
    const list = [];
    for (const doc of snaps.docs) {
      const d = doc.data();
      // fetch session for moduleCode
      const sessionSnap = await admin
        .firestore()
        .collection("sessions")
        .doc(d.sessionId)
        .get();
      const moduleCode = sessionSnap.exists
        ? sessionSnap.data().moduleCode
        : null;
      list.push({
        sessionId: d.sessionId,
        moduleCode,
        checkInTime: d.checkInTime,
        checkOutTime: d.checkOutTime,
        duration: d.duration,
      });
    }
    return res.json(list);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
}

async function headcount(req, res) {
  try {
    const { id } = req.params;
    const q = admin
      .firestore()
      .collection("attendance")
      .where("sessionId", "==", id)
      .where("checkOutTime", "==", null);
    const snaps = await q.get();
    return res.json({ headcount: snaps.size });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = { report, checkin, checkout, getStudentAttendance, headcount };
