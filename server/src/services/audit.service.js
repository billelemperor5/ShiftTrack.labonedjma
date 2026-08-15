const { addAuditLog, getAuditLogs } = require('../database/store');

module.exports = {
  logAction: (req, action, details = {}, status = 'SUCCESS') => {
    const user = req.user || {};
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
    return addAuditLog({
      userId: user.id || 'anonymous',
      username: user.username || 'Invité',
      role: user.role || 'GUEST',
      action,
      details,
      ip,
      status
    });
  },
  getLogs: (limit, filter) => getAuditLogs(limit, filter)
};
