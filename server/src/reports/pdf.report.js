const PDFDocument = require('pdfkit');

function generateAttendancePDF(data) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({
      size: 'A4',
      layout: 'landscape',
      margins: { top: 25, bottom: 25, left: 25, right: 25 },
      info: {
        Title: `Rapport de Pointage - ${data.employee?.fullName || 'Employé'}`,
        Author: 'Billel Attendance System',
        Subject: 'Relevé de pointage et calcul de présence'
      },
      bufferPages: true
    });

    const buffers = [];
    doc.on('data', buffers.push.bind(buffers));
    doc.on('end', () => {
      // Add page numbers on all buffered pages
      const totalPages = doc.bufferedPageRange().count;
      for (let i = 0; i < totalPages; i++) {
        doc.switchToPage(i);
        doc.fontSize(7.5).fillColor('#94A3B8').font('Helvetica')
           .text(`Page ${i + 1} sur ${totalPages}`, 720, 565, { width: 70, align: 'right' })
           .text(`BILLEL ATTENDANCE — Document interne confidentiel ZKBioTime 9.0.3`, 25, 565, { width: 450, align: 'left' });
      }
      
      const pdfData = Buffer.concat(buffers);
      resolve(pdfData);
    });
    doc.on('error', reject);

    const { employee, period, summary, days } = data;
    const pageWidth = 792; // 842 - 50 margin
    const leftMargin = 25;

    // --- Header Top Banner ---
    doc.rect(leftMargin, 25, pageWidth, 42).fill('#1E293B');

    doc.fontSize(15).fillColor('#FFFFFF').font('Helvetica-Bold')
       .text('BILLEL ATTENDANCE — RAPPORT DÉTAILLÉ DU POINTAGE', leftMargin + 15, 33);
    
    doc.fontSize(8.5).fillColor('#94A3B8').font('Helvetica')
       .text(`Source : ZKBioTime 9.0.3 (Live) • Édité le : ${new Date().toLocaleString('fr-FR')}`, leftMargin + 15, 51);

    // --- Employee & Period Metadata Card ---
    const infoY = 74;
    const infoHeight = 36;
    doc.rect(leftMargin, infoY, pageWidth, infoHeight).fill('#F8FAFC').stroke('#CBD5E1');

    doc.fontSize(9.5).fillColor('#0F172A').font('Helvetica-Bold')
       .text('Employé : ', leftMargin + 15, infoY + 7, { continued: true })
       .font('Helvetica').text(`${(employee.fullName || '').toUpperCase()} (Matricule : ${employee.empCode})`)
       .font('Helvetica-Bold').text('Département : ', leftMargin + 15, infoY + 20, { continued: true })
       .font('Helvetica').text(`${employee.department || 'N/A'}`);

    doc.fontSize(9.5).fillColor('#0F172A').font('Helvetica-Bold')
       .text('Période du : ', 460, infoY + 7, { continued: true })
       .font('Helvetica').text(`${period.startDateFR} au ${period.endDateFR}`)
       .font('Helvetica-Bold').text('Heure Début Normale : ', 460, infoY + 20, { continued: true })
       .font('Helvetica').text(`${summary.standardStartTime || '08:00'}`);

    // --- KPI Metrics Boxes ---
    const kpiY = 117;
    const kpiCount = 6;
    const kpiGap = 6;
    const kpiWidth = (pageWidth - (kpiGap * (kpiCount - 1))) / kpiCount;

    const kpis = [
      { label: 'JOURS TRAVAILLÉS', val: `${summary.daysWorked} / ${summary.totalDaysInRange}`, color: '#0F766E', bg: '#F0FDFA' },
      { label: 'HEURES TRAVAILLÉES', val: `${summary.totalWorkedHoursStr}`, color: '#1E40AF', bg: '#EFF6FF' },
      { label: 'MOYENNE / JOUR', val: `${summary.averageDailyHoursStr || '00h00'}`, color: '#6B21A8', bg: '#FAF5FF' },
      { label: 'RETARDS', val: `${summary.totalDelaysCount} (${summary.totalDelayHoursStr})`, color: '#B45309', bg: '#FFFBEB' },
      { label: 'ABSENCES', val: `${summary.totalAbsencesCount}`, color: '#B91C1C', bg: '#FEF2F2' },
      { label: 'ANOMALIES', val: `${summary.totalAnomaliesCount}`, color: '#DC2626', bg: '#FFF1F2' }
    ];

    kpis.forEach((kpi, idx) => {
      const x = leftMargin + (idx * (kpiWidth + kpiGap));
      doc.rect(x, kpiY, kpiWidth, 32).fill(kpi.bg).stroke('#E2E8F0');
      doc.fontSize(6.5).fillColor('#64748B').font('Helvetica-Bold').text(kpi.label, x + 3, kpiY + 4, { width: kpiWidth - 6, align: 'center' });
      doc.fontSize(10.5).fillColor(kpi.color).font('Helvetica-Bold').text(kpi.val, x + 3, kpiY + 16, { width: kpiWidth - 6, align: 'center' });
    });

    // --- Table Headers & Columns ---
    const tableTop = 157;
    const colX = [25, 95, 165, 230, 295, 375, 445, 555];
    const colW = [70, 70, 65, 65, 80, 70, 110, 237];
    const headers = ['Date', 'Jour', 'Entrée', 'Sortie', 'Temps Trav.', 'Retard', 'Statut', 'Observations / Anomalies'];

    const renderTableHeader = (y) => {
      doc.rect(leftMargin, y, pageWidth, 17).fill('#334155');
      headers.forEach((h, i) => {
        doc.fontSize(7.5).fillColor('#FFFFFF').font('Helvetica-Bold')
           .text(h, colX[i] + 3, y + 4.5, { width: colW[i] - 6, align: i === 7 ? 'left' : 'center' });
      });
    };

    renderTableHeader(tableTop);

    let currentY = tableTop + 17;
    const rowHeight = 13.5;
    const pageMaxY = 515;

    days.forEach((day, index) => {
      if (currentY + rowHeight > pageMaxY) {
        doc.addPage({ size: 'A4', layout: 'landscape', margins: { top: 25, bottom: 25, left: 25, right: 25 } });
        currentY = 35;
        renderTableHeader(currentY);
        currentY += 17;
      }

      const rowBg = index % 2 === 0 ? '#FFFFFF' : '#F8FAFC';
      doc.rect(leftMargin, currentY, pageWidth, rowHeight).fill(rowBg).stroke('#E2E8F0');

      const observations = day.anomalies.map(a => a.label).join('; ') || (day.isWeekend ? 'Week-end / Repos' : '');

      doc.fontSize(7.5).font('Helvetica');

      // Date
      doc.fillColor('#0F172A').text(day.dateFR, colX[0], currentY + 3, { width: colW[0], align: 'center' });
      
      // Day name
      doc.text(day.dayName, colX[1], currentY + 3, { width: colW[1], align: 'center' });
      
      // Entry
      doc.text(day.entryTime, colX[2], currentY + 3, { width: colW[2], align: 'center' });
      
      // Exit
      doc.text(day.exitTime, colX[3], currentY + 3, { width: colW[3], align: 'center' });
      
      // Work Time
      doc.font('Helvetica-Bold').text(day.workTimeStr, colX[4], currentY + 3, { width: colW[4], align: 'center' });
      
      // Delay
      if (day.delayMinutes > 0) {
        doc.fillColor('#B45309').font('Helvetica-Bold');
      } else {
        doc.fillColor('#64748B').font('Helvetica');
      }
      doc.text(day.delayStr, colX[5], currentY + 3, { width: colW[5], align: 'center' });

      // Status
      if (day.anomalies.length > 0) {
        doc.fillColor('#DC2626').font('Helvetica-Bold');
      } else if (day.workTimeMinutes > 0 || (day.isToday && day.rawEntry)) {
        doc.fillColor('#059669').font('Helvetica-Bold');
      } else if (day.isWeekend || day.isFuture) {
        doc.fillColor('#64748B').font('Helvetica');
      } else {
        doc.fillColor('#B91C1C').font('Helvetica');
      }
      doc.text(day.status, colX[6] + 2, currentY + 3, { width: colW[6] - 4, align: 'center' });

      // Observations
      const obsColor = day.anomalies.length > 0 ? '#DC2626' : ((day.isWeekend || day.isFuture) ? '#94A3B8' : '#475569');
      doc.fillColor(obsColor).font('Helvetica')
         .text(observations, colX[7] + 4, currentY + 3, { width: colW[7] - 8, align: 'left', lineBreak: false });

      currentY += rowHeight;
    });

    // --- Signature Section ---
    // If not enough room on current page, add new page
    if (currentY + 45 > 550) {
      doc.addPage({ size: 'A4', layout: 'landscape', margins: { top: 25, bottom: 25, left: 25, right: 25 } });
      currentY = 50;
    } else {
      currentY = Math.max(currentY + 12, 495);
    }

    const sigBoxWidth = 220;
    const sigBoxHeight = 35;

    doc.fontSize(8).fillColor('#334155').font('Helvetica-Bold')
       .text('Signature du collaborateur :', 80, currentY)
       .text('Visa Responsable RH / Direction :', 490, currentY);

    doc.rect(80, currentY + 12, sigBoxWidth, sigBoxHeight).fill('#FFFFFF').stroke('#94A3B8');
    doc.rect(490, currentY + 12, sigBoxWidth, sigBoxHeight).fill('#FFFFFF').stroke('#94A3B8');

    doc.end();
  });
}

module.exports = {
  generateAttendancePDF
};
