const express = require('express');
const router = express.Router();
const { getSafeSettings, updateSettings, getSettings } = require('../database/store');
const { ZKBioTimeConnector } = require('../connector/zkbiotime.connector');
const { logAction } = require('../services/audit.service');
const { requireAuth, requireRole } = require('../auth/auth');

// Get current system settings
router.get('/', (req, res) => {
  try {
    const settings = getSafeSettings();
    return res.json({
      success: true,
      data: settings
    });
  } catch (err) {
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Update system settings (Admin only when authenticated)
router.post('/', (req, res) => {
  try {
    const current = getSafeSettings();
    const updated = updateSettings(req.body);

    logAction(req, 'UPDATE_SETTINGS', {
      previousUrl: current.serverUrl,
      newUrl: updated.serverUrl,
      username: updated.username,
      overtimeStartTime: updated.overtimeStartTime
    });

    return res.json({
      success: true,
      message: 'Paramètres enregistrés avec succès.',
      data: updated
    });
  } catch (err) {
    logAction(req, 'UPDATE_SETTINGS_ERROR', { error: err.message }, 'FAILURE');
    return res.status(500).json({ success: false, error: err.message });
  }
});

// Test connection to ZKBioTime server
router.post('/test-connection', async (req, res) => {
  const { serverUrl, username, password } = req.body;
  const currentSettings = getSettings();

  const targetUrl = serverUrl || currentSettings.serverUrl;
  const targetUser = username || currentSettings.username;
  const targetPass = password !== undefined && password !== '' ? password : currentSettings.password;

  const connector = new ZKBioTimeConnector();
  const testResult = await connector.testConnection(targetUrl, targetUser, targetPass);

  logAction(req, 'TEST_CONNECTION', {
    serverUrl: targetUrl,
    username: targetUser,
    success: testResult.success,
    authType: testResult.authType
  }, testResult.success ? 'SUCCESS' : 'FAILURE');

  return res.json(testResult);
});

module.exports = router;
