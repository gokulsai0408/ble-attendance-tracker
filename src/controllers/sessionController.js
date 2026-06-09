const admin = require("../config/firebase");
const { generateSequence } = require("../utils/uuidSequence");
const { pushSequence, advanceIndex } = require("../services/anchorPush");

async function createSession(req, res) {
  try {
    const { moduleCode, room } = req.body;
    if (!moduleCode || !room)
      return res.status(400).json({ error: "moduleCode and room required" });
    const { randomUUID } = require("crypto");
    const sessionId = randomUUID();
    const uuidSequence = generateSequence(20);
    const session = {
      sessionId,
      moduleCode,
      room,
      professorUid: req.user.uid,
      startTime: null,
      endTime: null,
      uuidSequence,
      currentSeqIndex: 0,
      active: false,
    };
    await admin.firestore().collection("sessions").doc(sessionId).set(session);
    return res.json({ sessionId, uuidSequence });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
}

async function startSession(req, res) {
  try {
    const { id } = req.params;
    const sessionRef = admin.firestore().collection("sessions").doc(id);
    const snap = await sessionRef.get();
    if (!snap.exists)
      return res.status(404).json({ error: "Session not found" });
    const session = snap.data();
    if (session.professorUid !== req.user.uid)
      return res.status(403).json({ error: "Forbidden" });

    const anchorResponses = await pushSequence(session.uuidSequence);
    await sessionRef.update({
      active: true,
      startTime: admin.firestore.FieldValue.serverTimestamp(),
    });
    return res.json({ ok: true, anchorResponses });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
}

async function advanceSession(req, res) {
  try {
    const { id } = req.params;
    const { seq } = req.body;
    if (typeof seq !== "number")
      return res.status(400).json({ error: "seq number required" });
    const sessionRef = admin.firestore().collection("sessions").doc(id);
    await admin.firestore().runTransaction(async (t) => {
      const doc = await t.get(sessionRef);
      if (!doc.exists) throw new Error("Session not found");
      const data = doc.data();
      if (data.professorUid !== req.user.uid) throw new Error("Forbidden");
      const newIndex = (data.currentSeqIndex + 1) % data.uuidSequence.length;
      t.update(sessionRef, { currentSeqIndex: newIndex });
    });
    const anchorResults = await advanceIndex(seq);
    const updated = await sessionRef.get();
    return res.json({
      ok: true,
      currentSeqIndex: updated.data().currentSeqIndex,
      anchorResults,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
}

async function endSession(req, res) {
  try {
    const { id } = req.params;
    const sessionRef = admin.firestore().collection("sessions").doc(id);
    const snap = await sessionRef.get();
    if (!snap.exists)
      return res.status(404).json({ error: "Session not found" });
    const session = snap.data();
    if (session.professorUid !== req.user.uid)
      return res.status(403).json({ error: "Forbidden" });

    // close session
    await sessionRef.update({
      active: false,
      endTime: admin.firestore.FieldValue.serverTimestamp(),
    });

    // find attendance documents for this session without checkout
    const attendanceRef = admin.firestore().collection("attendance");
    console.log(
      "DEBUG attendanceRef:",
      attendanceRef,
      "where type:",
      typeof attendanceRef.where,
    );
    const q = attendanceRef
      .where("sessionId", "==", id)
      .where("checkOutTime", "==", null);
    const firstWhere = attendanceRef.where("sessionId", "==", id);
    console.log("DEBUG firstWhere.where type:", typeof firstWhere.where);
    const snaps = await q.get();
    const batch = admin.firestore().batch();
    const now = admin.firestore.Timestamp.now();
    snaps.forEach((doc) => {
      const data = doc.data();
      const checkIn = data.checkInTime || now;
      const duration = now.seconds - checkIn.seconds;
      batch.update(doc.ref, { checkOutTime: now, duration });
    });
    await batch.commit();
    const totalStudents = snaps.size;
    return res.json({ ok: true, totalStudents });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
}

async function getSession(req, res) {
  try {
    const { id } = req.params;
    const sessionRef = admin.firestore().collection("sessions").doc(id);
    const snap = await sessionRef.get();
    if (!snap.exists)
      return res.status(404).json({ error: "Session not found" });
    const session = snap.data();
    // headcount: attendance records with checkInTime and null checkOutTime
    const attendanceRef = admin.firestore().collection("attendance");
    const q = attendanceRef
      .where("sessionId", "==", id)
      .where("checkOutTime", "==", null);
    const snaps = await q.get();
    const headcount = snaps.size;
    return res.json({ session, headcount });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
}

async function getAttendanceList(req, res) {
  try {
    const { id } = req.params;
    const attendanceRef = admin.firestore().collection("attendance");
    const q = attendanceRef.where("sessionId", "==", id);
    const snaps = await q.get();
    const list = [];
    for (const doc of snaps.docs) {
      const d = doc.data();
      const userSnap = await admin
        .firestore()
        .collection("users")
        .doc(d.studentUid)
        .get();
      const name = userSnap.exists ? userSnap.data().name : null;
      list.push({
        studentUid: d.studentUid,
        name,
        checkInTime: d.checkInTime,
        checkOutTime: d.checkOutTime,
        duration: d.duration,
      });
    }
    return res.json(list);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}

module.exports = {
  createSession,
  startSession,
  advanceSession,
  endSession,
  getSession,
  getAttendanceList,
};
