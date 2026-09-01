import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/breakdown_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:intl/intl.dart';

class ExcelExporter {
  static Future<void> _saveAndOpen(Workbook workbook, String fileName) async {
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes);
    OpenFile.open(path);
  }

  static Future<void> exportProjectFinancials(String projectName, List<Expense> expenses, List<Income> incomes) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'ΟΙΚΟΝΟΜΙΚΑ';
    sheet.getRangeByName('A1').setText('ΗΜΕΡΟΜΗΝΙΑ');
    sheet.getRangeByName('B1').setText('ΠΕΡΙΓΡΑΦΗ');
    sheet.getRangeByName('C1').setText('ΣΥΝΕΡΓΑΤΗΣ/ΠΡΟΜΗΘΕΥΤΗΣ');
    sheet.getRangeByName('D1').setText('ΠΟΣΟ (€)');
    sheet.getRangeByName('E1').setText('ΤΥΠΟΣ');
    sheet.getRangeByName('F1').setText('ΚΑΤΗΓΟΡΙΑ');

    int row = 2;
    for (var i in incomes) {
      sheet.getRangeByIndex(row, 1).setText(DateTime.fromMillisecondsSinceEpoch(i.date).toString().split(' ')[0]);
      sheet.getRangeByIndex(row, 2).setText(i.description);
      sheet.getRangeByIndex(row, 3).setText('ΠΕΛΑΤΗΣ');
      sheet.getRangeByIndex(row, 4).setNumber(i.amount);
      sheet.getRangeByIndex(row, 5).setText('ΕΙΣΠΡΑΞΗ');
      row++;
    }
    for (var e in expenses) {
      sheet.getRangeByIndex(row, 1).setText(DateTime.fromMillisecondsSinceEpoch(e.date).toString().split(' ')[0]);
      sheet.getRangeByIndex(row, 2).setText(e.description);
      sheet.getRangeByIndex(row, 3).setText(e.workerName);
      sheet.getRangeByIndex(row, 4).setNumber(e.amount);
      sheet.getRangeByIndex(row, 5).setText(e.expenseType == 'INVOICE' ? 'ΤΙΜΟΛΟΓΙΟ' : 'ΠΛΗΡΩΜΗ');
      sheet.getRangeByIndex(row, 6).setText(e.categoryType);
      row++;
    }
    await _saveAndOpen(workbook, 'MTC_Financials_${projectName.replaceAll(' ', '_')}');
  }

  static Future<void> exportPayroll(String title, List<AttendanceEntity> attendance, List<Expense> payments) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'ΠΑΡΟΥΣΙΟΛΟΓΙΟ';
    sheet.getRangeByName('A1').setText('ΕΡΓΑΤΗΣ');
    sheet.getRangeByName('B1').setText('ΔΕΔΟΥΛΕΥΜΕΝΑ (€)');
    sheet.getRangeByName('C1').setText('ΠΛΗΡΩΜΕΣ (€)');
    sheet.getRangeByName('D1').setText('ΥΠΟΛΟΙΠΟ (€)');

    final workerNames = (attendance.map((e) => e.workerName).toList() + payments.map((e) => e.workerName).toList()).toSet().toList()..sort();
    int row = 2;
    double totalEarned = 0, totalPaid = 0;
    for (var name in workerNames) {
      final earned = attendance.where((a) => a.workerName == name).fold(0.0, (sum, a) => sum + a.dailyRate + a.overtimeAmount);
      final paid = payments.where((p) => p.workerName == name).fold(0.0, (sum, p) => sum + p.amount);
      sheet.getRangeByIndex(row, 1).setText(name.toUpperCase());
      sheet.getRangeByIndex(row, 2).setNumber(earned);
      sheet.getRangeByIndex(row, 3).setNumber(paid);
      sheet.getRangeByIndex(row, 4).setNumber(earned - paid);
      totalEarned += earned;
      totalPaid += paid;
      row++;
    }
    sheet.getRangeByIndex(row, 1).setText('ΣΥΝΟΛΑ');
    sheet.getRangeByIndex(row, 2).setNumber(totalEarned);
    sheet.getRangeByIndex(row, 3).setNumber(totalPaid);
    sheet.getRangeByIndex(row, 4).setNumber(totalEarned - totalPaid);
    await _saveAndOpen(workbook, 'MTC_Payroll_${title.replaceAll(' ', '_')}');
  }

  static Future<void> exportPartners(List<Partner> partners) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'ΣΥΝΕΡΓΑΤΕΣ';
    sheet.getRangeByName('A1').setText('ΟΝΟΜΑΤΕΠΩΝΥΜΟ');
    sheet.getRangeByName('B1').setText('ΤΗΛΕΦΩΝΟ');
    sheet.getRangeByName('C1').setText('ΕΙΔΙΚΟΤΗΤΑ');
    sheet.getRangeByName('D1').setText('ΒΑΣΙΚΟ ΜΕΡΟΚΑΜΑΤΟ');

    int row = 2;
    for (var p in partners) {
      sheet.getRangeByIndex(row, 1).setText(p.name.toUpperCase());
      sheet.getRangeByIndex(row, 2).setText(p.phone);
      sheet.getRangeByIndex(row, 3).setText(p.trade);
      sheet.getRangeByIndex(row, 4).setNumber(p.baseRate);
      row++;
    }
    await _saveAndOpen(workbook, 'MTC_Partners');
  }

  static Future<void> exportClients(List<Client> clients) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'ΠΕΛΑΤΕΣ';
    sheet.getRangeByName('A1').setText('ΟΝΟΜΑΤΕΠΩΝΥΜΟ');
    sheet.getRangeByName('B1').setText('ΤΗΛΕΦΩΝΟ');
    sheet.getRangeByName('C1').setText('EMAIL');
    sheet.getRangeByName('D1').setText('ΚΑΤΑΣΤΑΣΗ');

    int row = 2;
    for (var c in clients) {
      sheet.getRangeByIndex(row, 1).setText(c.name.toUpperCase());
      sheet.getRangeByIndex(row, 2).setText(c.phone);
      sheet.getRangeByIndex(row, 3).setText(c.email);
      sheet.getRangeByIndex(row, 4).setText(c.status);
      row++;
    }
    await _saveAndOpen(workbook, 'MTC_Clients');
  }

  static Future<void> exportTools(List<Tool> tools) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'ΕΡΓΑΛΕΙΑ';
    sheet.getRangeByName('A1').setText('ΟΝΟΜΑΣΙΑ');
    sheet.getRangeByName('B1').setText('ΚΑΤΗΓΟΡΙΑ');
    sheet.getRangeByName('C1').setText('ΤΟΠΟΘΕΣΙΑ');
    sheet.getRangeByName('D1').setText('ΠΟΣΟΤΗΤΑ');
    sheet.getRangeByName('E1').setText('ΣΧΟΛΙΑ');

    int row = 2;
    for (var t in tools) {
      sheet.getRangeByIndex(row, 1).setText(t.name.toUpperCase());
      sheet.getRangeByIndex(row, 2).setText(t.category);
      sheet.getRangeByIndex(row, 3).setText(t.locationType);
      sheet.getRangeByIndex(row, 4).setNumber(t.quantity);
      sheet.getRangeByIndex(row, 5).setText(t.comments);
      row++;
    }
    await _saveAndOpen(workbook, 'MTC_Tools');
  }

  static Future<void> exportCostAnalysis(String projectName, Map<String, CategoryBreakdown> breakdown) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'ΑΝΑΛΥΣΗ ΚΟΣΤΟΥΣ';
    sheet.getRangeByName('A1').setText('ΚΑΤΗΓΟΡΙΑ');
    sheet.getRangeByName('B1').setText('ΕΡΓΑΤΙΚΑ (€)');
    sheet.getRangeByName('C1').setText('ΥΛΙΚΑ (€)');
    sheet.getRangeByName('D1').setText('ΣΥΝΟΛΟ (€)');
    sheet.getRangeByName('E1').setText('ΣΥΜΦΩΝΗΘΕΝ (€)');

    int row = 2;
    double totalLabor = 0, totalMaterials = 0, totalAgreed = 0;
    for (var entry in breakdown.entries) {
      sheet.getRangeByIndex(row, 1).setText(entry.key.toUpperCase());
      sheet.getRangeByIndex(row, 2).setNumber(entry.value.labor);
      sheet.getRangeByIndex(row, 3).setNumber(entry.value.materials);
      sheet.getRangeByIndex(row, 4).setNumber(entry.value.total);
      sheet.getRangeByIndex(row, 5).setNumber(entry.value.agreed);
      totalLabor += entry.value.labor;
      totalMaterials += entry.value.materials;
      totalAgreed += entry.value.agreed;
      row++;
    }
    sheet.getRangeByIndex(row, 1).setText('ΣΥΝΟΛΑ');
    sheet.getRangeByIndex(row, 2).setNumber(totalLabor);
    sheet.getRangeByIndex(row, 3).setNumber(totalMaterials);
    sheet.getRangeByIndex(row, 4).setNumber(totalLabor + totalMaterials);
    sheet.getRangeByIndex(row, 5).setNumber(totalAgreed);
    await _saveAndOpen(workbook, 'MTC_CostAnalysis_${projectName.replaceAll(' ', '_')}');
  }

  static Future<void> exportInvoices(List<Expense> invoices) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'ΤΙΜΟΛΟΓΙΑ';
    sheet.getRangeByName('A1').setText('ΗΜΕΡΟΜΗΝΙΑ');
    sheet.getRangeByName('B1').setText('ΠΕΡΙΓΡΑΦΗ');
    sheet.getRangeByName('C1').setText('ΠΡΟΜΗΘΕΥΤΗΣ');
    sheet.getRangeByName('D1').setText('ΑΡ. ΤΙΜΟΛΟΓΙΟΥ');
    sheet.getRangeByName('E1').setText('ΠΟΣΟ (€)');

    int row = 2;
    for (var i in invoices) {
      sheet.getRangeByIndex(row, 1).setText(DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(i.date)));
      sheet.getRangeByIndex(row, 2).setText(i.description.toUpperCase());
      sheet.getRangeByIndex(row, 3).setText(i.workerName.toUpperCase());
      sheet.getRangeByIndex(row, 4).setText(i.invoiceNumber ?? "");
      sheet.getRangeByIndex(row, 5).setNumber(i.amount);
      row++;
    }
    await _saveAndOpen(workbook, 'MTC_Invoices');
  }

  static Future<void> exportMarketArchive(List<MarketArchiveItem> items) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'ΑΡΧΕΙΟ ΑΓΟΡΩΝ';

    // Headers
    sheet.getRangeByName('A1').setText('ΚΥΡΙΑ ΚΑΤΗΓΟΡΙΑ');
    sheet.getRangeByName('B1').setText('ΥΠΟΚΑΤΗΓΟΡΙΑ');
    sheet.getRangeByName('C1').setText('ΥΛΙΚΟ / ΕΡΓΑΛΕΙΟ');
    sheet.getRangeByName('D1').setText('ΠΡΟΜΗΘΕΥΤΗΣ');
    sheet.getRangeByName('E1').setText('ΗΜΕΡΟΜΗΝΙΑ');
    sheet.getRangeByName('F1').setText('ΤΙΜΗ (€)');
    sheet.getRangeByName('G1').setText('ΜΟΝΑΔΑ');
    sheet.getRangeByName('H1').setText('ΦΠΑ');

    // Grouping
    final Map<String, Map<String, Map<String, List<MarketArchiveItem>>>> grouped = {};
    for (var item in items) {
      grouped.putIfAbsent(item.category, () => {});
      final catGroup = grouped[item.category]!;
      final subCat = item.subCategory.toUpperCase();
      catGroup.putIfAbsent(subCat, () => {});
      final nameGroup = catGroup[subCat]!;
      final itemName = item.name.toUpperCase();
      nameGroup.putIfAbsent(itemName, () => []).add(item);
    }

    int row = 2;
    for (var catEntry in grouped.entries) {
      final dest = AppDestinations.values.firstWhere((d) => d.name == catEntry.key, orElse: () => AppDestinations.GENERAL);
      for (var subEntry in catEntry.value.entries) {
        for (var nameEntry in subEntry.value.entries) {
          for (var i in nameEntry.value) {
            sheet.getRangeByIndex(row, 1).setText(dest.label.toUpperCase());
            sheet.getRangeByIndex(row, 2).setText(subEntry.key);
            sheet.getRangeByIndex(row, 3).setText(nameEntry.key);
            sheet.getRangeByIndex(row, 4).setText(i.supplier.toUpperCase());
            sheet.getRangeByIndex(row, 5).setText(DateFormat('dd/MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(i.dateAdded)));
            sheet.getRangeByIndex(row, 6).setNumber(i.price);
            sheet.getRangeByIndex(row, 7).setText(i.unit);
            sheet.getRangeByIndex(row, 8).setText(i.hasVat ? 'ΝΑΙ' : 'ΟΧΙ');
            row++;
          }
        }
      }
    }

    await _saveAndOpen(workbook, 'MTC_MarketArchive');
  }
}
