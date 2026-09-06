import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/models/breakdown_models.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<pw.Document> buildQuoteDocument({
    required String projectName,
    required List<QuoteItem> items,
    required Settings settings,
    bool showCategoryTotals = true,
    bool showItemPrices = true,
    bool showItemizedTasks = false,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    pw.Font italicFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      italicFont = await PdfGoogleFonts.robotoItalic();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    final categories = <AppDestinations, List<QuoteItem>>{};
    for (var item in items) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    double grandTotal = items.fold(0.0, (sum, item) => sum + item.priceForClient);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, italic: italicFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text("ΠΡΟΣΦΟΡΑ ΕΡΓΟΥ: ${projectName.toUpperCase()}", 
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 20),

          ...categories.entries.map((entry) {
            final category = entry.key;
            final catItems = entry.value;
            final catTotal = catItems.fold(0.0, (sum, i) => sum + i.priceForClient);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(category.label.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      if (showCategoryTotals)
                        pw.Text("${catTotal.toStringAsFixed(2)} €", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                if (showItemizedTasks && showItemPrices) ...[
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    headers: ['ΠΕΡΙΓΡΑΦΗ', 'ΠΟΣΟΤΗΤΑ', 'ΤΙΜΗ ΜΟΝΑΔΑΣ', 'ΣΥΝΟΛΟ'],
                    headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    data: catItems.where((item) => item.showInQuote).map((item) {
                      return [
                        item.description,
                        '${item.quantity} ${item.unit}'.trim(),
                        '${double.tryParse(item.unitPrice.replaceAll(',', '.'))?.toStringAsFixed(2) ?? item.unitPrice} €',
                        '${item.priceForClient.toStringAsFixed(2)} €',
                      ];
                    }).toList(),
                    border: null,
                  ),
                  pw.SizedBox(height: 15),
                ] else ...[
                  pw.SizedBox(height: 10),
                ],
              ],
            );
          }).toList(),

          pw.SizedBox(height: 20),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            padding: const pw.EdgeInsets.all(15),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("ΤΕΛΙΚΟ ΣΥΝΟΛΟ (Προ ΦΠΑ):", style: pw.TextStyle(color: PdfColors.blueGrey800, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text("${grandTotal.toStringAsFixed(2)} €", style: pw.TextStyle(color: PdfColors.black, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Text("Σας ευχαριστούμε για την εμπιστοσύνη σας. Παραμένουμε στη διάθεσή σας για κάθε διευκρίνιση.", 
            style: pw.TextStyle(fontSize: 9, font: italicFont, color: PdfColors.grey700)),
        ],
      ),
    );
    return pdf;
  }

  static Future<void> generateAndShareQuote({
    required String projectName,
    required List<QuoteItem> items,
    required Settings settings,
    bool showCategoryTotals = true,
    bool showItemPrices = true,
    bool showItemizedTasks = false,
  }) async {
    final pdf = await buildQuoteDocument(
      projectName: projectName, 
      items: items, 
      settings: settings, 
      showCategoryTotals: showCategoryTotals,
      showItemPrices: showItemPrices,
      showItemizedTasks: showItemizedTasks,
    );
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'MTC_Quote_${projectName.replaceAll(' ', '_')}.pdf');
  }

  static Future<pw.Document> buildContractDocument({
    required Project project,
    required List<QuoteItem> items,
    required Settings settings,
    Uint8List? contractorSignature,
    Uint8List? clientSignature,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    pw.Font italicFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      italicFont = await PdfGoogleFonts.robotoItalic();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    double total = items.fold(0.0, (sum, item) => sum + item.priceForClient);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, italic: italicFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 30),
          pw.Center(child: pw.Text("ΙΔΙΩΤΙΚΟ ΣΥΜΦΩΝΗΤΙΚΟ", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 24),
          pw.Text("1. ΑΝΤΙΚΕΙΜΕΝΟ ΕΡΓΑΣΙΩΝ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Text("Ο εργολάβος αναλαμβάνει την εκτέλεση των εργασιών στη διεύθυνση ${project.address}, σύμφωνα με την αναλυτική προσφορά που ακολουθεί.", style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 20),
          pw.Text("2. ΑΝΑΛΥΤΙΚΟΣ ΠΙΝΑΚΑΣ ΕΡΓΑΣΙΩΝ & ΚΟΣΤΟΣ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['ΠΕΡΙΓΡΑΦΗ', 'ΠΟΣΟΤΗΤΑ', 'ΣΥΝΟΛΟ (€)'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: items.map((i) => [i.description, "${i.quantity} ${i.unit}", i.priceForClient.toStringAsFixed(2)]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text("ΣΥΝΟΛΙΚΟ ΠΟΣΟ (ΚΑΘΑΡΑ): ${total.toStringAsFixed(2)} €", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ],
          ),
          pw.SizedBox(height: 60),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              pw.Column(
                children: [
                  pw.Text("Ο ΕΡΓΟΛΑΒΟΣ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  if (contractorSignature != null) pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8), child: pw.Image(pw.MemoryImage(contractorSignature), width: 120, height: 60)),
                  pw.Text(settings.companyName.toUpperCase(), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text("Ο ΠΕΛΑΤΗΣ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  if (clientSignature != null) pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8), child: pw.Image(pw.MemoryImage(clientSignature), width: 120, height: 60)),
                  pw.Text(project.clientName.toUpperCase(), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return pdf;
  }

  static Future<void> generateAndShareContract({
    required Project project,
    required List<QuoteItem> items,
    required Settings settings,
    Uint8List? contractorSignature,
    Uint8List? clientSignature,
  }) async {
    final pdf = await buildContractDocument(project: project, items: items, settings: settings, contractorSignature: contractorSignature, clientSignature: clientSignature);
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'MTC_Contract_${project.name.replaceAll(' ', '_')}.pdf');
  }

  static Future<void> generateAndSharePayroll({
    required String title,
    required List<AttendanceEntity> attendance,
    required List<Expense> payments,
    required List<Project> projects,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    pw.Font italicFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      italicFont = await PdfGoogleFonts.robotoItalic();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    final workerNames = (attendance.map((e) => e.workerName).toList() + payments.map((e) => e.workerName).toList()).toSet().toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, italic: italicFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text("ΚΑΤΑΣΤΑΣΗ ΠΛΗΡΩΜΩΝ: $title", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['ΕΡΓΑΤΗΣ', 'ΔΕΔΟΥΛΕΥΜΕΝΑ (€)', 'ΠΛΗΡΩΜΕΣ (€)', 'ΥΠΟΛΟΙΠΟ (€)'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 10),
            data: [
              ...workerNames.map((name) {
                final earned = attendance.where((a) => a.workerName == name).fold(0.0, (sum, a) => sum + a.dailyRate + a.overtimeAmount);
                final paid = payments.where((p) => p.workerName == name).fold(0.0, (sum, p) => sum + p.amount);
                return [name.toUpperCase(), earned.toStringAsFixed(2), paid.toStringAsFixed(2), (earned - paid).toStringAsFixed(2)];
              }),
              [
                'ΣΥΝΟΛΑ',
                '${workerNames.fold(0.0, (sum, name) => sum + attendance.where((a) => a.workerName == name).fold(0.0, (s, a) => s + a.dailyRate + a.overtimeAmount)).toStringAsFixed(2)} €',
                '${workerNames.fold(0.0, (sum, name) => sum + payments.where((p) => p.workerName == name).fold(0.0, (s, p) => s + p.amount)).toStringAsFixed(2)} €',
                '${workerNames.fold(0.0, (sum, name) => sum + (attendance.where((a) => a.workerName == name).fold(0.0, (s, a) => s + a.dailyRate + a.overtimeAmount) - payments.where((p) => p.workerName == name).fold(0.0, (s, p) => s + p.amount))).toStringAsFixed(2)} €',
              ],
            ],
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print("Printing Error: $e");
    }
  }

  static Future<void> generateAndShareProgressReport({
    required Project project,
    required List<ProjectStageEntity> stages,
    required List<ProjectPhotoEntity> photos,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    pw.Font italicFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      italicFont = await PdfGoogleFonts.robotoItalic();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, italic: italicFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text("ΑΝΑΦΟΡΑ ΠΡΟΟΔΟΥ ΕΡΓΑΣΙΩΝ", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          ),
          pw.Center(
            child: pw.Text(project.name.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          ),
          pw.SizedBox(height: 30),
          pw.Text("ΚΑΤΑΣΤΑΣΗ ΦΑΣΕΩΝ:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          ...stages.map((s) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: pw.Text(s.name.toUpperCase(), style: const pw.TextStyle(fontSize: 10))),
                pw.Expanded(
                  flex: 7, 
                  child: pw.Stack(
                    children: [
                      pw.Container(height: 10, width: double.infinity, color: PdfColors.grey200),
                      pw.Container(height: 10, width: 200 * s.progress, color: s.progress >= 1.0 ? PdfColors.green700 : PdfColors.blue700),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text("${(s.progress * 100).toInt()}%", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          )),
          pw.SizedBox(height: 40),
          pw.Text("ΠΡΟΣΦΑΤΕΣ ΦΩΤΟΓΡΑΦΙΕΣ:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          if (photos.isEmpty)
            pw.Text("Δεν υπάρχουν διαθέσιμες φωτογραφίες για αυτή την αναφορά.", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))
          else
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: photos.take(6).map((p) {
                final file = File(p.uri);
                if (file.existsSync()) {
                  return pw.Container(
                    width: 170,
                    height: 120,
                    child: pw.Image(pw.MemoryImage(file.readAsBytesSync()), fit: pw.BoxFit.cover),
                  );
                }
                return pw.SizedBox();
              }).toList(),
            ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Progress_Report_${project.name.replaceAll(' ', '_')}.pdf');
  }

  static Future<void> generateAndShareToolList({
    required List<Tool> tools,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text("ΚΑΤΑΣΤΑΣΗ ΕΡΓΑΛΕΙΩΝ", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['ΕΡΓΑΛΕΙΟ', 'ΚΑΤΗΓΟΡΙΑ', 'ΤΟΠΟΘΕΣΙΑ', 'ΠΟΣΟΤΗΤΑ'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: tools.map((t) {
              String locText = "";
              switch (t.locationType) {
                case "WAREHOUSE": locText = "ΑΠΟΘΗΚΗ"; break;
                case "VAN": locText = "ΒΑΝ"; break;
                case "PROJECT": locText = t.customLocationName ?? "ΕΡΓΟ"; break;
              }
              return [t.name.toUpperCase(), t.category.toUpperCase(), locText, t.quantity.toInt().toString()];
            }).toList(),
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print("Printing Error: $e");
    }
  }

  static Future<void> generateAndShareCostAnalysis({
    required String projectName,
    required Map<String, CategoryBreakdown> breakdown,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text("ΑΝΑΛΥΣΗ ΚΟΣΤΟΥΣ ΕΡΓΟΥ: ${projectName.toUpperCase()}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['ΚΑΤΗΓΟΡΙΑ', 'ΕΡΓΑΤΙΚΑ (€)', 'ΥΛΙΚΑ (€)', 'ΣΥΝΟΛΟ (€)'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: [
              ...breakdown.entries.map((e) => [
                e.key.toUpperCase(),
                e.value.labor.toStringAsFixed(2),
                e.value.materials.toStringAsFixed(2),
                e.value.total.toStringAsFixed(2),
              ]),
              [
                'ΣΥΝΟΛΑ',
                '${breakdown.values.fold(0.0, (sum, e) => sum + e.labor).toStringAsFixed(2)} €',
                '${breakdown.values.fold(0.0, (sum, e) => sum + e.materials).toStringAsFixed(2)} €',
                '${breakdown.values.fold(0.0, (sum, e) => sum + e.total).toStringAsFixed(2)} €',
              ],
            ],
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print("Printing Error: $e");
    }
  }

  static Future<void> generateAndShareProjectFinancials({
    required String projectName,
    required List<Expense> expenses,
    required List<Income> incomes,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    final allItems = <Map<String, dynamic>>[];
    for (var i in incomes) {
      allItems.add({'date': i.date, 'desc': i.description, 'partner': 'ΠΕΛΑΤΗΣ', 'type': 'ΕΙΣΠΡΑΞΗ', 'amount': i.amount, 'isIncome': true});
    }
    for (var e in expenses) {
      allItems.add({'date': e.date, 'desc': e.description, 'partner': e.workerName, 'type': e.expenseType == 'INVOICE' ? 'ΤΙΜΟΛΟΓΙΟ' : 'ΠΛΗΡΩΜΗ', 'amount': e.amount, 'isIncome': false});
    }
    allItems.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text("ΟΙΚΟΝΟΜΙΚΗ ΚΑΤΑΣΤΑΣΗ ΕΡΓΟΥ: ${projectName.toUpperCase()}", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['ΗΜΕΡΟΜΗΝΙΑ', 'ΠΕΡΙΓΡΑΦΗ', 'ΣΥΝΕΡΓΑΤΗΣ', 'ΠΟΣΟ (€)'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 8),
            data: [
              ...allItems.map((i) => [
                DateFormat('dd/MM/yy').format(DateTime.fromMillisecondsSinceEpoch(i['date'])),
                i['desc'].toString().toUpperCase(),
                i['partner'].toString().toUpperCase(),
                '${(i['isIncome'] ? '+' : '-')}${i['amount'].toStringAsFixed(2)}',
              ]),
              [
                'ΣΥΝΟΛΑ',
                '',
                '',
                '${(incomes.fold(0.0, (s, i) => s + i.amount) - expenses.fold(0.0, (s, e) => s + e.amount)).toStringAsFixed(2)} €',
              ],
            ],
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print("Printing Error: $e");
    }
  }

  static Future<void> generateAndSharePartnerList({
    required List<Partner> partners,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text("ΚΑΤΑΛΟΓΟΣ ΣΥΝΕΡΓΑΤΩΝ", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['ΟΝΟΜΑΤΕΠΩΝΥΜΟ', 'ΤΗΛΕΦΩΝΟ', 'ΕΙΔΙΚΟΤΗΤΑ', 'ΜΕΡΟΚΑΜΑΤΟ'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: partners.map((p) => [
              p.name.toUpperCase(),
              p.phone,
              p.trade.toUpperCase(),
              '${p.baseRate.toStringAsFixed(2)} €',
            ]).toList(),
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print("Printing Error: $e");
    }
  }

  static Future<void> generateAndShareClientList({
    required List<Client> clients,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text("ΠΕΛΑΤΟΛΟΓΙΟ", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['ΟΝΟΜΑΤΕΠΩΝΥΜΟ', 'ΤΗΛΕΦΩΝΟ', 'EMAIL', 'ΚΑΤΑΣΤΑΣΗ'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: clients.map((c) => [
              c.name.toUpperCase(),
              c.phone,
              c.email.toLowerCase(),
              c.status,
            ]).toList(),
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print("Printing Error: $e");
    }
  }

  static Future<void> generateAndShareInvoiceList({
    required List<Expense> invoices,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text("ΛΙΣΤΑ ΤΙΜΟΛΟΓΙΩΝ & ΑΓΟΡΩΝ", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['ΗΜΕΡΟΜΗΝΙΑ', 'ΠΕΡΙΓΡΑΦΗ', 'ΠΡΟΜΗΘΕΥΤΗΣ', 'ΠΟΣΟ (€)'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: [
              ...invoices.map((i) => [
                DateFormat('dd/MM/yy').format(DateTime.fromMillisecondsSinceEpoch(i.date)),
                i.description.toUpperCase(),
                i.workerName.toUpperCase(),
                '${i.amount.toStringAsFixed(2)} €',
              ]),
              [
                'ΣΥΝΟΛΟ',
                '',
                '',
                '${invoices.fold(0.0, (s, i) => s + i.amount).toStringAsFixed(2)} €',
              ],
            ],
          ),
        ],
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      print("Printing Error: $e");
    }
  }

  static Future<pw.MemoryImage?> _loadLogo(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return pw.MemoryImage(await file.readAsBytes());
      }
    } catch (_) {}
    return null;
  }

  static Future<void> generateAndShareCompanyFullReport({
    required double totalIncomes,
    required double projectExpenses,
    required double generalExpenses,
    required List<Project> projects,
    required Map<int, Map<String, dynamic>> detailedBreakdowns,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    pw.Font italicFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      italicFont = await PdfGoogleFonts.robotoItalic();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, italic: italicFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 30),
          pw.Center(child: pw.Text("ΑΝΑΛΥΤΙΚΗ ΟΙΚΟΝΟΜΙΚΗ ΑΝΑΦΟΡΑ ΕΤΑΙΡΕΙΑΣ", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 20),

          pw.Text("ΣΥΝΟΨΗ ΕΤΑΙΡΕΙΑΣ", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildPdfBalanceRow("Συνολικές Εισπράξεις (Καθαρά):", totalIncomes, PdfColors.green700),
          _buildPdfBalanceRow("Συνολικά Έξοδα Έργων (Καθαρά):", projectExpenses, PdfColors.red700),
          _buildPdfBalanceRow("Γενικά Έξοδα & Πάγια (Καθαρά):", generalExpenses, PdfColors.red700),
          pw.Divider(),
          _buildPdfBalanceRow("ΚΑΘΑΡΟ ΚΕΡΔΟΣ:", totalIncomes - projectExpenses - generalExpenses, PdfColors.blueGrey900, isBold: true),
          
          pw.SizedBox(height: 40),
          pw.Text("ΑΝΑΛΥΣΗ ΑΝΑ ΕΡΓΟ", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),

          ...projects.map((project) {
            final breakdown = detailedBreakdowns[project.id];
            if (breakdown == null || breakdown.isEmpty) return pw.SizedBox();

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(project.name.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ),
                pw.Table.fromTextArray(
                  headers: ['ΚΑΤΗΓΟΡΙΑ', 'ΕΡΓΑΤΙΚΑ', 'ΥΛΙΚΑ', 'ΣΥΝΟΛΟ'],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                  cellStyle: const pw.TextStyle(fontSize: 8),
                  data: breakdown.entries.map((e) {
                    final info = e.value;
                    return [
                      e.key,
                      "${info.labor.toStringAsFixed(2)} €",
                      "${info.materials.toStringAsFixed(2)} €",
                      "${info.total.toStringAsFixed(2)} €",
                    ];
                  }).toList(),
                ),
                pw.SizedBox(height: 15),
              ],
            );
          }).toList(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'MTC_Company_Report.pdf');
  }

  static Future<void> generateAndShareYearlyTaxReport({
    required int year,
    required Map<int, Map<String, double>> monthlyData,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    pw.Font italicFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      italicFont = await PdfGoogleFonts.robotoItalic();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    final months = ["Ιανουάριος", "Φεβρουάριος", "Μάρτιος", "Απρίλιος", "Μάιος", "Ιούνιος", "Ιούλιος", "Αύγουστος", "Σεπτέμβριος", "Οκτώβριος", "Νοέμβριος", "Δεκέμβριος"];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, italic: italicFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 30),
          pw.Center(child: pw.Text("ΕΤΗΣΙΑ ΟΙΚΟΝΟΜΙΚΗ ΑΝΑΦΟΡΑ $year", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: ['ΜΗΝΑΣ', 'ΕΣΟΔΑ (ΚΑΘ.)', 'ΕΞΟΔΑ (ΚΑΘ.)', 'ΦΠΑ ΕΙΣΠ.', 'ΦΠΑ ΠΛΗΡ.'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            data: List.generate(12, (i) {
              final data = monthlyData[i] ?? {'collected': 0.0, 'paid': 0.0};
              return [
                months[i],
                "0.00 €", 
                "0.00 €",
                "${data['collected']!.toStringAsFixed(2)} €",
                "${data['paid']!.toStringAsFixed(2)} €",
              ];
            }),
          ),
          
          pw.SizedBox(height: 40),
          pw.Text("ΣΥΝΟΛΙΚΑ ΕΤΟΥΣ", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'MTC_Yearly_Report_$year.pdf');
  }

  static Future<void> generateAndShareMarketArchive({
    required List<MarketArchiveItem> items,
    required Settings settings,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;
    pw.Font italicFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
      italicFont = await PdfGoogleFonts.robotoItalic();
    } catch (e) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
      italicFont = pw.Font.helveticaOblique();
    }
    final logoImage = settings.logoUri != null ? await _loadLogo(settings.logoUri!) : null;

    // Grouping items by category then subcategory then name
    final grouped = <String, Map<String, Map<String, List<MarketArchiveItem>>>>{};
    for (var item in items) {
      grouped.putIfAbsent(item.category, () => {});
      final catGroup = grouped[item.category]!;
      final subCat = item.subCategory.toUpperCase();
      catGroup.putIfAbsent(subCat, () => {});
      final nameGroup = catGroup[subCat]!;
      final itemName = item.name.toUpperCase();
      nameGroup.putIfAbsent(itemName, () => []).add(item);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, italic: italicFont),
        build: (context) => [
          _buildHeader(settings, logoImage),
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text("ΑΡΧΕΙΟ ΑΓΟΡΩΝ & ΤΙΜΩΝ", 
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Divider(thickness: 1.5),
          pw.SizedBox(height: 20),

          ...grouped.entries.map((catEntry) {
            final category = catEntry.key;
            final subGroups = catEntry.value;
            final dest = AppDestinations.values.firstWhere((d) => d.name == category, orElse: () => AppDestinations.GENERAL);

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  color: PdfColors.blueGrey100,
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(dest.label.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 10),
                ...subGroups.entries.map((subEntry) {
                  final subCat = subEntry.key;
                  final nameGroups = subEntry.value;

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 10, top: 5, bottom: 5),
                        child: pw.Text(subCat, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                      ),
                      ...nameGroups.entries.map((nameEntry) {
                        final itemName = nameEntry.key;
                        final records = nameEntry.value;

                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 20, top: 10, bottom: 5),
                              child: pw.Text(itemName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Table.fromTextArray(
                              headers: ['ΠΡΟΜΗΘΕΥΤΗΣ', 'ΗΜΕΡΟΜΗΝΙΑ', 'ΤΙΜΗ (€)', 'ΦΠΑ'],
                              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                              cellStyle: const pw.TextStyle(fontSize: 8),
                              columnWidths: {
                                0: const pw.FlexColumnWidth(3),
                                1: const pw.FlexColumnWidth(2),
                                2: const pw.FlexColumnWidth(1.5),
                                3: const pw.FlexColumnWidth(1),
                              },
                              data: records.map((i) => [
                                i.supplier.toUpperCase(),
                                DateFormat('dd/MM/yy').format(DateTime.fromMillisecondsSinceEpoch(i.dateAdded)),
                                "${i.price.toStringAsFixed(2)} / ${i.unit}",
                                i.hasVat ? "ΝΑΙ" : "ΟΧΙ",
                              ]).toList(),
                            ),
                            pw.SizedBox(height: 10),
                          ],
                        );
                      }),
                      pw.SizedBox(height: 15),
                    ],
                  );
                }).toList(),
                pw.SizedBox(height: 20),
              ],
            );
          }).toList(),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'MTC_Market_Archive.pdf');
  }

  static pw.Widget _buildPdfBalanceRow(String label, double amount, PdfColor color, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text("${amount.toStringAsFixed(2)} €", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(Settings settings, pw.MemoryImage? logo) {
    return pw.Column(
      children: [
        pw.Container(
          height: 6,
          width: double.infinity,
          color: PdfColors.blue800,
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("ΗΜΕΡΟΜΗΝΙΑ", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now()), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null)
                    pw.Container(
                      height: 70,
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Text(settings.companyName.toUpperCase(), 
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  pw.SizedBox(height: 4),
                  pw.Text(settings.tagline, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.SizedBox(),
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _headerInfoItem("ΥΠΕΥΘΥΝΟΣ", settings.ownerName.toUpperCase()),
              _headerInfoItem("ΤΗΛΕΦΩΝΟ", settings.phone),
              _headerInfoItem("EMAIL", settings.email.toLowerCase()),
              if (settings.vatNumber.isNotEmpty) _headerInfoItem("Α.Φ.Μ.", settings.vatNumber),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _headerInfoItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }
}
