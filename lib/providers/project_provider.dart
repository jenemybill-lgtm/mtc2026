import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtc2026/database/database_helper.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/models/breakdown_models.dart';
import 'package:mtc2026/models/enums.dart';
import 'package:mtc2026/models/alert_model.dart';
import 'package:mtc2026/utils/api_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProjectProvider with ChangeNotifier {
  List<Project> _projects = [];
  List<Client> _clients = [];
  List<Partner> _partners = [];
  List<Task> _tasks = [];
  List<CompanyExpenseEntity> _companyExpenses = [];
  List<String> _materialCategories = [];
  List<String> _toolCategories = [];
  List<String> _marketSubCategories = [];
  List<Income> _currentProjectIncomes = [];
  List<Expense> _currentProjectExpenses = [];
  List<QuoteItem> _currentProjectQuoteItems = [];
  List<ProjectNote> _currentProjectNotes = [];
  List<ProjectSketch> _currentProjectSketches = [];
  List<ProjectDocument> _currentProjectDocuments = [];
  Settings _settings = Settings();
  Map<String, double> _dashboardStats = {'income': 0.0, 'expense': 0.0};
  List<SystemAlert> _alerts = [];
  bool _hasDownloadedOnWeb = false;
  bool _hasLoadedLocalCache = false;
  List<Manager> _managers = [];
  int? _currentManagerId;

  List<Project> get projects => _projects;
  List<Client> get clients => _clients;
  List<Partner> get partners => _partners;
  List<Task> get tasks => _tasks;
  List<CompanyExpenseEntity> get companyExpenses => _companyExpenses;
  List<String> get materialCategories => _materialCategories;
  List<String> get toolCategories => _toolCategories;
  List<String> get marketSubCategories => _marketSubCategories;
  List<Income> get currentProjectIncomes => _currentProjectIncomes;
  List<Expense> get currentProjectExpenses => _currentProjectExpenses;
  List<QuoteItem> get currentProjectQuoteItems => _currentProjectQuoteItems;
  List<ProjectNote> get currentProjectNotes => _currentProjectNotes;
  List<ProjectSketch> get currentProjectSketches => _currentProjectSketches;
  List<ProjectDocument> get currentProjectDocuments => _currentProjectDocuments;
  Settings get settings => _settings;
  Map<String, double> get dashboardStats => _dashboardStats;
  List<SystemAlert> get alerts => _alerts;
  List<Manager> get managers => _managers;
  int? get currentManagerId => _currentManagerId;

  Timer? _syncTimer;

  ProjectProvider() {
    _initPeriodicSync();
  }

  void _initPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool('is_logged_in') ?? false) {
          final response = await ApiClient().get("/api/sync/download");
          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            await DatabaseHelper().importDataFromSync(responseData);
            await fetchProjects();
          }
        }
      } catch (e) {
        debugPrint("Background Sync Error: $e");
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> setCurrentManagerId(int? id) async {
    _currentManagerId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove('current_manager_id');
    } else {
      await prefs.setInt('current_manager_id', id);
    }
    await fetchProjects();
  }

  double get totalQuoteRevenue => _currentProjectQuoteItems.fold(
    0.0,
    (sum, item) => sum + item.priceForClient,
  );

  Future<void> refreshAlerts() async {
    final List<SystemAlert> newAlerts = [];
    final now = DateTime.now();

    try {
      final db = DatabaseHelper();
      final vehicle = await db.getVehicle();
      final insDiff = DateTime.fromMillisecondsSinceEpoch(
        vehicle.insuranceExpiry,
      ).difference(now).inDays;
      if (insDiff < 15) {
        newAlerts.add(
          SystemAlert(
            title: "Ασφάλεια Βαν",
            message: insDiff <= 0 ? "Έχει λήξει!" : "Λήγει σε $insDiff ημέρες",
            icon: Icons.verified_user_rounded,
            color: insDiff <= 0 ? Colors.red : Colors.orange,
            type: insDiff <= 0 ? AlertType.error : AlertType.warning,
          ),
        );
      }

      final kteoDiff = DateTime.fromMillisecondsSinceEpoch(vehicle.kteoExpiry)
          .difference(now)
          .inDays;
      if (kteoDiff < 15) {
        newAlerts.add(
          SystemAlert(
            title: "ΚΤΕΟ",
            message: kteoDiff <= 0
                ? "Έχει λήξει!"
                : "Λήγει σε $kteoDiff ημέρες",
            icon: Icons.car_repair_rounded,
            color: kteoDiff <= 0 ? Colors.red : Colors.orange,
            type: kteoDiff <= 0 ? AlertType.error : AlertType.warning,
          ),
        );
      }

      final allMaterials =
          await db.getMaterials(null, "WAREHOUSE", "ΟΛΑ") +
          await db.getMaterials(null, "VAN", "ΟΛΑ");
      for (var m in allMaterials) {
        if (m.minStockThreshold > 0 && m.quantity <= m.minStockThreshold) {
          newAlerts.add(
            SystemAlert(
              title: "Έλλειψη Υλικού",
              message: "${m.name} (${m.quantity} ${m.unit})",
              icon: Icons.inventory_2_rounded,
              color: Colors.red,
              type: AlertType.error,
            ),
          );
        }
      }

      for (var t in _tasks) {
        if (!t.isCompleted) {
          final taskDate = DateTime.fromMillisecondsSinceEpoch(t.date);
          if (taskDate.year == now.year &&
              taskDate.month == now.month &&
              taskDate.day == now.day) {
            newAlerts.add(
              SystemAlert(
                title: "Εκκρεμής Εργασία",
                message: t.description,
                icon: Icons.assignment_late_rounded,
                color: Colors.blue,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error refreshing alerts: $e");
    }

    _alerts = newAlerts;
    notifyListeners();
  }

  Future<void> calculateDashboardStats() async {
    try {
      final db = DatabaseHelper();
      final allIncomes = await db.getAllIncomes();
      final allProjectExpenses = await db.getAllExpenses();
      final allCompanyExpenses = await db.getCompanyExpenses();

      debugPrint(
        "Stats Calc: Incomes=${allIncomes.length}, ProjectExps=${allProjectExpenses.length}, CompanyExps=${allCompanyExpenses.length}",
      );

      final income = allIncomes.fold(
        0.0,
        (sum, i) => sum + (i.hasVat ? i.amount / 1.24 : i.amount),
      );
      final totalExpense =
          allProjectExpenses.fold(
            0.0,
            (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount),
          ) +
          allCompanyExpenses.fold(
            0.0,
            (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount),
          );

      final vatCollected = allIncomes.fold(
        0.0,
        (sum, i) => sum + (i.hasVat ? i.amount - (i.amount / 1.24) : 0),
      );
      final vatPaid =
          (allProjectExpenses.fold(
            0.0,
            (sum, e) => sum + (e.hasVat ? e.amount - (e.amount / 1.24) : 0),
          ) +
          allCompanyExpenses.fold(
            0.0,
            (sum, e) => sum + (e.hasVat ? e.amount - (e.amount / 1.24) : 0),
          ));

      _dashboardStats = {
        'income': income,
        'expense': totalExpense,
        'vatCollected': vatCollected,
        'vatPaid': vatPaid,
        'vatBalance': vatCollected - vatPaid,
      };
      debugPrint("Stats Calc: Final Income=$income, Expense=$totalExpense");
      notifyListeners();
    } catch (e) {
      debugPrint("Error calculating stats: $e");
    }
  }

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<bool> manualUploadToCloud() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('is_logged_in') ?? false)) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      final data = await DatabaseHelper().getAllDataForSync();
      print("Sync: Uploading ${data.keys.length} tables...");
      
      final response = await ApiClient().post("/api/sync/upload", {
        "data": data,
      });
      
      if (response.statusCode == 200) {
        print("Sync: Upload Successful");
        return true;
      } else {
        print("Sync: Upload Failed (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Sync: Upload Error: $e");
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> manualDownloadFromCloud() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('is_logged_in') ?? false)) return false;

    _isSyncing = true;
    notifyListeners();

    try {
      print("Sync: Downloading data from cloud...");
      final response = await ApiClient().get("/api/sync/download");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        await DatabaseHelper().importDataFromSync(responseData);
        await fetchProjects();
        print("Sync: Download Successful");
        return true;
      } else {
        print("Sync: Download Failed (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Sync: Download Error: $e");
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<Map<String, double>> getDashboardStats() async {
    await calculateDashboardStats();
    return _dashboardStats;
  }

  Future<void> clearLocalData() async {
    await DatabaseHelper().clearAllData();
    await fetchProjects();
  }

  Future<void> fetchProjects() async {
    // 0. Load Local Cache on Web
    if (kIsWeb && !_hasLoadedLocalCache) {
      _hasLoadedLocalCache = true;
      await DatabaseHelper().loadWebMemoryFromLocal();
    }

    // 1. Auto-download at startup if logged in
    if (!_hasDownloadedOnWeb) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('is_logged_in') ?? false) {
        _hasDownloadedOnWeb = true;
        debugPrint("Startup: Auto-downloading data from cloud...");
        await manualDownloadFromCloud();
        return; 
      }
    }

    final prefs = await SharedPreferences.getInstance();
    _currentManagerId = prefs.getInt('current_manager_id');

    final db = DatabaseHelper();

    // 1. Critical Core Data
    try {
      final allProjects = await db.getProjects();
      if (_currentManagerId != null && _currentManagerId! > 0) {
        _projects = allProjects.where((p) => p.managerId == _currentManagerId).toList();
      } else {
        _projects = allProjects;
      }
      _clients = await db.getClients();
      _managers = await db.getManagers();
      _settings = await _loadSettings();
      debugPrint("Loaded ${_projects.length} projects and settings.");
    } catch (e) {
      debugPrint("ERROR loading Core Data: $e");
    }

    // 2. Secondary Management Data
    try {
      _partners = await db.getPartners();
      _tasks = await db.getTasks();
      _companyExpenses = await db.getCompanyExpenses();
      _materialCategories = await db.getMaterialCategories();
      _toolCategories = await db.getToolCategories();
      _marketSubCategories = await db.getMarketSubCategories();
    } catch (e) {
      debugPrint("ERROR loading Secondary Data: $e");
    }

    // 3. Market Archive & Seeding
    try {
      final archive = await db.getMarketArchive();
      if (archive.isEmpty) {
        await _seedBasics(db);
        _marketSubCategories = await db.getMarketSubCategories();
      }
    } catch (e) {
      debugPrint("ERROR loading Market Archive: $e");
    }

    // 4. Always attempt to calculate stats regardless of secondary errors
    await calculateDashboardStats();
    await refreshAlerts();

    notifyListeners();
  }

  Future<Settings> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseHelper();
    
    // Load local settings from SharedPreferences
    final settingsJson = prefs.getString('app_settings');
    Map<String, dynamic> combinedMap = {};
    if (settingsJson != null) {
      combinedMap = Map<String, dynamic>.from(jsonDecode(settingsJson));
    }

    // Load global settings from Database
    final globalData = await db.getGlobalSettings();
    if (globalData != null) {
      combinedMap.addAll(globalData);
    }

    if (combinedMap.isNotEmpty) {
      return Settings.fromMap(combinedMap);
    }
    return Settings();
  }

  Future<void> fetchProjectData(int projectId) async {
    final db = DatabaseHelper();
    _currentProjectIncomes = await db.getIncomes(projectId);
    _currentProjectExpenses = await db.getExpenses(projectId);
    _currentProjectQuoteItems = await db.getQuoteItems(projectId);
    _currentProjectNotes = await db.getProjectNotes(projectId);
    _currentProjectSketches = await db.getProjectSketches(projectId);
    _currentProjectDocuments = await db.getProjectDocuments(projectId);
    notifyListeners();
  }

  Future<void> _autoSync() async {
    try {
      // Non-blocking upload to cloud on all platforms
      manualUploadToCloud();
    } catch (e) {
      debugPrint("AutoSync Error: $e");
    }
  }

  // --- CRUD METHODS ---
  Future<void> addProject(Project p) async {
    await DatabaseHelper().insertProject(p);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> updateProject(Project p) async {
    await DatabaseHelper().updateProject(p);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> deleteProject(int id) async {
    await DatabaseHelper().deleteProject(id);
    await fetchProjects();
    await _autoSync();
  }

  Future<List<Project>> getProjectsForClient(int clientId) async =>
      await DatabaseHelper().getProjectsForClient(clientId);

  Future<void> addClient(Client c) async {
    await DatabaseHelper().insertClient(c);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> updateClient(Client c) async {
    await DatabaseHelper().updateClient(c);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> deleteClient(int id) async {
    await DatabaseHelper().deleteClient(id);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> addPartner(Partner p) async {
    await DatabaseHelper().insertPartner(p);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> updatePartner(Partner p) async {
    await DatabaseHelper().updatePartner(p);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> deletePartner(int id) async {
    await DatabaseHelper().deletePartner(id);
    await fetchProjects();
    await _autoSync();
  }

  // --- MANAGERS ---
  Future<void> addManager(Manager m) async {
    await DatabaseHelper().insertManager(m);
    _managers = await DatabaseHelper().getManagers();
    notifyListeners();
  }

  Future<void> updateManager(Manager m) async {
    await DatabaseHelper().updateManager(m);
    _managers = await DatabaseHelper().getManagers();
    notifyListeners();
  }

  Future<void> deleteManager(int id) async {
    await DatabaseHelper().deleteManager(id);
    _managers = await DatabaseHelper().getManagers();
    notifyListeners();
  }

  // --- PROJECT NOTES ---
  Future<void> addProjectNote(ProjectNote note) async {
    await DatabaseHelper().insertProjectNote(note);
    await fetchProjectData(note.projectId);
    await _autoSync();
  }

  Future<void> updateProjectNote(ProjectNote note) async {
    await DatabaseHelper().updateProjectNote(note);
    await fetchProjectData(note.projectId);
    await _autoSync();
  }

  Future<void> deleteProjectNote(int projectId, int noteId) async {
    await DatabaseHelper().deleteProjectNote(noteId);
    await fetchProjectData(projectId);
    await _autoSync();
  }

  // Sketches
  Future<void> addProjectSketch(ProjectSketch sketch) async {
    await DatabaseHelper().insertProjectSketch(sketch);
    await fetchProjectData(sketch.projectId);
    await _autoSync();
  }

  Future<void> deleteProjectSketch(int projectId, int sketchId) async {
    await DatabaseHelper().deleteProjectSketch(sketchId);
    await fetchProjectData(projectId);
    await _autoSync();
  }

  // Documents
  Future<void> addProjectDocument(ProjectDocument doc) async {
    await DatabaseHelper().insertProjectDocument(doc);
    await fetchProjectData(doc.projectId);
    await _autoSync();
  }

  Future<void> deleteProjectDocument(int projectId, int docId) async {
    await DatabaseHelper().deleteProjectDocument(docId);
    await fetchProjectData(projectId);
    await _autoSync();
  }

  // --- PROJECT PARTNERS ---
  Future<List<Partner>> getPartnersForProject(int projectId) async =>
      await DatabaseHelper().getPartnersForProject(projectId);
  Future<void> addPartnerToProject(int projectId, int partnerId) async {
    await DatabaseHelper().addPartnerToProject(projectId, partnerId);
    notifyListeners();
    await _autoSync();
  }

  Future<void> removePartnerFromProject(int projectId, int partnerId) async {
    await DatabaseHelper().removePartnerFromProject(projectId, partnerId);
    notifyListeners();
    await _autoSync();
  }

  // --- PARTNER AGREEMENTS ---
  Future<List<PartnerAgreement>> getPartnerAgreements(int projectId) async =>
      await DatabaseHelper().getPartnerAgreements(projectId);
  Future<void> addPartnerAgreement(PartnerAgreement agreement) async {
    await DatabaseHelper().insertPartnerAgreement(agreement);
    notifyListeners();
    await _autoSync();
  }

  Future<void> updatePartnerAgreement(PartnerAgreement agreement) async {
    await DatabaseHelper().updatePartnerAgreement(agreement);
    notifyListeners();
    await _autoSync();
  }

  Future<void> deletePartnerAgreement(int id) async {
    await DatabaseHelper().deletePartnerAgreement(id);
    notifyListeners();
    await _autoSync();
  }

  Future<void> addTask(Task t) async {
    await DatabaseHelper().insertTask(t);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> updateTask(Task t) async {
    await DatabaseHelper().updateTask(t);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> deleteTask(int id) async {
    await DatabaseHelper().deleteTask(id);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> addQuoteItem(int pid, QuoteItem item) async {
    await DatabaseHelper().insertQuoteItem(pid, item);
    await fetchProjectData(pid);
    await _autoSync();
  }

  Future<void> updateQuoteItem(int pid, QuoteItem item) async {
    await DatabaseHelper().updateQuoteItem(pid, item);
    await fetchProjectData(pid);
    await _autoSync();
  }

  Future<void> deleteQuoteItem(int pid, int id) async {
    await DatabaseHelper().deleteQuoteItem(id);
    await fetchProjectData(pid);
    await _autoSync();
  }

  Future<void> addIncome(int pid, Income i) async {
    await DatabaseHelper().insertIncome(i);
    await fetchProjectData(pid);
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<void> updateIncome(int pid, Income i) async {
    await DatabaseHelper().updateIncome(i);
    await fetchProjectData(pid);
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<void> deleteIncome(int pid, int id) async {
    await DatabaseHelper().deleteIncome(id);
    await fetchProjectData(pid);
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<void> addExpense(int pid, Expense e) async {
    await DatabaseHelper().insertExpense(e);
    await fetchProjectData(pid);
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<void> updateExpense(int pid, Expense e) async {
    await DatabaseHelper().updateExpense(e);
    await fetchProjectData(pid);
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<void> deleteExpense(int pid, int id) async {
    await DatabaseHelper().deleteExpense(id);
    await fetchProjectData(pid);
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<List<Expense>> getAllExpenses() async => await DatabaseHelper().getAllExpenses();

  // --- MATERIALS ---
  Future<List<MaterialEntity>> getMaterials(
    int? pid,
    String loc,
    String cat,
  ) async => await DatabaseHelper().getMaterials(pid, loc, cat);
  Future<void> addMaterial(MaterialEntity m) async {
    await DatabaseHelper().insertMaterial(m);
    notifyListeners();
    await _autoSync();
  }

  Future<void> updateMaterial(MaterialEntity m) async {
    await DatabaseHelper().updateMaterial(m);
    notifyListeners();
    await _autoSync();
  }

  Future<void> deleteMaterial(int id) async {
    await DatabaseHelper().deleteMaterial(id);
    notifyListeners();
    await _autoSync();
  }

  Future<void> addMaterialCategory(String name) async {
    await DatabaseHelper().insertMaterialCategory(name);
    await fetchProjects();
    await _autoSync();
  }

  // --- TOOLS ---
  Future<List<Tool>> getTools(int? pid, String loc, String cat) async =>
      await DatabaseHelper().getTools(pid, loc, cat);
  Future<void> addTool(Tool t) async {
    await DatabaseHelper().insertTool(t);
    notifyListeners();
    await _autoSync();
  }

  Future<void> updateTool(Tool t) async {
    await DatabaseHelper().updateTool(t);
    notifyListeners();
    await _autoSync();
  }

  Future<void> deleteTool(int id) async {
    await DatabaseHelper().deleteTool(id);
    notifyListeners();
    await _autoSync();
  }

  Future<void> addToolCategory(String name) async {
    await DatabaseHelper().insertToolCategory(name);
    await fetchProjects();
    await _autoSync();
  }

  // --- ATTENDANCE ---
  Future<void> addAttendance(AttendanceEntity r) async {
    await DatabaseHelper().insertAttendance(r);
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<void> addMultipleAttendance(List<AttendanceEntity> records) async {
    for (var r in records) {
      await DatabaseHelper().insertAttendance(r);
    }
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<void> updateAttendance(AttendanceEntity r) async {
    await DatabaseHelper().updateAttendance(r);
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<void> deleteAttendance(int id) async {
    await DatabaseHelper().deleteAttendance(id);
    await calculateDashboardStats();
    await _autoSync();
  }

  Future<List<AttendanceEntity>> getAttendance(int? pid, int? s, int? e) async =>
      await DatabaseHelper().getAttendance(pid, s, e);

  Future<List<AttendanceEntity>> getAttendanceInRange(int s, int e) async =>
      await DatabaseHelper().getAttendance(null, s, e);
  Future<List<Expense>> getPaymentsInRange(int s, int e) async =>
      await DatabaseHelper().getPayments(s, e);

  // --- VEHICLE ---
  Future<VehicleEntity> getVehicle() async =>
      await DatabaseHelper().getVehicle();
  Future<void> updateVehicle(VehicleEntity v) async {
    await DatabaseHelper().updateVehicle(v);
    notifyListeners();
    await _autoSync();
  }

  Future<List<VehicleMaintenanceEntity>> getMaintenance(int vid) async =>
      await DatabaseHelper().getMaintenance(vid);
  Future<void> addMaintenance(
    VehicleMaintenanceEntity m,
    bool addAsExpense,
  ) async {
    await DatabaseHelper().insertMaintenance(m);
    if (addAsExpense) {
      await addCompanyExpense(
        CompanyExpenseEntity(
          description: "ΣΥΝΤΗΡΗΣΗ: ${m.description}",
          amount: m.cost,
          date: m.date,
        ),
      );
    }
    notifyListeners();
    await _autoSync();
  }

  Future<void> deleteMaintenance(int id) async {
    await DatabaseHelper().deleteMaintenance(id);
    notifyListeners();
    await _autoSync();
  }

  // --- SHOPPING LIST ---
  Future<List<ShoppingItemEntity>> getShoppingList(int pid) async =>
      await DatabaseHelper().getShoppingList(pid);
  Future<void> addShoppingItem(ShoppingItemEntity item) async {
    await DatabaseHelper().insertShoppingItem(item);
    notifyListeners();
    await _autoSync();
  }

  Future<void> updateShoppingItem(ShoppingItemEntity item) async {
    await DatabaseHelper().updateShoppingItem(item);
    notifyListeners();
    await _autoSync();
  }

  Future<void> deleteShoppingItem(int id) async {
    await DatabaseHelper().deleteShoppingItem(id);
    notifyListeners();
    await _autoSync();
  }

  // --- GLOBAL PRICES ---
  Future<List<GlobalPriceEntity>> getGlobalPrices(String cat) async =>
      await DatabaseHelper().getGlobalPrices(cat);
  Future<void> addGlobalPrice(GlobalPriceEntity p) async {
    await DatabaseHelper().insertGlobalPrice(p);
    notifyListeners();
    await _autoSync();
  }

  Future<void> updateGlobalPrice(GlobalPriceEntity p) async {
    await DatabaseHelper().updateGlobalPrice(p);
    notifyListeners();
    await _autoSync();
  }

  Future<void> deleteGlobalPrice(int id) async {
    await DatabaseHelper().deleteGlobalPrice(id);
    notifyListeners();
    await _autoSync();
  }

  // --- MARKET ARCHIVE ---
  Future<List<MarketArchiveItem>> getMarketArchive() async =>
      await DatabaseHelper().getMarketArchive();
  Future<void> addMarketArchiveItem(MarketArchiveItem item) async {
    await DatabaseHelper().insertMarketArchiveItem(item);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> updateMarketArchiveItem(MarketArchiveItem item) async {
    await DatabaseHelper().updateMarketArchiveItem(item);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> deleteMarketArchiveItem(int id) async {
    await DatabaseHelper().deleteMarketArchiveItem(id);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> addMarketSubCategory(String name) async {
    await DatabaseHelper().insertMarketSubCategory(name);
    _marketSubCategories = await DatabaseHelper().getMarketSubCategories();
    notifyListeners();
    await _autoSync();
  }

  Future<void> deleteMarketSubCategory(String name) async {
    await DatabaseHelper().deleteMarketSubCategory(name);
    _marketSubCategories = await DatabaseHelper().getMarketSubCategories();
    notifyListeners();
    await _autoSync();
  }

  // --- PARTNER BIDS ---
  Future<List<PartnerBid>> getPartnerBids(int projectId) async => await DatabaseHelper().getPartnerBids(projectId);
  Future<void> addPartnerBid(PartnerBid bid) async { await DatabaseHelper().insertPartnerBid(bid); notifyListeners(); await _autoSync(); }
  Future<void> updatePartnerBid(PartnerBid bid) async { await DatabaseHelper().updatePartnerBid(bid); notifyListeners(); await _autoSync(); }
  Future<void> deletePartnerBid(int id) async { await DatabaseHelper().deletePartnerBid(id); notifyListeners(); await _autoSync(); }

  // --- JOB RECIPES ---
  Future<List<JobRecipe>> getJobRecipes() async => await DatabaseHelper().getJobRecipes();
  Future<void> addJobRecipe(JobRecipe recipe) async { await DatabaseHelper().insertJobRecipe(recipe); notifyListeners(); await _autoSync(); }
  Future<void> deleteJobRecipe(int id) async { await DatabaseHelper().deleteJobRecipe(id); notifyListeners(); await _autoSync(); }

  // --- PORTFOLIO ---
  Future<List<PortfolioItem>> getPortfolio() async => await DatabaseHelper().getPortfolio();
  Future<void> addPortfolioItem(PortfolioItem item) async { await DatabaseHelper().insertPortfolioItem(item); notifyListeners(); await _autoSync(); }
  Future<void> deletePortfolioItem(int id) async { await DatabaseHelper().deletePortfolioItem(id); notifyListeners(); await _autoSync(); }

  // --- PROJECT CHECKLISTS ---
  Future<List<ProjectChecklistItem>> getProjectChecklist(int projectId) async => await DatabaseHelper().getProjectChecklist(projectId);
  Future<void> addChecklistItem(ProjectChecklistItem item) async { await DatabaseHelper().insertChecklistItem(item); notifyListeners(); await _autoSync(); }
  Future<void> updateChecklistItem(ProjectChecklistItem item) async { await DatabaseHelper().updateChecklistItem(item); notifyListeners(); await _autoSync(); }
  Future<void> deleteChecklistItem(int id) async { await DatabaseHelper().deleteChecklistItem(id); notifyListeners(); await _autoSync(); }

  // --- SETTINGS ---
  Future<void> updateSettings(Settings s) async {
    _settings = s;
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseHelper();

    // Save Local Settings
    final localMap = {
      'ownerName': s.ownerName,
      'phone': s.phone,
      'email': s.email,
      'vatNumber': s.vatNumber,
      'appTheme': s.appTheme,
      'isPaymentReminderEnabled': s.isPaymentReminderEnabled ? 1 : 0,
      'dbApiUrl': s.dbApiUrl,
    };
    await prefs.setString('app_settings', jsonEncode(localMap));

    // Save Global Settings (to Database for sync)
    final globalMap = {
      'id': 1,
      'companyName': s.companyName,
      'tagline': s.tagline,
      'logoUri': s.logoUri,
      'aiApiUrl': s.aiApiUrl,
      'aiApiKey': s.aiApiKey,
    };
    await db.updateGlobalSettings(globalMap);

    notifyListeners();
    await _autoSync();
  }

  // --- FINANCIALS & BREAKDOWN ---
  Future<ProjectROIData> calculateProjectROIData(int projectId) async {
    final db = DatabaseHelper();
    final quoteItems = await db.getQuoteItems(projectId);
    final incomes = await db.getIncomes(projectId);
    final expenses = await db.getExpenses(projectId);
    final attendance = await db.getAttendance(projectId, null, null);

    final quote = quoteItems.fold(0.0, (sum, i) => sum + i.netPriceForClient);
    final actual = incomes.fold(
      0.0,
      (sum, i) => sum + (i.hasVat ? i.amount / 1.24 : i.amount),
    );

    // Distinguish Labor vs Materials using categoryType
    // Fetch partners to identify who is a "Worker"
    final allPartners = await db.getPartners();

    // 1. Labor from Expenses table (Invoices or Professional Payments)
    final professionalLabor = expenses
        .where((e) {
          final name = e.workerName.toUpperCase();
          final desc = e.description.toUpperCase();
          
          // Safety: If worker is Generic or contains material keywords, it's NOT labor
          if (name == "ΓΕΝΙΚΟ / ΑΓΟΡΑ" || name.contains("ΥΛΙΚΑ") || name.contains("ΑΓΟΡΑ")) return false;
          if (desc.contains("ΥΛΙΚΑ") || desc.contains("ΑΓΟΡΑ") || desc.contains("ΤΙΜΟΛΟΓΙΟ")) return false;
          
          if (e.categoryType != "LABOR") return false;

          // Normalize names for comparison
          final expName = e.workerName.trim().toLowerCase();

          // Try to find the partner.
          final partner = allPartners.firstWhere(
            (p) => p.name.trim().toLowerCase() == expName,
            orElse: () => Partner(name: "", trade: "Professional", phone: ""),
          );

          // If trade is "Εργάτης" AND it's a PAYMENT (not an invoice),
          // it's likely an advance payment ("έναντι") which shouldn't be counted as earned cost yet.
          // The earned cost comes from the Attendance table below.
          if (partner.trade == "Εργάτης" && e.expenseType == "PAYMENT")
            return false;

          return true;
        })
        .fold(0.0, (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount));

    // 2. Materials from Expenses table
    final materialExps = expenses
        .where((e) {
          final name = e.workerName.toUpperCase();
          final desc = e.description.toUpperCase();
          final isGeneric = name == "ΓΕΝΙΚΟ / ΑΓΟΡΑ" || name.contains("ΥΛΙΚΑ") || name.contains("ΑΓΟΡΑ");
          final hasMaterialKeyword = desc.contains("ΥΛΙΚΑ") || desc.contains("ΑΓΟΡΑ") || desc.contains("ΤΙΜΟΛΟΓΙΟ");
          
          return e.categoryType == "MATERIAL" || isGeneric || hasMaterialKeyword;
        })
        .fold(0.0, (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount));

    // 3. Earned wages from Attendance table
    final attendanceLabor = attendance.fold(
      0.0,
      (sum, a) => sum + a.dailyRate + a.overtimeAmount,
    );

    final totalLabor = professionalLabor + attendanceLabor;
    final totalSpent = totalLabor + materialExps;
    final profit = actual - totalSpent;

    return ProjectROIData(
      quoteAmount: quote,
      actualIncome: actual,
      laborCosts: totalLabor,
      materialExpenses: materialExps,
      fixedCostsContribution: 0.0,
      netProfit: profit,
      roiPercentage: actual > 0 ? (profit / actual) * 100 : 0.0,
      realNetProfit: profit,
      realRoiPercentage: actual > 0 ? (profit / actual) * 100 : 0.0,
    );
  }

  ProjectROIData getProjectROIData(int projectId) {
    // This is a synchronous placeholder. Screens should use calculateProjectROIData (async).
    return ProjectROIData(
      quoteAmount: 0,
      actualIncome: 0,
      laborCosts: 0,
      materialExpenses: 0,
      fixedCostsContribution: 0,
      netProfit: 0,
      roiPercentage: 0,
      realNetProfit: 0,
      realRoiPercentage: 0,
    );
  }

  Future<Map<String, dynamic>> getCompanyAnalyticalFinancials() async {
    double totalActualIncome = 0;
    double totalLabor = 0;
    double totalMaterials = 0;
    double totalProjectProfit = 0;

    for (var project in _projects) {
      final roi = await calculateProjectROIData(project.id);
      totalActualIncome += roi.actualIncome;
      totalLabor += roi.laborCosts;
      totalMaterials += roi.materialExpenses;
      totalProjectProfit += roi.netProfit;
    }

    final db = DatabaseHelper();
    final allQuoteItems = await db.getAllQuoteItems();
    double totalQuotes = allQuoteItems.fold(
      0.0,
      (sum, i) => sum + QuoteItem.fromMap(i).netPriceForClient,
    );

    final allFixedExps = await db.getCompanyExpenses();
    double fixedSum = allFixedExps.fold(
      0.0,
      (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount),
    );

    final allIncomes = await db.getAllIncomes();
    final allProjectExps = await db.getAllExpenses();
    double vatCollected = allIncomes.fold(
      0.0,
      (sum, i) => sum + (i.hasVat ? i.amount - (i.amount / 1.24) : 0),
    );
    double vatPaid =
        allProjectExps.fold(
          0.0,
          (sum, e) => sum + (e.hasVat ? e.amount - (e.amount / 1.24) : 0),
        ) +
        allFixedExps.fold(
          0.0,
          (sum, e) => sum + (e.hasVat ? e.amount - (e.amount / 1.24) : 0),
        );

    return {
      'totalQuotes': totalQuotes,
      'actualIncome': totalActualIncome,
      'labor': totalLabor,
      'materials': totalMaterials,
      'fixed': fixedSum,
      'projectProfit': totalProjectProfit,
      'vatCollected': vatCollected,
      'vatPaid': vatPaid,
    };
  }

  Future<Map<String, CategoryBreakdown>> getProjectDetailedBreakdown(
    int projectId,
  ) async {
    final db = DatabaseHelper();
    final expenses = await db.getExpenses(projectId);
    final quoteItems = await db.getQuoteItems(projectId);
    final attendance = await db.getAttendance(projectId, null, null);

    final Map<String, CategoryBreakdown> breakdown = {};

    String normalize(String cat) {
      final dest = AppDestinations.values.firstWhere(
        (d) => d.label == cat || d.name == cat,
        orElse: () => AppDestinations.GENERAL,
      );
      return dest.label;
    }

    final laborGroups = <String, List<AttendanceEntity>>{};
    final laborExpensesGroups = <String, List<Expense>>{};
    final materialGroups = <String, List<Expense>>{};

    for (var att in attendance) {
      final cat = normalize(
        att.workCategory.isEmpty ? "ΓΕΝΙΚΑ" : att.workCategory,
      );
      laborGroups.putIfAbsent(cat, () => []).add(att);
    }

    for (var exp in expenses) {
      final catId = exp.linkedCategory;
      final dest = AppDestinations.values.firstWhere((d) => d.name == catId, orElse: () => AppDestinations.GENERAL);
      final catLabel = dest.label;
      
      final name = exp.workerName.toUpperCase();
      final desc = exp.description.toUpperCase();
      final isGeneric = name == "ΓΕΝΙΚΟ / ΑΓΟΡΑ" || name.contains("ΥΛΙΚΑ") || name.contains("ΑΓΟΡΑ");
      final hasMaterialKeyword = desc.contains("ΥΛΙΚΑ") || desc.contains("ΑΓΟΡΑ") || desc.contains("ΤΙΜΟΛΟΓΙΟ");

      final isMaterial = exp.categoryType == "MATERIAL" || isGeneric || hasMaterialKeyword;
      
      if (isMaterial) {
        materialGroups.putIfAbsent(catLabel, () => []).add(exp);
      } else {
        laborExpensesGroups.putIfAbsent(catLabel, () => []).add(exp);
      }
    }

    final agreedGroups = <String, List<QuoteItem>>{};
    for (var item in quoteItems) {
      agreedGroups.putIfAbsent(item.category.label, () => []).add(item);
    }

    final allCats =
        (laborGroups.keys.toSet()
              ..addAll(laborExpensesGroups.keys)
              ..addAll(materialGroups.keys)
              ..addAll(agreedGroups.keys))
            .toList()
          ..sort();

    for (var cat in allCats) {
      final attSum = (laborGroups[cat] ?? []).fold(
        0.0,
        (sum, a) => sum + a.dailyRate + a.overtimeAmount,
      );
      final laborExpSum = (laborExpensesGroups[cat] ?? []).fold(
        0.0,
        (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount),
      );
      final lSum = attSum + laborExpSum;

      final mSum = (materialGroups[cat] ?? []).fold(
        0.0,
        (sum, e) => sum + (e.hasVat ? e.amount / 1.24 : e.amount),
      );
      final qSum = (agreedGroups[cat] ?? []).fold(
        0.0,
        (sum, i) => sum + i.priceForClient,
      );

      if (lSum > 0 || mSum > 0 || qSum > 0) {
        breakdown[cat] = CategoryBreakdown(
          labor: lSum,
          materials: mSum,
          agreed: qSum,
          total: lSum + mSum,
          laborRecords: laborGroups[cat] ?? [],
          materialRecords: materialGroups[cat] ?? [],
        );
      }
    }
    return breakdown;
  }

  Future<Map<int, Map<String, double>>> getQuarterlyVatReport() async {
    final currentYear = DateTime.now().year;
    final db = DatabaseHelper();
    final incomes = await db.getAllIncomes();
    final expenses = await db.getAllExpenses();
    final fixed = await db.getCompanyExpenses();

    final report = <int, Map<String, double>>{};

    for (int q = 0; q < 4; q++) {
      double collected = 0.0;
      double paid = 0.0;

      for (var inc in incomes) {
        final dt = DateTime.fromMillisecondsSinceEpoch(inc.date);
        if (dt.year == currentYear && (dt.month - 1) ~/ 3 == q && inc.hasVat) {
          collected += inc.amount - (inc.amount / 1.24);
        }
      }

      for (var exp in expenses) {
        final dt = DateTime.fromMillisecondsSinceEpoch(exp.date);
        if (dt.year == currentYear && (dt.month - 1) ~/ 3 == q && exp.hasVat) {
          paid += exp.amount - (exp.amount / 1.24);
        }
      }

      for (var f in fixed) {
        final dt = DateTime.fromMillisecondsSinceEpoch(f.date);
        if (dt.year == currentYear && (dt.month - 1) ~/ 3 == q && f.hasVat) {
          paid += f.amount - (f.amount / 1.24);
        }
      }

      if (collected > 0 || paid > 0) {
        report[q] = {'collected': collected, 'paid': paid};
      }
    }
    return report;
  }

  // --- PHOTOS & STAGES ---
  Future<List<ProjectPhotoEntity>> getProjectPhotos(int pid) async =>
      await DatabaseHelper().getProjectPhotos(pid);
  Future<void> addPhoto(ProjectPhotoEntity p) async {
    await DatabaseHelper().insertPhoto(p);
    notifyListeners();
  }

  Future<void> updatePhoto(ProjectPhotoEntity p) async {
    await DatabaseHelper().updatePhoto(p);
    notifyListeners();
  }

  Future<void> deletePhoto(int id) async {
    await DatabaseHelper().deletePhoto(id);
    notifyListeners();
  }

  Future<List<ProjectStageEntity>> getProjectStages(int pid) async =>
      await DatabaseHelper().getProjectStages(pid);
  Future<void> addProjectStage(ProjectStageEntity stage) async {
    await DatabaseHelper().insertProjectStage(stage);
    notifyListeners();
  }

  Future<void> updateProjectStage(ProjectStageEntity stage) async {
    await DatabaseHelper().updateProjectStage(stage);
    notifyListeners();
  }

  Future<void> deleteProjectStage(int id) async {
    await DatabaseHelper().deleteProjectStage(id);
    notifyListeners();
  }

  Future<void> addCompanyExpense(CompanyExpenseEntity e) async {
    await DatabaseHelper().insertCompanyExpense(e);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> updateCompanyExpense(CompanyExpenseEntity e) async {
    await DatabaseHelper().updateCompanyExpense(e);
    await fetchProjects();
    await _autoSync();
  }

  Future<void> deleteCompanyExpense(int id) async {
    await DatabaseHelper().deleteCompanyExpense(id);
    await fetchProjects();
  }

  Future<void> _seedBasics(DatabaseHelper db) async {
    final basics = [
      MarketArchiveItem(
        name: "Τσιμέντο TITAN (25kg)",
        category: "GENERAL",
        subCategory: "ΤΣΙΜΕΝΤΑ",
        type: "MATERIAL",
        supplier: "ΓΕΝΙΚΟΣ ΠΡΟΜΗΘΕΥΤΗΣ",
        price: 7.50,
        unit: "σακί",
        hasVat: true,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
      ),
      MarketArchiveItem(
        name: "Άμμος Λατομείου",
        category: "GENERAL",
        subCategory: "ΑΔΡΑΝΗ",
        type: "MATERIAL",
        supplier: "ΛΑΤΟΜΕΙΟ",
        price: 35.00,
        unit: "m³",
        hasVat: true,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
      ),
      MarketArchiveItem(
        name: "Καλώδιο NYM 3x1.5",
        category: "ELECTRICAL",
        subCategory: "ΚΑΛΩΔΙΑ",
        type: "MATERIAL",
        supplier: "ΗΛΕΚΤΡΟΛΟΓΙΚΟ ΚΑΤΑΣΤΗΜΑ",
        price: 1.20,
        unit: "m",
        hasVat: true,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
      ),
      MarketArchiveItem(
        name: "Σωλήνα Ύδρευσης Φ20",
        category: "PLUMBING",
        subCategory: "ΣΩΛΗΝΕΣ",
        type: "MATERIAL",
        supplier: "ΥΔΡΑΥΛΙΚΑ",
        price: 2.10,
        unit: "m",
        hasVat: true,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
      ),
      MarketArchiveItem(
        name: "Δράπανο Bosch Professional",
        category: "GENERAL",
        subCategory: "ΕΡΓΑΛΕΙΑ",
        type: "TOOL",
        supplier: "ΕΡΓΑΛΕΙΑ Α.Ε.",
        price: 180.00,
        unit: "τεμ",
        hasVat: true,
        dateAdded: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
    for (var item in basics) {
      await db.insertMarketArchiveItem(item);
    }

    // Seed initial subcategories
    final initialSubCats = [
      "ΤΣΙΜΕΝΤΑ",
      "ΑΔΡΑΝΗ",
      "ΚΑΛΩΔΙΑ",
      "ΣΩΛΗΝΕΣ",
      "ΕΡΓΑΛΕΙΑ",
      "ΠΛΑΚΑΚΙΑ",
      "ΜΟΝΩΤΙΚΑ",
      "ΧΡΩΜΑΤΑ",
    ];
    for (var cat in initialSubCats) {
      await db.insertMarketSubCategory(cat);
    }
  }
}

extension CountIterable<E> on Iterable<E> {
  int count(bool Function(E element) test) => where(test).length;
}
