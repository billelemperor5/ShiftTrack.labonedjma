/**
 * ShiftTrack LA BONEDJIMA - Firebase Firestore Sync Daemon
 * Synchronizes local ZKBioTime 9.0.3 data directly into Google Firebase Firestore.
 */

const https = require('https');
const path = require('path');
const attendanceService = require('./src/services/attendance.service');
const { ZKBioTimeConnector } = require('./src/connector/zkbiotime.connector');
const { getSettings } = require('./src/database/store');

const PROJECT_ID = 'shifttrack-labonedjma';
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

/**
 * Encode Javascript Object to Firestore REST API fields structure
 */
function encodeFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    const enc = encodeValue(value);
    if (enc !== undefined) {
      fields[key] = enc;
    }
  }
  return { fields };
}

function encodeValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: String(val) };
    return { doubleValue: val };
  }
  if (typeof val === 'string') return { stringValue: val };
  if (Array.isArray(val)) {
    return {
      arrayValue: {
        values: val.map(item => encodeValue(item) || { nullValue: null })
      }
    };
  }
  if (typeof val === 'object') {
    const inner = {};
    for (const [k, v] of Object.entries(val)) {
      const enc = encodeValue(v);
      if (enc !== undefined) inner[k] = enc;
    }
    return { mapValue: { fields: inner } };
  }
  return { stringValue: String(val) };
}

/**
 * Patch a document in Firebase Firestore
 */
function writeFirestoreDoc(collection, docId, data) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(encodeFirestoreFields(data));
    const urlStr = `${FIRESTORE_BASE}/${collection}/${encodeURIComponent(docId)}`;
    const url = new URL(urlStr);

    const req = https.request({
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      },
      timeout: 10000
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(true);
        } else {
          console.warn(`[Firestore] Failed to write ${collection}/${docId} (HTTP ${res.statusCode}): ${body.substring(0, 100)}`);
          resolve(false);
        }
      });
    });

    req.on('error', (err) => {
      console.error(`[Firestore] Network error writing ${collection}/${docId}:`, err.message);
      resolve(false);
    });

    req.on('timeout', () => {
      req.destroy();
      console.error(`[Firestore] Timeout writing ${collection}/${docId}`);
      resolve(false);
    });

    req.write(payload);
    req.end();
  });
}

/**
 * Main Sync Function
 */
async function syncAllToFirebase() {
  console.log(`\n======================================================`);
  console.log(`🚀 ShiftTrack - Synchronisation vers Firebase Firestore`);
  console.log(`🕒 Heure: ${new Date().toLocaleString()}`);
  console.log(`🌐 Projet: ${PROJECT_ID}`);
  console.log(`======================================================`);

  const settings = getSettings();
  const serverUrl = settings.serverUrl || process.env.ZKBIO_BASE_URL || 'http://105.96.0.211:8080';
  const username = settings.username || process.env.ZKBIO_USERNAME || '';
  const password = settings.password || process.env.ZKBIO_PASSWORD || '';

  const connector = new ZKBioTimeConnector({ serverUrl, username, password });

  try {
    // 1. Fetch Employees List
    console.log(`📡 Connexion au serveur ZKBioTime (${serverUrl})...`);
    let employees = [];
    try {
      const res = await connector.get('/personnel/api/employees/', { page_size: 100 });
      employees = res?.data || res?.results || (Array.isArray(res) ? res : []);
      console.log(`✅ ${employees.length} employés trouvés sur ZKBioTime.`);
    } catch (e) {
      console.warn(`⚠️ Impossible de récupérer la liste globale: ${e.message}`);
    }

    // Default dates: current month
    const now = new Date();
    const endDate = now.toISOString().split('T')[0];
    const startDateObj = new Date(now.getFullYear(), now.getMonth(), 1);
    const startDate = startDateObj.toISOString().split('T')[0];

    // If employees list is available, sync each
    let syncedCount = 0;
    for (const emp of employees) {
      const cleanCode = String(emp.emp_code || emp.empCode || '').trim();
      if (!cleanCode) continue;

      try {
        console.log(`⏳ Synchronisation employé [${cleanCode}]...`);
        const report = await attendanceService.getEmployeeAttendance(cleanCode, startDate, endDate, true);

        if (report && report.employee) {
          // 1. Save Employee document
          await writeFirestoreDoc('employees', cleanCode, {
            id: report.employee.id || 0,
            empCode: cleanCode,
            firstName: report.employee.firstName || '',
            lastName: report.employee.lastName || '',
            fullName: report.employee.fullName || `Employé ${cleanCode}`,
            department: report.employee.department || 'Direction',
            position: report.employee.position || 'Collaborateur',
            avatar: report.employee.avatar || '',
            updatedAt: new Date().toISOString()
          });

          // 2. Save Attendance document
          await writeFirestoreDoc('attendance', cleanCode, {
            empCode: cleanCode,
            employee: report.employee,
            days: report.days || [],
            summary: report.summary || {},
            period: { startDate, endDate },
            updatedAt: new Date().toISOString()
          });

          syncedCount++;
          console.log(`✨ [${cleanCode}] ${report.employee.fullName} synchronisé avec succès !`);
        }
      } catch (err) {
        console.warn(`⚠️ Erreur pour [${cleanCode}]: ${err.message}`);
      }
    }

    // 3. Update system health
    await writeFirestoreDoc('system_status', 'health', {
      status: 'ONLINE',
      lastSyncTime: new Date().toISOString(),
      employeesSynced: syncedCount,
      serverUrl: serverUrl
    });

    console.log(`\n🎉 Synchronisation terminée ! ${syncedCount} employés mis à jour sur Firebase.`);
  } catch (err) {
    console.error(`❌ Erreur globale de synchronisation:`, err.message);
  }
}

// Check for --watch flag
if (process.argv.includes('--watch')) {
  console.log(`🔄 Mode surveillance activé: synchronisation toutes les 2 minutes.`);
  syncAllToFirebase();
  setInterval(syncAllToFirebase, 2 * 60 * 1000);
} else {
  syncAllToFirebase();
}

module.exports = { syncAllToFirebase, writeFirestoreDoc };
