const { onRequest } = require("firebase-functions/v2/https");
const app = require("./src/server");

// Export Express API as Firebase Cloud Function
exports.api = onRequest(
  {
    cors: true,
    maxInstances: 10,
    timeoutSeconds: 60,
  },
  app
);
