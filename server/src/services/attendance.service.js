const { ZKBioTimeConnector } = require('../connector/zkbiotime.connector');
const { getSettings, updateSettings, getCache, setCache } = require('../database/store');
const { processAttendanceRange } = require('../calculations/engine');

class AttendanceService {
  constructor() {
    this.connector = new ZKBioTimeConnector();
  }

  getConnectorInstance() {
    const settings = getSettings();
    this.connector.updateCredentials(settings.serverUrl, settings.username, settings.password);
    return this.connector;
  }

  /**
   * Search employee and retrieve attendance directly from ZKBioTime (100% REAL DATA)
   */
  async getEmployeeAttendance(empCode, startDate, endDate, forceSync = false) {
    if (!empCode) {
      throw new Error('Le matricule de l\'employé est obligatoire');
    }

    const cleanCode = String(empCode).trim();
    const settings = getSettings();
    const connector = this.getConnectorInstance();

    // Check if credentials are configured
    if (!settings.username || !settings.password) {
      throw new Error(
        'Veuillez configurer les identifiants de connexion ZKBioTime (Nom d\'utilisateur et Mot de passe) dans les Paramètres.'
      );
    }

    const cacheKey = `att_${cleanCode}_${startDate}_${endDate}`;
    if (!forceSync) {
      const cached = getCache(cacheKey);
      if (cached) {
        return { ...cached, fromCache: true };
      }
    }

    // 1. Fetch Real Employee from ZKBioTime
    let employee = null;
    try {
      employee = await connector.getEmployee(cleanCode);
    } catch (err) {
      throw new Error(`Erreur lors de la communication avec ZKBioTime : ${err.message}`);
    }

    if (!employee) {
      throw new Error(`Aucun employé trouvé avec le matricule '${cleanCode}' sur le serveur ZKBioTime.`);
    }

    // 2. Fetch Real Transactions from ZKBioTime
    let rawTransactions = [];
    try {
      rawTransactions = await connector.getTransactions(cleanCode, startDate, endDate);
    } catch (err) {
      throw new Error(`Erreur lors de la récupération des pointages ZKBioTime : ${err.message}`);
    }

    // 3. Run Calculation Engine on real transactions
    const calculationResult = processAttendanceRange(startDate, endDate, rawTransactions, {
      standardStartTime: settings.standardStartTime || '08:00',
      duplicateWindowSec: settings.duplicateWindowSec || 120
    });

    const finalResult = {
      employee,
      dataSource: `ZKBioTime 9.0.3 (${settings.serverUrl})`,
      isLive: true,
      lastSyncTime: new Date().toISOString(),
      serverUrl: settings.serverUrl,
      ...calculationResult,
      rawTransactionsCount: rawTransactions.length
    };

    // Cache the result for performance
    setCache(cacheKey, finalResult);

    // Update settings lastSyncTime
    updateSettings({ lastSyncTime: new Date().toISOString() });

    return finalResult;
  }
}

module.exports = new AttendanceService();
