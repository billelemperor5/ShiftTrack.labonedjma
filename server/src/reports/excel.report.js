const ExcelJS = require('exceljs');

async function generateAttendanceExcel(data) {
  const { employee, period, summary, days } = data;
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'BILLEL ATTENDANCE System';
  workbook.created = new Date();

  const sheet = workbook.addWorksheet('Détail du Pointage', {
    pageSetup: { orientation: 'landscape', paperSize: 9 }
  });

  // Color Palette Constants
  const HEADER_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1E293B' } };
  const BRAND_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF2563EB' } };
  const ACCENT_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF1F5F9' } };
  const WARNING_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFEF3C7' } };
  const DANGER_FILL = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFEE2E2' } };

  // Title Row
  sheet.mergeCells('A1:H1');
  const titleCell = sheet.getCell('A1');
  titleCell.value = 'BILLEL ATTENDANCE — RAPPORT DÉTAILLÉ DU POINTAGE';
  titleCell.font = { name: 'Calibri', size: 16, bold: true, color: { argb: 'FFFFFFFF' } };
  titleCell.fill = BRAND_FILL;
  titleCell.alignment = { horizontal: 'center', vertical: 'middle' };
  sheet.getRow(1).height = 36;

  // Subtitle / Info
  sheet.mergeCells('A2:H2');
  const subtitleCell = sheet.getCell('A2');
  subtitleCell.value = `ZKTeco ZKBioTime 9.0.3 • Généré le ${new Date().toLocaleString('fr-FR')}`;
  subtitleCell.font = { name: 'Calibri', size: 10, italic: true, color: { argb: 'FF64748B' } };
  subtitleCell.alignment = { horizontal: 'center', vertical: 'middle' };
  sheet.getRow(2).height = 20;

  sheet.addRow([]); // Blank line

  // Employee Information Block
  sheet.mergeCells('A4:C4');
  sheet.getCell('A4').value = `Employé : ${employee.fullName.toUpperCase()} (Matricule: ${employee.empCode})`;
  sheet.getCell('A4').font = { bold: true, size: 11, color: { argb: 'FF1E293B' } };

  sheet.mergeCells('D4:H4');
  sheet.getCell('D4').value = `Département : ${employee.department} | Période : ${period.startDateFR} → ${period.endDateFR}`;
  sheet.getCell('D4').font = { bold: true, size: 11, color: { argb: 'FF1E293B' } };
  sheet.getRow(4).height = 24;

  // KPI Summary Row
  sheet.mergeCells('A5:B5');
  sheet.getCell('A5').value = `Jours travaillés: ${summary.daysWorked} / ${summary.totalDaysInRange}`;
  sheet.getCell('A5').fill = ACCENT_FILL;
  sheet.getCell('A5').font = { bold: true };
  sheet.getCell('A5').alignment = { horizontal: 'center' };

  sheet.mergeCells('C5:D5');
  sheet.getCell('C5').value = `Heures Travaillées: ${summary.totalWorkedHoursStr} (Moyenne: ${summary.averageDailyHoursStr}/j)`;
  sheet.getCell('C5').fill = ACCENT_FILL;
  sheet.getCell('C5').font = { bold: true, color: { argb: 'FF0F766E' } };
  sheet.getCell('C5').alignment = { horizontal: 'center' };

  sheet.mergeCells('E5:F5');
  sheet.getCell('E5').value = `Retards: ${summary.totalDelaysCount} (${summary.totalDelayHoursStr})`;
  sheet.getCell('E5').fill = WARNING_FILL;
  sheet.getCell('E5').font = { bold: true, color: { argb: 'FFB45309' } };
  sheet.getCell('E5').alignment = { horizontal: 'center' };

  sheet.getCell('G5').value = `Absences: ${summary.totalAbsencesCount}`;
  sheet.getCell('G5').fill = DANGER_FILL;
  sheet.getCell('G5').font = { bold: true, color: { argb: 'FFB91C1C' } };
  sheet.getCell('G5').alignment = { horizontal: 'center' };

  sheet.getCell('H5').value = `Anomalies: ${summary.totalAnomaliesCount}`;
  sheet.getCell('H5').fill = DANGER_FILL;
  sheet.getCell('H5').font = { bold: true, color: { argb: 'FFB91C1C' } };
  sheet.getCell('H5').alignment = { horizontal: 'center' };

  sheet.getRow(5).height = 26;
  sheet.addRow([]); // Blank line

  // Table Headers
  const tableHeaders = [
    'Date',
    'Jour',
    'Entrée (1ère)',
    'Sortie (Dernière)',
    'Temps Travaillé',
    'Retard',
    'Statut',
    'Observations / Anomalies'
  ];

  const headerRow = sheet.addRow(tableHeaders);
  headerRow.height = 28;
  headerRow.eachCell((cell) => {
    cell.fill = HEADER_FILL;
    cell.font = { name: 'Calibri', bold: true, color: { argb: 'FFFFFFFF' } };
    cell.alignment = { horizontal: 'center', vertical: 'middle' };
    cell.border = {
      top: { style: 'thin', color: { argb: 'FFCBD5E1' } },
      left: { style: 'thin', color: { argb: 'FFCBD5E1' } },
      bottom: { style: 'medium', color: { argb: 'FF0F172A' } },
      right: { style: 'thin', color: { argb: 'FFCBD5E1' } }
    };
  });

  // Table Rows
  days.forEach((d) => {
    const anomaliesText = d.anomalies.map(a => a.label).join('; ');
    const row = sheet.addRow([
      d.dateFR,
      d.dayName,
      d.entryTime,
      d.exitTime,
      d.workTimeStr,
      d.delayStr,
      d.status,
      anomaliesText || (d.isWeekend ? 'Week-end' : '')
    ]);

    row.height = 22;
    row.eachCell((cell, colNumber) => {
      cell.border = {
        top: { style: 'thin', color: { argb: 'FFE2E8F0' } },
        left: { style: 'thin', color: { argb: 'FFE2E8F0' } },
        bottom: { style: 'thin', color: { argb: 'FFE2E8F0' } },
        right: { style: 'thin', color: { argb: 'FFE2E8F0' } }
      };
      cell.alignment = { vertical: 'middle', horizontal: colNumber === 8 ? 'left' : 'center' };

      if (d.anomalies.length > 0) {
        if (colNumber === 7 || colNumber === 8) {
          cell.fill = WARNING_FILL;
          cell.font = { color: { argb: 'FF92400E' }, bold: true };
        }
      }
    });
  });

  // Auto-fit column widths
  sheet.columns = [
    { width: 15 }, // Date
    { width: 15 }, // Jour
    { width: 18 }, // Entree
    { width: 18 }, // Sortie
    { width: 20 }, // Temps Travaille
    { width: 16 }, // Retard
    { width: 24 }, // Statut
    { width: 40 }  // Anomalies
  ];

  return workbook.xlsx.writeBuffer();
}

module.exports = {
  generateAttendanceExcel
};
