jest.mock("../src/config/firebase", () => {
  const db = { attendance: {}, sessions: {}, users: {} };
  const Timestamp = { now: () => ({ seconds: Math.floor(Date.now() / 1000) }) };

  function collection(name) {
    return {
      doc(id) {
        return {
          id,
          _collection: name,
          async set(obj, opts) {
            if (opts && opts.merge && db[name][id])
              db[name][id] = { ...db[name][id], ...obj };
            else db[name][id] = { ...(db[name][id] || {}), ...obj };
          },
          async get() {
            return { exists: !!db[name][id], data: () => db[name][id] };
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
              .map(([k, v]) => ({ id: k, data: () => v }));
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
    FieldValue: { arrayUnion: (v) => v },
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

  firestoreFn.FieldValue = { arrayUnion: (v) => v };
  firestoreFn.Timestamp = Timestamp;

  return {
    auth: () => ({
      async verifyIdToken(token) {
        if (token === "stud-token") return { uid: "stud1", role: "student" };
        throw new Error("invalid");
      },
    }),
    firestore: firestoreFn,
    Timestamp,
    _db: db,
  };
});

const request = require("supertest");
const app = require("../src/index");
const admin = require("../src/config/firebase");
beforeEach(() => {
  const db = admin._db;
  db.attendance = {};
  db.sessions = {};
  db.users = {};
});

test("POST /attendance/report with verified presence triggers checkin", async () => {
  // ensure presenceVerifier will return present by sending strong RSSI for two anchors
  const resp = await request(app)
    .post("/attendance/report")
    .set("Authorization", "Bearer stud-token")
    .send({
      sessionId: "sess1",
      studentUid: "stud1",
      scanResults: [
        { anchorId: "front", rssi: -60 },
        { anchorId: "mid", rssi: -65 },
      ],
    });
  expect(resp.status).toBe(200);
  expect(resp.body.present).toBe(true);
});

test("POST /attendance/report with insufficient RSSI returns present false", async () => {
  const resp = await request(app)
    .post("/attendance/report")
    .set("Authorization", "Bearer stud-token")
    .send({
      sessionId: "sess1",
      studentUid: "stud1",
      scanResults: [
        { anchorId: "front", rssi: -90 },
        { anchorId: "mid", rssi: -95 },
      ],
    });
  expect(resp.status).toBe(200);
  expect(resp.body.present).toBe(false);
});

test("POST /attendance/checkin is idempotent", async () => {
  // first call
  const first = await request(app)
    .post("/attendance/checkin")
    .set("Authorization", "Bearer stud-token")
    .send({ sessionId: "sess1" });
  expect(first.status).toBe(200);
  expect(first.body.alreadyCheckedIn).toBe(false);
  // second call
  const second = await request(app)
    .post("/attendance/checkin")
    .set("Authorization", "Bearer stud-token")
    .send({ sessionId: "sess1" });
  expect(second.status).toBe(200);
  expect(second.body.alreadyCheckedIn).toBe(true);
});

test("POST /attendance/checkout computes correct duration", async () => {
  // ensure checkin exists at an earlier time
  const before = Math.floor(Date.now() / 1000) - 60;
  const id = `sess1_stud1`;
  await admin
    .firestore()
    .collection("attendance")
    .doc(id)
    .set({
      sessionId: "sess1",
      studentUid: "stud1",
      checkInTime: { seconds: before },
      checkOutTime: null,
    });
  const resp = await request(app)
    .post("/attendance/checkout")
    .set("Authorization", "Bearer stud-token")
    .send({ sessionId: "sess1" });
  expect(resp.status).toBe(200);
  expect(resp.body.duration).toBeGreaterThanOrEqual(60);
});

test("GET /students/:uid/attendance returns array of sessions", async () => {
  const id = `sessX_stud1`;
  await admin
    .firestore()
    .collection("attendance")
    .doc(id)
    .set({
      sessionId: "sessX",
      studentUid: "stud1",
      checkInTime: { seconds: 100 },
      checkOutTime: { seconds: 200 },
      duration: 100,
    });
  const resp = await request(app)
    .get("/attendance/students/stud1/attendance")
    .set("Authorization", "Bearer stud-token");
  expect(resp.status).toBe(200);
  expect(Array.isArray(resp.body)).toBe(true);
});
