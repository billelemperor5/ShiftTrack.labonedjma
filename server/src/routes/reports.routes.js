const express = require('express');
const router = express.Router();
const attendanceService = require('../services/attendance.service');
const { generateAttendancePDF } = require('../reports/pdf.report');
const { generateAttendanceExcel } = require('../reports/excel.report');
const { logAction } = require('../services/audit.service');

// Export PDF Report
router.get('/pdf', async (req, res) => {
  try {
    const { matricule, startDate, endDate } = req.query;
    if (!matricule) {
      return res.status(400).send('Matricule requis');
    }

    const data = await attendanceService.getEmployeeAttendance(matricule, startDate, endDate);
    const pdfBuffer = await generateAttendancePDF(data);

    logAction(req, 'EXPORT_PDF', {
      matricule,
      employeeName: data.employee.fullName,
      startDate,
      endDate
    });

    const filename = `Billel_Attendance_${data.employee.empCode}_${data.period.startDate}_to_${data.period.endDate}.pdf`;

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    return res.send(pdfBuffer);
  } catch (err) {
    console.error('PDF generation error:', err);
    logAction(req, 'EXPORT_PDF_ERROR', { error: err.message }, 'FAILURE');
    return res.status(500).send('Erreur lors de la génération du rapport PDF');
  }
});

// Export Excel (XLSX) Report
router.get('/excel', async (req, res) => {
  try {
    const { matricule, startDate, endDate } = req.query;
    if (!matricule) {
      return res.status(400).send('Matricule requis');
    }

    const data = await attendanceService.getEmployeeAttendance(matricule, startDate, endDate);
    const excelBuffer = await generateAttendanceExcel(data);

    logAction(req, 'EXPORT_EXCEL', {
      matricule,
      employeeName: data.employee.fullName,
      startDate,
      endDate
    });

    const filename = `Billel_Attendance_${data.employee.empCode}_${data.period.startDate}_to_${data.period.endDate}.xlsx`;

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    return res.send(excelBuffer);
  } catch (err) {
    console.error('Excel generation error:', err);
    logAction(req, 'EXPORT_EXCEL_ERROR', { error: err.message }, 'FAILURE');
    return res.status(500).send('Erreur lors de la génération du fichier Excel');
  }
});

module.exports = router;
