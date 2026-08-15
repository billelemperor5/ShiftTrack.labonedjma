const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { JWT_SECRET, JWT_EXPIRES_IN } = require('../config');
const { findUserByUsername, findUserById, addAuditLog } = require('../database/store');

/**
 * Authenticate user credentials and return JWT token
 */
function login(username, password, ip = '127.0.0.1') {
  if (!username || !password) {
    throw new Error('Identifiants obligatoires');
  }

  const user = findUserByUsername(username);
  if (!user) {
    addAuditLog({
      username,
      role: 'UNKNOWN',
      action: 'LOGIN_FAILED',
      details: { reason: 'User not found' },
      ip,
      status: 'FAILURE'
    });
    throw new Error('Nom d\'utilisateur ou mot de passe incorrect');
  }

  const match = bcrypt.compareSync(password, user.passwordHash);
  if (!match) {
    addAuditLog({
      userId: user.id,
      username: user.username,
      role: user.role,
      action: 'LOGIN_FAILED',
      details: { reason: 'Invalid password' },
      ip,
      status: 'FAILURE'
    });
    throw new Error('Nom d\'utilisateur ou mot de passe incorrect');
  }

  const token = jwt.sign(
    {
      id: user.id,
      username: user.username,
      fullName: user.fullName,
      role: user.role
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );

  addAuditLog({
    userId: user.id,
    username: user.username,
    role: user.role,
    action: 'LOGIN',
    details: { message: 'User logged in successfully' },
    ip,
    status: 'SUCCESS'
  });

  return {
    token,
    user: {
      id: user.id,
      username: user.username,
      fullName: user.fullName,
      role: user.role
    }
  };
}

/**
 * Middleware to verify JWT token
 */
function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Non autorisé. Veuillez vous connecter.'
    });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      error: 'Session expirée ou invalide. Veuillez vous reconnecter.'
    });
  }
}

/**
 * Middleware to restrict route by role
 */
function requireRole(requiredRole) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, error: 'Non authentifié' });
    }
    if (req.user.role !== requiredRole && req.user.role !== 'ADMIN') {
      return res.status(403).json({
        success: false,
        error: 'Accès refusé. Privilèges administrateur requis.'
      });
    }
    next();
  };
}

module.exports = {
  login,
  requireAuth,
  requireRole
};
