const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const { 
  DATA_DIR, 
  DEFAULT_ZKBIO_URL, 
  DEFAULT_ZKBIO_USER, 
  DEFAULT_ZKBIO_PASS,
  DEFAULT_OVERTIME_START,
  DEFAULT_STANDARD_START,
  DEFAULT_DUPLICATE_WINDOW_SEC,
  DEFAULT_ROUNDING_MINUTES,
  encrypt,
  decrypt
} = require('../config');

if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

const SETTINGS_FILE = path.join(DATA_DIR, 'settings.json');
const USERS_FILE = path.join(DATA_DIR, 'users.json');
const AUDIT_FILE = path.join(DATA_DIR, 'audit_logs.json');
const CACHE_FILE = path.join(DATA_DIR, 'cache.json');

function readJson(filePath, defaultValue = {}) {
  try {
    if (!fs.existsSync(filePath)) {
      fs.writeFileSync(filePath, JSON.stringify(defaultValue, null, 2), 'utf8');
      return defaultValue;
    }
    const raw = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    console.error(`Error reading ${filePath}:`, err.message);
    return defaultValue;
  }
}

function writeJson(filePath, data) {
  try {
    const tempPath = `${filePath}.tmp.${Date.now()}`;
    fs.writeFileSync(tempPath, JSON.stringify(data, null, 2), 'utf8');
    fs.renameSync(tempPath, filePath);
  } catch (err) {
    console.error(`Error writing ${filePath}:`, err.message);
  }
}

// Initialize default data
function initDatabase() {
  // 1. Settings
  let settings = readJson(SETTINGS_FILE, null);
  if (!settings) {
    settings = {
      serverUrl: DEFAULT_ZKBIO_URL,
      username: DEFAULT_ZKBIO_USER,
      passwordEnc: encrypt(DEFAULT_ZKBIO_PASS),
      overtimeStartTime: DEFAULT_OVERTIME_START,
      standardStartTime: DEFAULT_STANDARD_START,
      duplicateWindowSec: DEFAULT_DUPLICATE_WINDOW_SEC,
      enableRounding: false,
      roundingMinutes: DEFAULT_ROUNDING_MINUTES,
      lastSyncTime: null,
      updatedAt: new Date().toISOString()
    };
    writeJson(SETTINGS_FILE, settings);
  }

  // 2. Users
  let users = readJson(USERS_FILE, null);
  if (!users || !Array.isArray(users) || users.length === 0) {
    const salt = bcrypt.genSaltSync(10);
    users = [
      {
        id: 'usr_admin',
        username: 'admin',
        passwordHash: bcrypt.hashSync('admin123', salt),
        fullName: 'Administrateur Système',
        role: 'ADMIN',
        createdAt: new Date().toISOString()
      },
      {
        id: 'usr_supervisor',
        username: 'supervisor',
        passwordHash: bcrypt.hashSync('user123', salt),
        fullName: 'Superviseur RH',
        role: 'USER',
        createdAt: new Date().toISOString()
      }
    ];
    writeJson(USERS_FILE, users);
  }

  // 3. Audit Logs
  let audit = readJson(AUDIT_FILE, null);
  if (!audit || !Array.isArray(audit)) {
    writeJson(AUDIT_FILE, []);
  }

  // 4. Cache
  let cache = readJson(CACHE_FILE, null);
  if (!cache) {
    writeJson(CACHE_FILE, { employees: {}, transactions: {}, lastUpdated: {} });
  }
}

// Settings methods
function getSettings() {
  const settings = readJson(SETTINGS_FILE, {});
  const decryptedPass = decrypt(settings.passwordEnc);
  const user = (settings.username && settings.username.trim() && settings.username !== 'attendance_readonly')
    ? settings.username.trim()
    : (process.env.ZKBIO_USERNAME || DEFAULT_ZKBIO_USER);
  const pass = (decryptedPass && decryptedPass.trim())
    ? decryptedPass.trim()
    : (process.env.ZKBIO_PASSWORD || DEFAULT_ZKBIO_PASS);

  return {
    ...settings,
    serverUrl: (settings.serverUrl && settings.serverUrl.trim()) ? settings.serverUrl.trim() : DEFAULT_ZKBIO_URL,
    username: user,
    password: pass
  };
}

function getSafeSettings() {
  const settings = readJson(SETTINGS_FILE, {});
  return {
    serverUrl: settings.serverUrl,
    username: settings.username,
    hasPassword: !!settings.passwordEnc,
    overtimeStartTime: settings.overtimeStartTime || DEFAULT_OVERTIME_START,
    standardStartTime: settings.standardStartTime || DEFAULT_STANDARD_START,
    duplicateWindowSec: settings.duplicateWindowSec || DEFAULT_DUPLICATE_WINDOW_SEC,
    enableRounding: !!settings.enableRounding,
    roundingMinutes: settings.roundingMinutes || DEFAULT_ROUNDING_MINUTES,
    lastSyncTime: settings.lastSyncTime,
    updatedAt: settings.updatedAt
  };
}

function updateSettings(newSettings) {
  const current = readJson(SETTINGS_FILE, {});
  const updated = {
    ...current,
    serverUrl: newSettings.serverUrl !== undefined ? newSettings.serverUrl.trim() : current.serverUrl,
    username: newSettings.username !== undefined ? newSettings.username.trim() : current.username,
    overtimeStartTime: newSettings.overtimeStartTime || current.overtimeStartTime,
    standardStartTime: newSettings.standardStartTime || current.standardStartTime,
    duplicateWindowSec: newSettings.duplicateWindowSec !== undefined ? Number(newSettings.duplicateWindowSec) : current.duplicateWindowSec,
    enableRounding: newSettings.enableRounding !== undefined ? !!newSettings.enableRounding : current.enableRounding,
    roundingMinutes: newSettings.roundingMinutes !== undefined ? Number(newSettings.roundingMinutes) : current.roundingMinutes,
    updatedAt: new Date().toISOString()
  };

  if (newSettings.password && newSettings.password.trim().length > 0) {
    updated.passwordEnc = encrypt(newSettings.password.trim());
  }

  if (newSettings.lastSyncTime) {
    updated.lastSyncTime = newSettings.lastSyncTime;
  }

  writeJson(SETTINGS_FILE, updated);
  return getSafeSettings();
}

// Users methods
function getUsers() {
  return readJson(USERS_FILE, []);
}

function findUserByUsername(username) {
  const users = getUsers();
  return users.find(u => u.username.toLowerCase() === username.toLowerCase().trim());
}

function findUserById(id) {
  const users = getUsers();
  return users.find(u => u.id === id);
}

// Audit Logs methods
function addAuditLog({ userId, username, role, action, details = {}, ip = '127.0.0.1', status = 'SUCCESS' }) {
  const logs = readJson(AUDIT_FILE, []);
  
  // Clean sensitive details
  const safeDetails = { ...details };
  delete safeDetails.password;
  delete safeDetails.passwordEnc;
  delete safeDetails.token;
  delete safeDetails.jwt;

  const entry = {
    id: `log_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`,
    timestamp: new Date().toISOString(),
    userId: userId || 'anonymous',
    username: username || 'System',
    role: role || 'GUEST',
    action,
    details: safeDetails,
    ipAddress: ip,
    status
  };

  logs.unshift(entry); // newest first
  if (logs.length > 2000) {
    logs.length = 2000; // Cap log history
  }
  writeJson(AUDIT_FILE, logs);
  return entry;
}

function getAuditLogs(limit = 100, filterAction = null) {
  const logs = readJson(AUDIT_FILE, []);
  let filtered = logs;
  if (filterAction) {
    filtered = filtered.filter(l => l.action === filterAction);
  }
  return filtered.slice(0, limit);
}

// Cache methods
function getCache(key) {
  const cache = readJson(CACHE_FILE, {});
  return cache[key];
}

function setCache(key, value) {
  const cache = readJson(CACHE_FILE, {});
  cache[key] = value;
  cache.lastUpdated = cache.lastUpdated || {};
  cache.lastUpdated[key] = new Date().toISOString();
  writeJson(CACHE_FILE, cache);
}

initDatabase();

module.exports = {
  initDatabase,
  getSettings,
  getSafeSettings,
  updateSettings,
  getUsers,
  findUserByUsername,
  findUserById,
  addAuditLog,
  getAuditLogs,
  getCache,
  setCache
};
