const path = require('path');
const crypto = require('crypto');
require('dotenv').config({ path: path.join(__dirname, '../../../.env') });

const ENCRYPTION_KEY = process.env.APP_SECRET_KEY 
  ? crypto.createHash('sha256').update(process.env.APP_SECRET_KEY).digest()
  : crypto.createHash('sha256').update('billel-attendance-super-secure-key-2026').digest();

const IV_LENGTH = 16;

/**
 * Encrypt plain text using AES-256-CBC
 */
function encrypt(text) {
  if (!text) return '';
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

/**
 * Decrypt text using AES-256-CBC
 */
function decrypt(text) {
  if (!text || !text.includes(':')) return text || '';
  try {
    const parts = text.split(':');
    const iv = Buffer.from(parts.shift(), 'hex');
    const encryptedText = Buffer.from(parts.join(':'), 'hex');
    const decipher = crypto.createDecipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
    let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (err) {
    console.error('Decryption error:', err.message);
    return '';
  }
}

module.exports = {
  PORT: process.env.PORT || 3000,
  JWT_SECRET: process.env.JWT_SECRET || 'billel-jwt-attendance-auth-secret-2026',
  JWT_EXPIRES_IN: '24h',
  DATA_DIR: path.join(__dirname, '../../../data'),
  
  // Default ZKBioTime settings
  DEFAULT_ZKBIO_URL: process.env.ZKBIO_BASE_URL || 'http://105.96.0.211:8080',
  DEFAULT_ZKBIO_USER: process.env.ZKBIO_USERNAME || '',
  DEFAULT_ZKBIO_PASS: process.env.ZKBIO_PASSWORD || '',
  
  // Overtime & Attendance Calculation defaults
  DEFAULT_OVERTIME_START: '15:30',
  DEFAULT_STANDARD_START: '08:00',
  DEFAULT_STANDARD_END: '16:30',
  DEFAULT_DUPLICATE_WINDOW_SEC: 120, // 2 minutes
  DEFAULT_ROUNDING_MINUTES: 0, // 0 = exact minutes
  
  encrypt,
  decrypt
};
