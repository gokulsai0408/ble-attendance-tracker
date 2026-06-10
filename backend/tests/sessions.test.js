// Mock firebase-admin and anchorPush before importing the app
const makeMockFirebase = () => {
  const db = { sessions: {}, attendance: {}, users: {} };

  const Timestamp = { now: () => ({ seconds: Math.floor(Date.now() / 1000) }) };

  function collection(name) {
    return {
      doc(id) {
        return {
          id,
          _collection: name,
          async set(obj, opts) {
            if (opts && opts.merge && db[name][id]) {
              db[name][id] = { ...db[name][id], ...obj };
            } else {
              db[name][id] = { ...(db[name][id] || {}), ...obj };
            }
          },
          async get() {
            const exists = !!db[name][id];
            return { exists, data: () => db[name][id] };
          },
          async update(obj) {
            if (!db[name][id]) throw new Error("No such document");
            db[name][id] = { ...db[name][id], ...obj };
          },
        };
      },
      where(field, op, value) {
        return {
          async get() {
            const docs = Object.entries(db[name])
              .filter(([, v]) => (op === "==" ? v[field] === value : false))
              .map(([k, v]) => ({
                ref: { id: k, _collection: name },
                data: () => v,
              }));
            return {
              size: docs.length,
              docs,
              forEach: (cb) => docs.forEach(cb),
            };
          },
        };
      },
      where(field, op, value) {
        const clauses = [{ field, op, value }];
        return {
          where(nextField, nextOp, nextValue) {
            clauses.push({ field: nextField, op: nextOp, value: nextValue });
            return this;
          },
          async get() {
            const docs = Object.entries(db[name])
              .filter(([, v]) =>
                clauses.every((c) =>
                  c.op === "==" ? v[c.field] === c.value : false,
                ),
              )
              .map(([k, v]) => ({
                ref: { id: k, _collection: name },
                data: () => v,
              }));
            return {
              size: docs.length,
              docs,
              forEach: (cb) => docs.forEach(cb),
            };
          },
        };
      },
    };
  }

  function batch() {
    const updates = [];
    return {
      update(ref, obj) {
        updates.push({ ref, obj });
      },
      async commit() {
        for (const u of updates) {
          const { ref, obj } = u;
          const col = ref._collection;
          const id = ref.id;
          if (!db[col][id]) db[col][id] = {};
          db[col][id] = { ...db[col][id], ...obj };
        }
      },
    };
  }

  const firestoreFn = () => ({
    collection,
    FieldValue: {
      serverTimestamp: () => Timestamp.now(),
      arrayUnion: (v) => v,
    },
    batch,
    Timestamp,
    runTransaction: async (cb) => {
      return cb({
        get: async (ref) => {
          const exists = !!db[ref._collection][ref.id];
          return { exists, data: () => db[ref._collection][ref.id] };
        },
        update: (ref, obj) => {
          if (!db[ref._collection][ref.id]) throw new Error("No such document");
          db[ref._collection][ref.id] = {
            ...db[ref._collection][ref.id],
            ...obj,
          };
        },
      });
    },
  });

  firestoreFn.FieldValue = {
    serverTimestamp: () => Timestamp.now(),
    arrayUnion: (v) => v,
  };
  firestoreFn.Timestamp = Timestamp;

  return {
    auth: () => ({
      async verifyIdToken(token) {
        if (token === "prof-token") return { uid: "prof1", role: "professor" };
        if (token === "stud-token") return { uid: "stud1", role: "student" };
        throw new Error("invalid token");
      },
    }),
    firestore: firestoreFn,
    Timestamp,
    _db: db,
  };
};

jest.mock("../src/config/firebase", () => makeMockFirebase());
jest.mock("../src/services/anchorPush", () => ({
  pushSequence: jest.fn(async (uuids) =>
    uuids.map((u) => ({ ip: "1", ok: true, uuid: u })),
  ),
  advanceIndex: jest.fn(async (seq) => [{ ip: "1", ok: true, seq }]),
}));

const request = require("supertest");
const app = require("../src/index");
const admin = require("../src/config/firebase");
const anchorPush = require("../src/services/anchorPush");

test("POST /sessions creates session and returns sessionId + uuidSequence", async () => {
  const resp = await request(app)
    .post("/sessions")
    .set("Authorization", "Bearer prof-token")
    .send({ moduleCode: "CS101", room: "LT27" });
  expect(resp.status).toBe(200);
  expect(resp.body.sessionId).toBeDefined();
  expect(Array.isArray(resp.body.uuidSequence)).toBe(true);
  expect(resp.body.uuidSequence).toHaveLength(20);
  // verify session stored
  const id = resp.body.sessionId;
  const stored = admin._db.sessions[id];
  expect(stored.moduleCode).toBe("CS101");
});

test("POST /sessions/:id/start calls anchorPush.pushSequence and sets session active", async () => {
  // create session manually
  const id = "sess-start";
  const uuidSequence = Array.from({ length: 5 }, (_, i) => `u-${i}`);
  await admin.firestore().collection("sessions").doc(id).set({
    sessionId: id,
    uuidSequence,
    professorUid: "prof1",
    currentSeqIndex: 0,
    active: false,
  });
  const resp = await request(app)
    .post(`/sessions/${id}/start`)
    .set("Authorization", "Bearer prof-token");
  expect(resp.status).toBe(200);
  expect(anchorPush.pushSequence).toHaveBeenCalled();
  const updated = await admin.firestore().collection("sessions").doc(id).get();
  expect(updated.data().active).toBe(true);
});

test("POST /sessions/:id/advance increments currentSeqIndex", async () => {
  const id = "sess-adv";
  const uuidSequence = ["a", "b", "c"];
  await admin.firestore().collection("sessions").doc(id).set({
    sessionId: id,
    uuidSequence,
    professorUid: "prof1",
    currentSeqIndex: 0,
    active: true,
  });
  const resp = await request(app)
    .post(`/sessions/${id}/advance`)
    .set("Authorization", "Bearer prof-token")
    .send({ seq: 1 });
  expect(resp.status).toBe(200);
  expect(resp.body.currentSeqIndex).toBe(1);
});

test("POST /sessions/:id/end sets active false and computes durations", async () => {
  const id = "sess-end";
  // create session and attendance without checkOutTime
  await admin
    .firestore()
    .collection("sessions")
    .doc(id)
    .set({ sessionId: id, professorUid: "prof1", active: true });
  const checkInTime = { seconds: Math.floor(Date.now() / 1000) - 120 };
  // attendance doc id format sessionId_studentUid
  const attId = `${id}_stud1`;
  await admin.firestore().collection("attendance").doc(attId).set({
    sessionId: id,
    studentUid: "stud1",
    checkInTime,
    checkOutTime: null,
  });

  const resp = await request(app)
    .post(`/sessions/${id}/end`)
    .set("Authorization", "Bearer prof-token");
  expect(resp.status).toBe(200);
  expect(resp.body.ok).toBe(true);
  // verify attendance updated
  const updated = await admin
    .firestore()
    .collection("attendance")
    .doc(attId)
    .get();
  expect(updated.data().checkOutTime).toBeDefined();
  expect(updated.data().duration).toBeGreaterThanOrEqual(120);
});

test("GET /sessions/:id returns session + headcount", async () => {
  const id = "sess-head";
  await admin
    .firestore()
    .collection("sessions")
    .doc(id)
    .set({ sessionId: id, professorUid: "prof1", active: true });
  const att1 = `${id}_s1`;
  const att2 = `${id}_s2`;
  await admin
    .firestore()
    .collection("attendance")
    .doc(att1)
    .set({
      sessionId: id,
      studentUid: "s1",
      checkInTime: { seconds: 1000 },
      checkOutTime: null,
    });
  await admin
    .firestore()
    .collection("attendance")
    .doc(att2)
    .set({
      sessionId: id,
      studentUid: "s2",
      checkInTime: { seconds: 1000 },
      checkOutTime: { seconds: 1100 },
    });

  const resp = await request(app)
    .get(`/sessions/${id}`)
    .set("Authorization", "Bearer prof-token");
  expect(resp.status).toBe(200);
  expect(resp.body.headcount).toBe(1);
});
