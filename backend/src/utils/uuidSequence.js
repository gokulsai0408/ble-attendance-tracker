const { randomUUID } = require("crypto");

function generateSequence(count = 20) {
  const arr = [];
  for (let i = 0; i < count; i++) arr.push(randomUUID());
  return arr;
}

module.exports = { generateSequence };
