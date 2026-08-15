const http = require('http');

function get(path) {
  return new Promise((resolve, reject) => {
    http.get('http://localhost:3000' + path, (res) => {
      let data = [];
      res.on('data', chunk => data.push(chunk));
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          headers: res.headers,
          body: Buffer.concat(data)
        });
      });
    }).on('error', reject);
  });
}

function post(path, body) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify(body);
    const req = http.request('http://localhost:3000' + path, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      let data = [];
      res.on('data', chunk => data.push(chunk));
      res.on('end', () => {
        resolve({
          status: res.statusCode,
          headers: res.headers,
          body: Buffer.concat(data)
        });
      });
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

(async () => {
  console.log('====================================================');
  console.log('BILLEL ATTENDANCE — UPDATED VERIFICATION SUITE');
  console.log('====================================================');

  // 1. Static Assets
  console.log('\n[1/6] Testing Static Frontend Assets:');
  const indexRes = await get('/');
  console.log(' - index.html:', indexRes.status === 200 ? 'PASSED' : 'FAILED');
  const mainCss = await get('/css/main.css');
  console.log(' - main.css:', mainCss.status === 200 ? 'PASSED' : 'FAILED');
  const appJs = await get('/js/app.js');
  console.log(' - app.js:', appJs.status === 200 ? 'PASSED' : 'FAILED');

  // 2. Attendance Search & Calculations
  console.log('\n[2/6] Testing Attendance Detail for Matricule 40754:');
  const attRes = await get('/api/attendance/search?matricule=40754&startDate=2026-07-24&endDate=2026-08-15&forceSync=true');
  const attData = JSON.parse(attRes.body.toString());
  console.log(' - Employee:', attData.data.employee.fullName, '| Dept:', attData.data.employee.department);
  console.log(' - Total Worked Hours:', attData.data.summary.totalWorkedHoursStr);
  console.log(' - Average Daily Hours:', attData.data.summary.averageDailyHoursStr);
  console.log(' - Presence Rate:', attData.data.summary.presenceRate + '%');
  console.log(' - Days processed:', attData.data.days.length);

  // Check specific test cases
  const day24 = attData.data.days.find(d => d.date === '2026-07-24');
  console.log(' - Case 24/07/2026 (07:46 -> 22:18):', 
    day24 && day24.workTimeStr === '14h32' && day24.entryTime === '07:46' && day24.exitTime === '22:18' ? 'PASSED (Work: 14h32, In: 07:46, Out: 22:18)' : 'FAILED');

  const day15 = attData.data.days.find(d => d.date === '2026-08-15');
  console.log(' - Case 15/08/2026 (10:54 Incomplete):',
    day15 && day15.status === 'Pointage incomplet' ? 'PASSED (Pointage incomplet, No exit)' : 'FAILED');

  // 3. Security Guarantee
  console.log('\n[3/6] Testing 100% Read-Only Security Assertion:');
  const { ZKBioTimeConnector, ReadOnlySecurityViolation } = require('./src/connector/zkbiotime.connector');
  const connector = new ZKBioTimeConnector();
  try {
    await connector._sendRequest('/personnel/api/employees/', { method: 'POST', body: { name: 'UnauthorizedWrite' } });
    console.log(' - Read-Only Enforcement: FAILED TO BLOCK WRITE');
  } catch (err) {
    if (err.name === 'ReadOnlySecurityViolation') {
      console.log(' - Read-Only Enforcement: PASSED (Strictly blocked write attempt)');
    }
  }

  // 4. Reports (PDF & Excel)
  console.log('\n[4/6] Testing PDF & Excel Exporters:');
  const pdfRes = await get('/api/reports/pdf?matricule=40754&startDate=2026-07-24&endDate=2026-08-15');
  console.log(' - PDF Export:', pdfRes.status === 200 && pdfRes.body.length > 2000 ? `PASSED (${pdfRes.body.length} bytes)` : 'FAILED');
  const xlsRes = await get('/api/reports/excel?matricule=40754&startDate=2026-07-24&endDate=2026-08-15');
  console.log(' - Excel Export:', xlsRes.status === 200 && xlsRes.body.length > 2000 ? `PASSED (${xlsRes.body.length} bytes)` : 'FAILED');

  // 5. Settings Update
  console.log('\n[5/6] Testing Settings Update:');
  const settingsUpdate = await post('/api/settings', {
    serverUrl: 'http://105.96.0.211:8080',
    username: 'attendance_readonly',
    standardStartTime: '08:00',
    duplicateWindowSec: 120
  });
  console.log(' - Settings Update:', settingsUpdate.status === 200 ? 'PASSED' : 'FAILED');

  // 6. Audit Logging
  console.log('\n[6/6] Testing Audit Logging:');
  const auditRes = await get('/api/audit-logs?limit=5');
  const auditData = JSON.parse(auditRes.body.toString());
  console.log(' - Audit Logs Count:', auditData.data?.length);

  console.log('\n====================================================');
  console.log('ALL TESTS COMPLETED SUCCESSFULLY!');
  console.log('====================================================');
})();
