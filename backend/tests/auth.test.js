jest.mock("../src/config/firebase", () => {
  const Timestamp = { now: () => ({ seconds: Math.floor(Date.now() / 1000) }) };
  return {
    auth: () => ({
      createUser: jest.fn(async ({ email }) => ({ uid: "uid123", email })),
      setCustomUserClaims: jest.fn(async () => {}),
      verifyIdToken: jest.fn(async (token) => ({
        uid: "uid123",
        email: "a@b.com",
        role: "student",
      })),
    }),
    firestore: () => ({
      collection: () => ({
        doc: () => ({
          set: jest.fn(async () => {}),
          get: jest.fn(async () => ({
            exists: true,
            data: () => ({
              uid: "uid123",
              name: "Test",
              role: "student",
              email: "a@b.com",
            }),
          })),
        }),
      }),
      FieldValue: {
        serverTimestamp: () => Timestamp.now(),
        arrayUnion: (v) => v,
      },
    }),
    Timestamp,
  };
});

const request = require("supertest");
const app = require("../src/index");

test("POST /auth/register returns uid", async () => {
  const resp = await request(app)
    .post("/auth/register")
    .send({
      email: "a@b.com",
      password: "pass",
      name: "Test",
      role: "student",
    });
  expect(resp.status).toBe(200);
  expect(resp.body.uid).toBe("uid123");
});

test("POST /auth/login without token returns 401", async () => {
  const resp = await request(app).post("/auth/login");
  expect(resp.status).toBe(401);
});
