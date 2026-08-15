import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import '../models/attendance_record.dart';
import '../models/user_profile.dart';
import '../core/utils/time_utils.dart';

class ExportService {
  static Future<void> exportToExcel(
    UserProfile profile,
    List<AttendanceRecord> records,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Sort records chronologically
    records.sort((a, b) => a.date.compareTo(b.date));
    final excel = Excel.createExcel();
    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Rapport');
    final sheet = excel['Rapport'];
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 22,
      fontColorHex: ExcelColor.fromHexString('#E65100'), // Orange 900
      horizontalAlign: HorizontalAlign.Left,
    );
    final subtitleStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#424242'), // Grey 800
    );
    final statsHeaderStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#757575'), // Grey 600
    );
    final statsValueStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#E65100'),
    );
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#FFF3E0'), // Orange 50
      fontColorHex: ExcelColor.fromHexString('#E65100'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      topBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFB74D'),
      ),
      bottomBorder: Border(
        borderStyle: BorderStyle.Medium,
        borderColorHex: ExcelColor.fromHexString('#FFB74D'),
      ),
    );

    // Company Header
    final cName = profile.companyName?.isNotEmpty == true
        ? profile.companyName!
        : 'ShiftTrack';
    sheet.updateCell(
      CellIndex.indexByString('A1'),
      TextCellValue(cName),
      cellStyle: titleStyle,
    );
    sheet.updateCell(
      CellIndex.indexByString('A2'),
      TextCellValue('${profile.firstName} ${profile.lastName}'),
      cellStyle: subtitleStyle,
    );
    sheet.updateCell(
      CellIndex.indexByString('A3'),
      TextCellValue(
        startDate.month == endDate.month && startDate.year == endDate.year
            ? 'Rapport de: ${DateFormat('MMMM yyyy').format(startDate)}'
            : 'Période: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
      ),
      cellStyle: CellStyle(fontColorHex: ExcelColor.fromHexString('#757575')),
    );

    // Compute shift duration for overtime calculation
    final inParts = profile.defaultCheckIn.split(':');
    final outParts = profile.defaultCheckOut.split(':');
    double defIn = double.parse(inParts[0]) + double.parse(inParts[1]) / 60;
    double defOut = double.parse(outParts[0]) + double.parse(outParts[1]) / 60;
    double shiftDuration = defOut - defIn;
    if (shiftDuration < 0) shiftDuration += 24;

    double breakOffset = (profile.isBreakPaid)
        ? 0
        : (profile.breakDuration / 60.0);
    double standardWorkDuration = shiftDuration - breakOffset;
    if (standardWorkDuration < 0) standardWorkDuration = shiftDuration;

    // Compute stats
    double totalH = 0;
    double totalOvertime = 0;
    int presentCount = 0;
    for (var r in records) {
      totalH += r.hours;
      if (r.status == AttendanceStatus.present) {
        presentCount++;
        double stdWork = r.scheduledHours > 0
            ? r.scheduledHours
            : standardWorkDuration;
        if (r.hours > stdWork) {
          totalOvertime += (r.hours - stdWork);
        }
      }
    }

    sheet.updateCell(
      CellIndex.indexByString('D2'),
      TextCellValue('Heures Totales'),
      cellStyle: statsHeaderStyle,
    );
    sheet.updateCell(
      CellIndex.indexByString('D3'),
      TextCellValue(formatDuration(totalH)),
      cellStyle: statsValueStyle,
    );

    sheet.updateCell(
      CellIndex.indexByString('E2'),
      TextCellValue('Heures Sup.'),
      cellStyle: statsHeaderStyle,
    );
    sheet.updateCell(
      CellIndex.indexByString('E3'),
      TextCellValue(formatDuration(totalOvertime)),
      cellStyle: CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('#2E7D32'),
      ),
    );

    sheet.updateCell(
      CellIndex.indexByString('F2'),
      TextCellValue('Présences'),
      cellStyle: statsHeaderStyle,
    );
    sheet.updateCell(
      CellIndex.indexByString('F3'),
      TextCellValue('$presentCount'),
      cellStyle: CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('#1976D2'),
      ),
    );

    sheet.appendRow([]); // Row 4
    sheet.appendRow([]); // Row 5

    // Table Headers
    final headerRow = [
      TextCellValue('Date'),
      TextCellValue('Statut'),
      TextCellValue('Entrée'),
      TextCellValue('Sortie'),
      TextCellValue('Sessions Sup.'),
      TextCellValue('Total Heures'),
      TextCellValue('Heures Sup.'),
    ];
    sheet.appendRow(headerRow);
    final headerRowIdx = sheet.maxRows - 1;
    for (int c = 0; c < headerRow.length; c++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRowIdx),
        headerRow[c],
        cellStyle: headerStyle,
      );
    }

    // Set Column Widths
    sheet.setColumnWidth(0, 15.0); // Date
    sheet.setColumnWidth(1, 12.0); // Statut
    sheet.setColumnWidth(2, 10.0); // Entrée
    sheet.setColumnWidth(3, 10.0); // Sortie
    sheet.setColumnWidth(4, 25.0); // Sessions Sup (Wide)
    sheet.setColumnWidth(5, 12.0); // Total Heures
    sheet.setColumnWidth(6, 12.0); // Heures Sup

    // Data
    final normalStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    for (var r in records) {
      final isPresent = r.status == AttendanceStatus.present;
      final statusColor = isPresent
          ? ExcelColor.fromHexString('#43A047')
          : ExcelColor.fromHexString('#E53935');
      final statusStyle = CellStyle(
        fontColorHex: statusColor,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      double dayOvertime = 0;
      if (isPresent) {
        double stdWork = r.scheduledHours > 0
            ? r.scheduledHours
            : standardWorkDuration;
        if (r.hours > stdWork) {
          dayOvertime = r.hours - stdWork;
        }
      }

      String sessionsStr = '-';
      if (isPresent && r.extraSessions != null && r.extraSessions!.isNotEmpty) {
        sessionsStr = r.extraSessions!
            .map((s) => '${s.startTime}-${s.endTime}')
            .join(', ');
      }

      final rowData = [
        TextCellValue(DateFormat('yyyy-MM-dd').format(r.date)),
        TextCellValue(isPresent ? 'Présent' : 'Absent'),
        TextCellValue(r.checkIn ?? '-'),
        TextCellValue(r.checkOut ?? '-'),
        TextCellValue(sessionsStr),
        TextCellValue(formatDuration(r.hours)),
        TextCellValue(dayOvertime > 0 ? formatDuration(dayOvertime) : '-'),
      ];
      sheet.appendRow(rowData);

      final rowIdx = sheet.maxRows - 1;
      for (int c = 0; c < rowData.length; c++) {
        CellStyle currentStyle = normalStyle;
        if (c == 1) currentStyle = statusStyle;
        if (c == 6 && dayOvertime > 0) {
          currentStyle = CellStyle(
            fontColorHex: ExcelColor.fromHexString('#2E7D32'),
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
        }

        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx),
          rowData[c],
          cellStyle: currentStyle,
        );
      }
    }

    final bytes = excel.save();
    if (bytes != null) {
      final filename = 'ShiftTrack_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
      await FileSaver.saveAndShareFile(Uint8List.fromList(bytes), filename);
    }
  }

  static Future<void> exportToPdf(
    UserProfile profile,
    List<AttendanceRecord> records,
    DateTime startDate,
    DateTime endDate,
  ) async {
    records.sort((a, b) => a.date.compareTo(b.date));
    final pdf = pw.Document();

    final ByteData iconData = await rootBundle.load('assets/icon/app_icon.png');
    final Uint8List iconBytes = iconData.buffer.asUint8List();
    final pw.MemoryImage appIcon = pw.MemoryImage(iconBytes);

    final inParts = profile.defaultCheckIn.split(':');
    final outParts = profile.defaultCheckOut.split(':');
    double defIn = double.parse(inParts[0]) + double.parse(inParts[1]) / 60;
    double defOut = double.parse(outParts[0]) + double.parse(outParts[1]) / 60;
    double shiftDuration = defOut - defIn;
    if (shiftDuration < 0) shiftDuration += 24;

    final breakOffset = profile.isBreakPaid
        ? 0.0
        : profile.breakDuration / 60.0;
    var standardWorkDuration = shiftDuration - breakOffset;
    if (standardWorkDuration < 0) standardWorkDuration = shiftDuration;

    double totalHours = 0;
    double totalOvertime = 0;
    int presentDays = 0;
    int absentDays = 0;
    final Map<String, List<AttendanceRecord>> groupedByMonth = {};

    for (final record in records) {
      totalHours += record.hours;
      if (record.status == AttendanceStatus.present) {
        presentDays++;
        final stdWork = record.scheduledHours > 0
            ? record.scheduledHours
            : standardWorkDuration;
        if (record.hours > stdWork) {
          totalOvertime += record.hours - stdWork;
        }
      } else if (record.status == AttendanceStatus.absent) {
        absentDays++;
      }

      final monthKey = DateFormat('MMMM yyyy', 'fr').format(record.date);
      groupedByMonth.putIfAbsent(monthKey, () => []).add(record);
    }

    final periodLabel =
        startDate.month == endDate.month && startDate.year == endDate.year
        ? 'Rapport de ${DateFormat('MMMM yyyy', 'fr').format(startDate)}'
        : 'Période: ${DateFormat('dd/MM/yyyy', 'fr').format(startDate)} - ${DateFormat('dd/MM/yyyy', 'fr').format(endDate)}';
    final companyName = profile.companyName?.isNotEmpty == true
        ? profile.companyName!.toUpperCase()
        : 'SHIFTTRACK';
    final employeeName = '${profile.firstName} ${profile.lastName}'.trim();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 28),
        footer: (context) => _buildPdfFooter(context),
        header: (context) => _buildPdfHeader(
          appIcon: appIcon,
          companyName: companyName,
          employeeName: employeeName.isEmpty ? 'Employé' : employeeName,
          periodLabel: periodLabel,
        ),
        build: (pw.Context context) {
          return [
            pw.Row(
              children: [
                _buildSummaryCard(
                  title: 'Heures totales',
                  value: formatDuration(totalHours),
                  color: _pdfTeal,
                  icon: 'H',
                ),
                pw.SizedBox(width: 10),
                _buildSummaryCard(
                  title: 'Heures sup.',
                  value: formatDuration(totalOvertime),
                  color: _pdfGreen,
                  icon: 'S',
                ),
                pw.SizedBox(width: 10),
                _buildSummaryCard(
                  title: 'Présences',
                  value: '$presentDays',
                  color: _pdfBlue,
                  icon: 'P',
                ),
                pw.SizedBox(width: 10),
                _buildSummaryCard(
                  title: 'Absences',
                  value: '$absentDays',
                  color: _pdfRed,
                  icon: '!',
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            if (groupedByMonth.length > 1) ...[
              _buildSectionTitle('Résumé mensuel'),
              pw.SizedBox(height: 10),
              _buildMonthlySummaryTable(groupedByMonth, standardWorkDuration),
              pw.SizedBox(height: 24),
            ],
            _buildSectionTitle('Détails des pointages'),
            pw.SizedBox(height: 10),
            _buildAttendanceTable(records, standardWorkDuration),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name:
          'ShiftTrack_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static const PdfColor _pdfInk = PdfColor.fromInt(0xFF111827);
  static const PdfColor _pdfMuted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _pdfLine = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _pdfSoft = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor _pdfTeal = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor _pdfGreen = PdfColor.fromInt(0xFF10B981);
  static const PdfColor _pdfBlue = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor _pdfRed = PdfColor.fromInt(0xFFEF4444);

  static pw.Widget _buildPdfHeader({
    required pw.MemoryImage appIcon,
    required String companyName,
    required String employeeName,
    required String periodLabel,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 22),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0F766E),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 42,
                  height: 42,
                  padding: const pw.EdgeInsets.all(5),
                  alignment: pw.Alignment.center,
                  decoration: const pw.BoxDecoration(color: PdfColors.white),
                  child: pw.Image(appIcon, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ShiftTrack',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        companyName,
                        maxLines: 1,
                        style: pw.TextStyle(
                          fontSize: 20,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        periodLabel,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromInt(0xFFD1FAE5),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Rapport PDF',
                      style: pw.TextStyle(
                        color: const PdfColor.fromInt(0xFFD1FAE5),
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      employeeName,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Généré le ${DateFormat('dd/MM/yyyy', 'fr').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColor.fromInt(0xFFD1FAE5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _pdfLine, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'ShiftTrack Workforce Report',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: _pdfInk,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'by developpeur billel bouraba - billel.dadi123@gmail.com',
                style: const pw.TextStyle(fontSize: 7, color: _pdfMuted),
              ),
            ],
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9,
              color: _pdfInk,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard({
    required String title,
    required String value,
    required PdfColor color,
    required String icon,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: _pdfLine, width: 0.9),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 22,
                  height: 22,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(color: color),
                  child: pw.Text(
                    icon,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 7),
                pw.Expanded(
                  child: pw.Text(
                    title,
                    maxLines: 1,
                    style: const pw.TextStyle(fontSize: 8, color: _pdfMuted),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 9),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 17,
                color: color,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 7,
          height: 18,
          decoration: const pw.BoxDecoration(color: _pdfTeal),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            color: _pdfInk,
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMonthlySummaryTable(
    Map<String, List<AttendanceRecord>> groupedByMonth,
    double standardWorkDuration,
  ) {
    return _buildTableShell(
      child: pw.Table(
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _pdfLine, width: 0.7),
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.2),
          1: pw.FlexColumnWidth(1.7),
          2: pw.FlexColumnWidth(1.7),
          3: pw.FlexColumnWidth(1.4),
          4: pw.FlexColumnWidth(1.4),
        },
        children: [
          _buildTableHeader([
            'Mois',
            'Heures totales',
            'Heures sup.',
            'Présences',
            'Absences',
          ]),
          ...groupedByMonth.entries.map((entry) {
            double monthHours = 0;
            double monthOvertime = 0;
            int monthPresent = 0;
            int monthAbsent = 0;

            for (final record in entry.value) {
              monthHours += record.hours;
              if (record.status == AttendanceStatus.present) {
                monthPresent++;
                final stdWork = record.scheduledHours > 0
                    ? record.scheduledHours
                    : standardWorkDuration;
                if (record.hours > stdWork) {
                  monthOvertime += record.hours - stdWork;
                }
              } else {
                monthAbsent++;
              }
            }

            return pw.TableRow(
              children: [
                _buildTableCell(entry.key),
                _buildTableCell(formatDuration(monthHours)),
                _buildTableCell(
                  formatDuration(monthOvertime),
                  color: _pdfGreen,
                ),
                _buildTableCell('$monthPresent', color: _pdfBlue),
                _buildTableCell('$monthAbsent', color: _pdfRed),
              ],
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildAttendanceTable(
    List<AttendanceRecord> records,
    double standardWorkDuration,
  ) {
    return _buildTableShell(
      child: pw.Table(
        border: const pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _pdfLine, width: 0.7),
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.45),
          1: pw.FlexColumnWidth(1.65),
          2: pw.FlexColumnWidth(1.1),
          3: pw.FlexColumnWidth(1.1),
          4: pw.FlexColumnWidth(1.7),
          5: pw.FlexColumnWidth(1.0),
          6: pw.FlexColumnWidth(1.1),
        },
        children: [
          _buildTableHeader([
            'Date',
            'Statut',
            'Entrée',
            'Sortie',
            'Extra',
            'Sup.',
            'Total',
          ]),
          ...records.map((record) {
            final isPresent = record.status == AttendanceStatus.present;
            double dayOvertime = 0;
            if (isPresent) {
              final stdWork = record.scheduledHours > 0
                  ? record.scheduledHours
                  : standardWorkDuration;
              if (record.hours > stdWork) {
                dayOvertime = record.hours - stdWork;
              }
            }

            var sessions = '-';
            if (isPresent &&
                record.extraSessions != null &&
                record.extraSessions!.isNotEmpty) {
              sessions = record.extraSessions!
                  .map((session) => '${session.startTime}-${session.endTime}')
                  .join('\n');
            }

            return pw.TableRow(
              children: [
                _buildTableCell(
                  DateFormat('dd/MM/yy', 'fr').format(record.date),
                ),
                _buildStatusCell(isPresent),
                _buildTableCell(record.checkIn ?? '-'),
                _buildTableCell(record.checkOut ?? '-'),
                _buildTableCell(sessions, fontSize: 7.5),
                _buildTableCell(
                  dayOvertime > 0 ? formatDuration(dayOvertime) : '-',
                  color: dayOvertime > 0 ? _pdfGreen : _pdfMuted,
                  bold: dayOvertime > 0,
                ),
                _buildTableCell(formatDuration(record.hours), bold: true),
              ],
            );
          }),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableHeader(List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _pdfSoft),
      children: labels
          .map(
            (label) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 9,
                horizontal: 5,
              ),
              child: pw.Text(
                label,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: _pdfInk,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _buildTableShell({required pw.Widget child}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _pdfLine, width: 0.9),
      ),
      child: child,
    );
  }

  static pw.Widget _buildStatusCell(bool isPresent) {
    final color = isPresent ? _pdfGreen : _pdfRed;
    final label = isPresent ? 'PRÉSENT' : 'ABSENT';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 9, horizontal: 5),
      child: pw.Text(
        label,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    PdfColor color = _pdfInk,
    bool bold = false,
    double fontSize = 8.3,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 9, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
