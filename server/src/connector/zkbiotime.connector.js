const http = require('http');
const https = require('https');
const { URL } = require('url');

class ReadOnlySecurityViolation extends Error {
  constructor(message) {
    super(`[CRITICAL SECURITY VIOLATION] ${message}`);
    this.name = 'ReadOnlySecurityViolation';
  }
}

class ZKBioTimeConnector {
  constructor(config = {}) {
    this.serverUrl = config.serverUrl ? config.serverUrl.replace(/\/+$/, '') : 'http://105.96.0.211:8080';
    this.username = config.username || 'attendance_readonly';
    this.password = config.password || '';
    this.sessionCookies = [];
    this.csrfToken = '';
    this.sessionExpiresAt = 0;
    this.timeout = config.timeout || 10000;
  }

  updateCredentials(serverUrl, username, password) {
    this.serverUrl = serverUrl ? serverUrl.replace(/\/+$/, '') : this.serverUrl;
    this.username = username !== undefined ? username : this.username;
    if (password !== undefined) {
      this.password = password;
    }
    this.sessionCookies = [];
    this.csrfToken = '';
    this.sessionExpiresAt = 0;
  }

  /**
   * Internal HTTP request engine enforcing 100% READ-ONLY policy
   */
  async _rawRequest(pathname, options = {}) {
    const method = (options.method || 'GET').toUpperCase();
    
    // HARD ENFORCEMENT: Only POST to login is allowed. All attendance queries MUST be GET.
    const isLoginEndpoint = pathname === '/login/' || pathname.startsWith('/login');
    if (method !== 'GET') {
      if (method === 'POST' && isLoginEndpoint) {
        // Allowed only for authentication session creation
      } else {
        throw new ReadOnlySecurityViolation(
          `Operation '${method}' on '${pathname}' is STRICTLY FORBIDDEN. BILLEL ATTENDANCE is 100% READ-ONLY.`
        );
      }
    }

    const fullUrlStr = `${this.serverUrl}${pathname.startsWith('/') ? '' : '/'}${pathname}`;
    const parsedUrl = new URL(fullUrlStr);
    const isHttps = parsedUrl.protocol === 'https:';
    const client = isHttps ? https : http;

    const headers = {
      'Accept': 'application/json, text/plain, */*',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      ...(options.headers || {})
    };

    let postData = null;
    if (options.body) {
      postData = options.body;
      if (typeof postData === 'object') {
        postData = JSON.stringify(postData);
        headers['Content-Type'] = 'application/json';
      }
      headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const requestOptions = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || (isHttps ? 443 : 80),
      path: `${parsedUrl.pathname}${parsedUrl.search}`,
      method: method,
      headers: headers,
      timeout: this.timeout
    };

    return new Promise((resolve, reject) => {
      const req = client.request(requestOptions, (res) => {
        let responseData = '';
        res.on('data', (chunk) => {
          responseData += chunk;
        });
        res.on('end', () => {
          let parsedBody = null;
          try {
            parsedBody = responseData ? JSON.parse(responseData) : null;
          } catch (e) {
            parsedBody = responseData;
          }

          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: parsedBody,
            rawText: responseData
          });
        });
      });

      req.on('timeout', () => {
        req.destroy();
        const err = new Error(`Délai d'attente dépassé lors de la communication avec ZKBioTime (${this.timeout}ms)`);
        err.code = 'ETIMEDOUT';
        reject(err);
      });

      req.on('error', (err) => {
        reject(err);
      });

      if (postData) {
        req.write(postData);
      }
      req.end();
    });
  }

  /**
   * Authenticate session against ZKBioTime 9.0.3 Web Application
   */
  async authenticate(forceRefresh = false) {
    if (!forceRefresh && this.sessionCookies.length > 0 && Date.now() < this.sessionExpiresAt) {
      return { cookies: this.sessionCookies, csrfToken: this.csrfToken };
    }

    if (!this.username) {
      throw new Error('Identifiant ZKBioTime non configuré');
    }

    // Step 1: GET /login/ to retrieve initial CSRF token & cookie
    const loginPage = await this._rawRequest('/login/', { method: 'GET' });
    const initialCookies = loginPage.headers['set-cookie'] || [];
    
    let csrfToken = '';
    const csrfCookie = initialCookies.find(c => c.startsWith('csrftoken='));
    if (csrfCookie) {
      csrfToken = csrfCookie.split(';')[0].split('=')[1];
    }

    // Step 2: POST /login/ with credentials
    const formBody = `username=${encodeURIComponent(this.username)}&password=${encodeURIComponent(this.password || '')}&csrfmiddlewaretoken=${encodeURIComponent(csrfToken)}`;
    
    const cookieHeader = initialCookies.map(c => c.split(';')[0]).join('; ');
    const loginRes = await this._rawRequest('/login/', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Cookie': cookieHeader,
        'Referer': `${this.serverUrl}/login/`
      },
      body: formBody
    });

    const postCookies = loginRes.headers['set-cookie'] || [];
    const allCookies = [...initialCookies, ...postCookies];

    // Check if sessionid cookie was provided
    const sessionCookie = allCookies.find(c => c.startsWith('sessionid='));
    if (!sessionCookie) {
      // Check if invalid credentials error was on page
      if (typeof loginRes.rawText === 'string' && (loginRes.rawText.includes('incorrect') || loginRes.rawText.includes('invalide') || loginRes.rawText.includes('error'))) {
        throw new Error('Identifiant ou mot de passe ZKBioTime incorrect.');
      }
      throw new Error('Échec d\'authentification ZKBioTime : session non créée.');
    }

    this.sessionCookies = allCookies;
    this.csrfToken = csrfToken;
    this.sessionExpiresAt = Date.now() + (4 * 60 * 60 * 1000); // 4 hours session validity

    return { cookies: this.sessionCookies, csrfToken: this.csrfToken };
  }

  /**
   * Execute authenticated GET request
   */
  async get(pathname, params = {}) {
    let auth = await this.authenticate();

    const queryParams = new URLSearchParams();
    for (const [k, v] of Object.entries(params)) {
      if (v !== undefined && v !== null && v !== '') {
        queryParams.append(k, v);
      }
    }

    const queryString = queryParams.toString();
    const fullPath = queryString ? `${pathname}?${queryString}` : pathname;
    const cookieHeader = auth.cookies.map(c => c.split(';')[0]).join('; ');

    let res = await this._rawRequest(fullPath, {
      method: 'GET',
      headers: {
        'Cookie': cookieHeader,
        'X-CSRFToken': auth.csrfToken,
        'X-Requested-With': 'XMLHttpRequest'
      }
    });

    // If session expired or returned 401/302 to login, re-authenticate once
    if (res.statusCode === 401 || res.statusCode === 403 || res.statusCode === 302 || (typeof res.data === 'string' && res.data.includes('/login/'))) {
      this.sessionCookies = [];
      auth = await this.authenticate(true);
      const newCookieHeader = auth.cookies.map(c => c.split(';')[0]).join('; ');
      res = await this._rawRequest(fullPath, {
        method: 'GET',
        headers: {
          'Cookie': newCookieHeader,
          'X-CSRFToken': auth.csrfToken,
          'X-Requested-With': 'XMLHttpRequest'
        }
      });
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.data;
    }

    throw new Error(`Erreur ZKBioTime (HTTP ${res.statusCode})`);
  }

  /**
   * Test connection to ZKBioTime server
   */
  async testConnection(serverUrl, username, password) {
    const tempConnector = new ZKBioTimeConnector({
      serverUrl: serverUrl || this.serverUrl,
      username: username || this.username,
      password: password !== undefined ? password : this.password,
      timeout: 8000
    });

    try {
      await tempConnector.authenticate(true);
      
      // Test read permissions by querying employees count
      const testRes = await tempConnector.get('/personnel/api/employees/', { page_size: 1 });
      const empCount = testRes?.count !== undefined ? testRes.count : 'OK';

      return {
        success: true,
        message: `Connexion à ZKBioTime 9.0.3 réussie avec succès ! (Total employés: ${empCount}) [100% READ-ONLY]`,
        serverUrl: tempConnector.serverUrl,
        empCount: empCount,
        reachable: true
      };
    } catch (err) {
      return {
        success: false,
        message: err.message || 'Échec de connexion au serveur ZKBioTime',
        serverUrl: tempConnector.serverUrl,
        reachable: err.code !== 'ETIMEDOUT' && err.code !== 'ECONNREFUSED',
        errorDetails: err.message
      };
    }
  }

  /**
   * Get employee by matricule (emp_code)
   */
  async getEmployee(empCode) {
    if (!empCode) return null;
    const cleanCode = String(empCode).trim();

    try {
      const res = await this.get('/personnel/api/employees/', {
        emp_code: cleanCode,
        page_size: 10
      });

      const list = res?.data || res?.results || (Array.isArray(res) ? res : []);
      const emp = list.find(e => String(e.emp_code).trim() === cleanCode) || list[0];
      
      if (!emp) return null;

      // Extract department name safely
      let deptName = 'N/A';
      if (typeof emp.department === 'string') {
        deptName = emp.department;
      } else if (emp.department && emp.department.dept_name) {
        deptName = emp.department.dept_name;
      } else if (emp.dept_name) {
        deptName = emp.dept_name;
      }

      // Extract position / title safely
      let posName = 'Collaborateur';
      if (typeof emp.position === 'string' && emp.position) {
        posName = emp.position;
      } else if (emp.position && emp.position.position_name) {
        posName = emp.position.position_name;
      } else if (emp.job_title) {
        posName = emp.job_title;
      }

      return {
        id: emp.id,
        empCode: String(emp.emp_code),
        firstName: emp.first_name || '',
        lastName: emp.last_name || '',
        fullName: emp.full_name || `${emp.first_name || ''} ${emp.last_name || ''}`.trim() || `Employé ${emp.emp_code}`,
        department: deptName,
        position: posName,
        hireDate: emp.hire_date || null,
        avatar: emp.photo || null,
        raw: emp
      };
    } catch (err) {
      console.warn(`[Connector] getEmployee failed for ${cleanCode}: ${err.message}`);
      throw err;
    }
  }

  /**
   * Get punch transactions for an employee in a date range
   */
  async getTransactions(empCode, startDate, endDate) {
    if (!empCode) return [];
    const cleanCode = String(empCode).trim();

    const startFormatted = startDate ? `${startDate} 00:00:00` : '';
    const endFormatted = endDate ? `${endDate} 23:59:59` : '';

    try {
      const res = await this.get('/iclock/api/transactions/', {
        emp_code: cleanCode,
        start_time: startFormatted,
        end_time: endFormatted,
        page_size: 1000
      });

      const rawList = res?.data || res?.results || (Array.isArray(res) ? res : []);
      
      return rawList.map(t => ({
        id: t.id,
        empCode: String(t.emp_code),
        punchTime: t.punch_time,
        punchState: String(t.punch_state),
        punchStateDisplay: t.punch_state_display || '',
        verifyType: t.verify_type,
        verifyTypeDisplay: t.verify_type_display || '',
        terminalSn: t.terminal_sn,
        terminalAlias: t.terminal_alias || t.area_alias || 'Terminal ZKTeco',
        raw: t
      })).sort((a, b) => new Date(a.punchTime) - new Date(b.punchTime));
    } catch (err) {
      console.warn(`[Connector] getTransactions failed for ${cleanCode}: ${err.message}`);
      throw err;
    }
  }
}

module.exports = {
  ZKBioTimeConnector,
  ReadOnlySecurityViolation
};
