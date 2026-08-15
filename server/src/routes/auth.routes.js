const express = require('express');
const router = express.Router();
const { login, requireAuth } = require('../auth/auth');

router.post('/login', (req, res) => {
  try {
    const { username, password } = req.body;
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
    const result = login(username, password, ip);
    return res.json({
      success: true,
      data: result
    });
  } catch (err) {
    return res.status(400).json({
      success: false,
      error: err.message || 'Échec de connexion'
    });
  }
});

router.get('/me', requireAuth, (req, res) => {
  return res.json({
    success: true,
    data: {
      user: req.user
    }
  });
});

module.exports = router;
