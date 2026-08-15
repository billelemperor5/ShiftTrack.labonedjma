import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'attendance_calculator.dart';

class BioTimePdfService {
  static Future<void> exportAttendancePdf({
    required MonthAttendanceReport report,
    required List<DailyAttendanceSummary> days,
    required String periodTitle,
  }) async {
    final pdf = pw.Document();

    final fontBold = await PdfGoogleFonts.interBold();
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontMedium = await PdfGoogleFonts.interMedium();

    final totalWorkedDays = days.where((d) => d.punches.isNotEmpty || d.workTimeMinutes > 0).length;
    int totalMinutes = 0;
    int totalDelays = 0;
    int totalDelayMins = 0;

    for (final d in days) {
      totalMinutes += d.workTimeMinutes;
      if (d.delayMinutes > 0) {
        totalDelays++;
        totalDelayMins += d.delayMinutes;
      }
    }

    final totalHoursFormatted = '${(totalMinutes ~/ 60).toString().padLeft(2, '0')}h${(totalMinutes % 60).toString().padLeft(2, '0')}';
    final totalDelayFormatted = '${(totalDelayMins ~/ 60).toString().padLeft(2, '0')}h${(totalDelayMins % 60).toString().padLeft(2, '0')}';
    final nowStr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (context) => _buildPdfHeader(report, periodTitle, fontBold, fontRegular),
        footer: (context) => _buildPdfFooter(context, fontRegular),
        build: (context) => [
          pw.SizedBox(height: 12),

          // 1. Employee Identity Card & Meta
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Collaborateur: ', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(report.empName, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.blue900)),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        pw.Text('Matricule: ', style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.grey700)),
                        pw.Text(report.empCode, style: pw.TextStyle(font: fontMedium, fontSize: 9.5, color: PdfColors.black)),
                        pw.SizedBox(width: 14),
                        pw.Text('Département: ', style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.grey700)),
                        pw.Text(report.department, style: pw.TextStyle(font: fontMedium, fontSize: 9.5, color: PdfColors.teal800)),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('Période: ', style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.grey700)),
                        pw.Text(periodTitle, style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.indigo900)),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text('Édité le: $nowStr', style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // 2. Summary KPI Badges
          pw.Row(
            children: [
              _buildPdfKpi(
                title: 'Jours Travaillés',
                value: '$totalWorkedDays jours',
                color: PdfColors.green700,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(width: 8),
              _buildPdfKpi(
                title: 'Heures Totales',
                value: totalHoursFormatted,
                color: PdfColors.blue700,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(width: 8),
              _buildPdfKpi(
                title: 'Taux Présence',
                value: '${report.presenceRate}%',
                color: PdfColors.teal700,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
              pw.SizedBox(width: 8),
              _buildPdfKpi(
                title: 'Retards Constatés',
                value: '$totalDelays ($totalDelayFormatted)',
                color: totalDelays > 0 ? PdfColors.orange800 : PdfColors.green700,
                fontBold: fontBold,
                fontRegular: fontRegular,
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // 3. Attendance Detailed Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.2), // Date
              1: pw.FlexColumnWidth(2.0), // Jour
              2: pw.FlexColumnWidth(2.2), // Entrée
              3: pw.FlexColumnWidth(2.2), // Sortie
              4: pw.FlexColumnWidth(2.2), // Durée
              5: pw.FlexColumnWidth(2.0), // Retard
              6: pw.FlexColumnWidth(2.4), // Statut
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                children: [
                  _buildTableHeaderCell('Date', fontBold),
                  _buildTableHeaderCell('Jour', fontBold),
                  _buildTableHeaderCell('1er Pointage', fontBold),
                  _buildTableHeaderCell('Dernier Pointage', fontBold),
                  _buildTableHeaderCell('Temps Travaillé', fontBold),
                  _buildTableHeaderCell('Retard', fontBold),
                  _buildTableHeaderCell('Statut', fontBold),
                ],
              ),
              // Data rows
              ...days.map((d) {
                final hasPunches = d.punches.isNotEmpty || d.workTimeMinutes > 0;
                final isWeekend = d.isWeekend;
                final rowBg = isWeekend
                    ? PdfColors.grey100
                    : (hasPunches ? PdfColors.white : PdfColors.grey50);

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowBg),
                  children: [
                    _buildTableCell(d.dateFR, fontRegular, align: pw.TextAlign.center),
                    _buildTableCell(d.dayName, fontRegular, align: pw.TextAlign.center),
                    _buildTableCell(
                      hasPunches ? (d.entryTime ?? '--:--') : '-',
                      fontBold,
                      color: hasPunches ? PdfColors.blue900 : PdfColors.grey500,
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      hasPunches ? (d.exitTime ?? '--:--') : '-',
                      fontBold,
                      color: hasPunches ? PdfColors.green900 : PdfColors.grey500,
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      hasPunches ? d.workTimeStr : '-',
                      fontBold,
                      color: hasPunches ? PdfColors.teal900 : PdfColors.grey500,
                      align: pw.TextAlign.center,
                    ),
                    _buildTableCell(
                      hasPunches && d.delayMinutes > 0 ? d.delayStr : '-',
                      fontRegular,
                      color: d.delayMinutes > 0 ? PdfColors.red800 : PdfColors.grey600,
                      align: pw.TextAlign.center,
                    ),
                    _buildStatusCell(d, fontBold),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 18),

          // 4. Signatures Box
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Signature de l\'Employé (Lu et approuvé):', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.SizedBox(height: 38),
                    pw.Container(width: 170, height: 0.5, color: PdfColors.grey500),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Visa & Cachet Direction des Ressources Humaines (RH):', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    pw.SizedBox(height: 38),
                    pw.Container(width: 220, height: 0.5, color: PdfColors.grey500),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Open native browser PDF preview and print dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Releve_Presence_${report.empCode}_${DateFormat('yyyyMM').format(days.first.date)}.pdf',
    );
  }

  static pw.Widget _buildPdfHeader(MonthAttendanceReport report, String periodTitle, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue900, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RELEVÉ MENSUEL DE PRÉSENCE & POINTAGES',
                style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Système Biométrique Intégré ZKTeco BioTime',
                style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'DOCUMENT OFFICIEL',
              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.white),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context, pw.Font fontRegular) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'ShiftTrack Enterprise - Extraction certifiée BioTime Live',
            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfKpi({
    required String title,
    required String value,
    required PdfColor color,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4.5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: font, fontSize: 8.5, color: color ?? PdfColors.black),
      ),
    );
  }

  static pw.Widget _buildStatusCell(DailyAttendanceSummary d, pw.Font fontBold) {
    final hasPunches = d.punches.isNotEmpty || d.workTimeMinutes > 0;
    String label = 'Repos';
    PdfColor bg = PdfColors.grey200;
    PdfColor textCol = PdfColors.grey800;

    if (hasPunches) {
      if (d.delayMinutes > 0) {
        label = 'Présent (Retard)';
        bg = PdfColors.amber100;
        textCol = PdfColors.orange900;
      } else {
        label = 'Présent';
        bg = PdfColors.green100;
        textCol = PdfColors.green900;
      }
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: textCol),
        ),
      ),
    );
  }
}
