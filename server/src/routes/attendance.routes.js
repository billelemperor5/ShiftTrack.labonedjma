const express = require('express');
const router = express.Router();
const attendanceService = require('../services/attendance.service');
const { logAction } = require('../services/audit.service');

router.get('/search', async (req, res) => {
  try {
    const { matricule, startDate, endDate, forceSync } = req.query;

    if (!matricule) {
      return res.status(400).json({
        success: false,
        error: 'Veuillez saisir un matricule valide.'
      });
    }

    // Default dates if missing: current month or last 30 days
    const now = new Date();
    const end = endDate || now.toISOString().split('T')[0];
    const defaultStart = new Date(now);
    defaultStart.setDate(defaultStart.getDate() - 25);
    const start = startDate || defaultStart.toISOString().split('T')[0];

    const result = await attendanceService.getEmployeeAttendance(
      matricule,
      start,
      end,
      forceSync === 'true' || forceSync === true
    );

    logAction(req, 'SEARCH_EMPLOYEE', {
      matricule,
      startDate: start,
      endDate: end,
      employeeName: result.employee?.fullName,
      daysFound: result.days?.length
    });

    return res.json({
      success: true,
      data: result
    });
  } catch (err) {
    console.error('Attendance search error:', err);
    logAction(req, 'SEARCH_ERROR', { error: err.message }, 'FAILURE');

    return res.status(500).json({
      success: false,
      error: err.message || 'Erreur lors de la récupération des données de pointage'
    });
  }
});

router.post('/sync', async (req, res) => {
  try {
    const { matricule, startDate, endDate } = req.body;
    if (!matricule) {
      return res.status(400).json({ success: false, error: 'Matricule requis' });
    }

    const result = await attendanceService.getEmployeeAttendance(
      matricule,
      startDate,
      endDate,
      true // forceSync = true
    );

    logAction(req, 'SYNC_ATTENDANCE', {
      matricule,
      startDate,
      endDate,
      lastSyncTime: result.lastSyncTime
    });

    return res.json({
      success: true,
      message: 'Données synchronisées avec succès depuis ZKBioTime',
      data: result
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      error: err.message || 'Échec de synchronisation ZKBioTime'
    });
  }
});

module.exports = router;
