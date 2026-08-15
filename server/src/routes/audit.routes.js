const express = require('express');
const router = express.Router();
const { getAuditLogs } = require('../database/store');

router.get('/', (req, res) => {
  try {
    const limit = parseInt(req.query.limit, 10) || 100;
    const action = req.query.action || null;
    const logs = getAuditLogs(limit, action);

    return res.json({
      success: true,
      data: logs
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      error: err.message
    });
  }
});

module.exports = router;
