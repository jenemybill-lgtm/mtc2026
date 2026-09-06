import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive_io.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Εικονική μνήμη για το Web - Διατηρεί τα δεδομένα στη διάρκεια της συνεδρίας
  static final Map<String, List<Map<String, dynamic>>> _webMemory = {};

  void clearWebMemory() {
    _webMemory.clear();
    _saveWebMemoryToLocal();
  }

  Future<void> _saveWebMemoryToLocal() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_db_cache', jsonEncode(_webMemory));
    } catch (e) {
      print("Web Cache Error: $e");
    }
  }

  Future<void> loadWebMemoryFromLocal() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('web_db_cache');
      if (data != null) {
        final Map<String, dynamic> decoded = jsonDecode(data);
        decoded.forEach((key, value) {
          if (value is List) {
            _webMemory[key] = List<Map<String, dynamic>>.from(value);
          }
        });
        print("Web Cache: Loaded from LocalStorage");
      }
    } catch (e) {
      print("Web Cache Load Error: $e");
    }
  }

  int _webInsert(String table, Map<String, dynamic> data) {
    _webMemory.putIfAbsent(table, () => []);
    final list = _webMemory[table]!;
    
    // Generate ID
    int nextId = 1;
    if (list.isNotEmpty) {
      final ids = list.map((e) => e['id'] as int? ?? 0).where((id) => id > 0).toList();
      if (ids.isNotEmpty) {
        nextId = ids.reduce((a, b) => a > b ? a : b) + 1;
      }
    }
    
    final newData = Map<String, dynamic>.from(data);
    newData['id'] = nextId;
    list.add(newData);
    _saveWebMemoryToLocal();
    return nextId;
  }

  int _webUpdate(String table, Map<String, dynamic> data, int id) {
    if (!_webMemory.containsKey(table)) return 0;
    final list = _webMemory[table]!;
    final index = list.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      list[index] = Map<String, dynamic>.from(data);
      _saveWebMemoryToLocal();
      return 1;
    }
    return 0;
  }

  int _webDelete(String table, int id) {
    if (!_webMemory.containsKey(table)) return 0;
    final list = _webMemory[table]!;
    final initialLength = list.length;
    list.removeWhere((e) => e['id'] == id);
    if (initialLength != list.length) {
      _saveWebMemoryToLocal();
    }
    return initialLength - list.length;
  }

  Future<void> clearAllData() async {
    if (kIsWeb) {
      clearWebMemory();
      return;
    }
    Database? db = await database;
    final tables = await db!.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    for (var table in tables) {
      final name = table['name'] as String;
      if (name != 'android_metadata' && name != 'sqlite_sequence') {
        await db.delete(name);
      }
    }
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;
    String dbDir;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dbDir = (await getApplicationSupportDirectory()).path;
    } else {
      dbDir = await getDatabasesPath();
    }
    String path = join(dbDir, 'mtc_database.db');
    final db = await openDatabase(
      path,
      version: 16,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _ensureMarketArchiveSchema(db);
    return db;
  }

  Future<void> _ensureMarketArchiveSchema(Database db) async {
    final tableInfo = await db.rawQuery("PRAGMA table_info(market_archive)");
    final existingColumns = tableInfo
        .map((row) => row['name'] as String)
        .toSet();

    final additions = <MapEntry<String, String>>[
      const MapEntry(
        'type',
        "ALTER TABLE market_archive ADD COLUMN type TEXT DEFAULT 'MATERIAL'",
      ),
      const MapEntry(
        'subCategory',
        "ALTER TABLE market_archive ADD COLUMN subCategory TEXT DEFAULT 'ΓΕΝΙΚΑ'",
      ),
      const MapEntry(
        'supplier',
        "ALTER TABLE market_archive ADD COLUMN supplier TEXT DEFAULT ''",
      ),
      const MapEntry(
        'price',
        "ALTER TABLE market_archive ADD COLUMN price REAL DEFAULT 0",
      ),
      const MapEntry(
        'unit',
        "ALTER TABLE market_archive ADD COLUMN unit TEXT DEFAULT ''",
      ),
      const MapEntry(
        'hasVat',
        "ALTER TABLE market_archive ADD COLUMN hasVat INTEGER DEFAULT 0",
      ),
    ];

    for (final entry in additions) {
      if (!existingColumns.contains(entry.key)) {
        try {
          await db.execute(entry.value);
        } catch (_) {}
      }
    }

    final subCats = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='market_sub_categories'",
    );
    if (subCats.isEmpty) {
      await db.execute('''
        CREATE TABLE market_sub_categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE
        )
      ''');
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          "ALTER TABLE company_expenses ADD COLUMN invoiceNumber TEXT",
        );
      } catch (e) {
        print("Migration error v2: $e");
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE project_partners (
            projectId INTEGER,
            partnerId INTEGER,
            PRIMARY KEY (projectId, partnerId),
            FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE,
            FOREIGN KEY (partnerId) REFERENCES partners (id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        print("Migration error v3: $e");
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          "ALTER TABLE expenses ADD COLUMN categoryType TEXT DEFAULT 'LABOR'",
        );
        await db.execute('''
          CREATE TABLE partner_agreements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            projectId INTEGER,
            partnerId INTEGER,
            category TEXT,
            amount REAL,
            FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE,
            FOREIGN KEY (partnerId) REFERENCES partners (id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        print("Migration error v4: $e");
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('''
          CREATE TABLE market_archive (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            category TEXT,
            type TEXT,
            supplier TEXT,
            price REAL,
            unit TEXT,
            dateAdded INTEGER
          )
        ''');
      } catch (e) {
        print("Migration error v5: $e");
      }
    }
    if (oldVersion < 6) {
      try {
        await db.execute(
          "ALTER TABLE market_archive ADD COLUMN hasVat INTEGER DEFAULT 0",
        );
      } catch (e) {
        print("Migration error v6: $e");
      }
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
          "ALTER TABLE market_archive ADD COLUMN subCategory TEXT DEFAULT 'ΓΕΝΙΚΑ'",
        );
      } catch (e) {
        print("Migration error v7: $e");
      }
    }
    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE market_sub_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE
          )
        ''');
      } catch (e) {
        print("Migration error v8: $e");
      }
    }
    if (oldVersion < 10) {
      try {
        await db.execute("ALTER TABLE projects ADD COLUMN status INTEGER DEFAULT 1");
        await db.execute("ALTER TABLE projects ADD COLUMN proposalValue REAL DEFAULT 0.0");

        // Migrate existing projects
        await db.execute("UPDATE projects SET status = 2 WHERE isCompleted = 1");
        await db.execute("UPDATE projects SET status = 1 WHERE isCompleted = 0");

        await db.execute('''
          CREATE TABLE partner_bids (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            projectId INTEGER,
            partnerId INTEGER,
            partnerName TEXT,
            category TEXT,
            amount REAL,
            notes TEXT,
            dateAdded INTEGER,
            isAccepted INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE job_recipes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            category TEXT,
            description TEXT,
            materialsJson TEXT,
            estimatedLabor REAL
          )
        ''');
      } catch (e) {
        print("Migration error v10: $e");
      }
    }
    if (oldVersion < 11) {
      try {
        await db.execute("ALTER TABLE clients ADD COLUMN status TEXT DEFAULT 'ACTIVE'");
        await db.execute("ALTER TABLE clients ADD COLUMN followUpDate INTEGER");

        await db.execute('''
          CREATE TABLE portfolio (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            uri TEXT,
            category TEXT,
            description TEXT,
            dateAdded INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE project_checklists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            projectId INTEGER,
            title TEXT,
            isChecked INTEGER DEFAULT 0,
            FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        print("Migration error v11: $e");
      }
    }
    if (oldVersion < 12) {
      try {
        await db.execute('''
          CREATE TABLE project_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            projectId INTEGER,
            content TEXT,
            dateAdded INTEGER,
            FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        print("Migration error v12: $e");
      }
    }
    if (oldVersion < 13) {
      try {
        // Fix missing columns for existing users
        final projectCols = await db.rawQuery("PRAGMA table_info(projects)");
        if (!projectCols.any((c) => c['name'] == 'status')) {
          await db.execute("ALTER TABLE projects ADD COLUMN status INTEGER DEFAULT 1");
        }
        if (!projectCols.any((c) => c['name'] == 'proposalValue')) {
          await db.execute("ALTER TABLE projects ADD COLUMN proposalValue REAL DEFAULT 0.0");
        }

        final clientCols = await db.rawQuery("PRAGMA table_info(clients)");
        if (!clientCols.any((c) => c['name'] == 'status')) {
          await db.execute("ALTER TABLE clients ADD COLUMN status TEXT DEFAULT 'ACTIVE'");
        }
        if (!clientCols.any((c) => c['name'] == 'followUpDate')) {
          await db.execute("ALTER TABLE clients ADD COLUMN followUpDate INTEGER");
        }

        // New tables
        await db.execute('''
          CREATE TABLE project_sketches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            projectId INTEGER,
            title TEXT,
            folder TEXT DEFAULT 'ΓΕΝΙΚΑ',
            imagePath TEXT,
            vectorDataJson TEXT,
            dateAdded INTEGER,
            FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE project_documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            projectId INTEGER,
            title TEXT,
            filePath TEXT,
            fileExtension TEXT,
            dateAdded INTEGER,
            FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
          )
        ''');
      } catch (e) {
        print("Migration error v13: $e");
      }
    }
    if (oldVersion < 14) {
      try {
        await db.execute('''
          CREATE TABLE global_settings (
            id INTEGER PRIMARY KEY DEFAULT 1,
            companyName TEXT,
            tagline TEXT,
            logoUri TEXT,
            aiApiUrl TEXT,
            aiApiKey TEXT
          )
        ''');
      } catch (e) {
        print("Migration error v14: $e");
      }
    }
    if (oldVersion < 15) {
      try {
        await db.execute('''
          CREATE TABLE managers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            pin TEXT
          )
        ''');
        await db.execute("ALTER TABLE projects ADD COLUMN managerId INTEGER");
        await db.execute("ALTER TABLE quote_items ADD COLUMN showPriceToClient INTEGER DEFAULT 1");
      } catch (e) {
        print("Migration error v15: $e");
      }
    }
    if (oldVersion < 16) {
      try {
        await db.execute("ALTER TABLE quote_items ADD COLUMN showInQuote INTEGER DEFAULT 1");
      } catch (e) {
        print("Migration error v16: $e");
      }
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE managers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        pin TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        clientName TEXT,
        address TEXT,
        dateCreated INTEGER,
        isCompleted INTEGER,
        taxableAmountForVat REAL,
        clientId INTEGER,
        clientPhone TEXT,
        clientEmail TEXT,
        startDate INTEGER,
        deliveryDate INTEGER,
        status INTEGER DEFAULT 1,
        proposalValue REAL DEFAULT 0.0,
        managerId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        email TEXT,
        dateAdded INTEGER,
        status TEXT DEFAULT 'ACTIVE',
        followUpDate INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        date INTEGER,
        description TEXT,
        workerName TEXT,
        amount REAL,
        hasVat INTEGER,
        linkedCategory TEXT,
        invoiceNumber TEXT,
        expenseType TEXT,
        isGeneral INTEGER,
        categoryType TEXT,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        date INTEGER,
        description TEXT,
        isCompleted INTEGER,
        reminderTime INTEGER,
        reminderType TEXT,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE partners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phone TEXT,
        trade TEXT,
        baseRate REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        date INTEGER,
        description TEXT,
        amount REAL,
        hasVat INTEGER,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE quote_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        category TEXT,
        subCategory TEXT,
        description TEXT,
        unit TEXT,
        quantity REAL,
        unitPrice REAL,
        categoryProfitMargin REAL,
        useCustomMargin INTEGER,
        customProfitMargin REAL,
        internalNote TEXT,
        hasVat INTEGER,
        isVatInclusive INTEGER,
        showVatToClient INTEGER,
        showPriceToClient INTEGER DEFAULT 1,
        showInQuote INTEGER DEFAULT 1,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        locationType TEXT,
        locationId INTEGER,
        customLocationName TEXT,
        lastLocationUpdate INTEGER,
        comments TEXT,
        dateAdded INTEGER,
        quantity REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        quantity REAL,
        unit TEXT,
        locationType TEXT,
        colorCode TEXT,
        purchaseDate INTEGER,
        projectId INTEGER,
        lastUpdated INTEGER,
        minStockThreshold REAL,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE project_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        uri TEXT,
        description TEXT,
        dateAdded INTEGER,
        folderName TEXT DEFAULT 'ΓΕΝΙΚΑ',
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE company_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER,
        description TEXT,
        amount REAL,
        isMonthly INTEGER,
        hasVat INTEGER,
        invoiceNumber TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE project_stages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        name TEXT,
        progress REAL,
        displayOrder INTEGER,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE material_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tool_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        plateNumber TEXT,
        insuranceExpiry INTEGER,
        kteoExpiry INTEGER,
        currentMileage INTEGER,
        lastServiceMileage INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE vehicle_maintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER,
        date INTEGER,
        description TEXT,
        cost REAL,
        mileage INTEGER,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        description TEXT,
        quantity TEXT,
        isBought INTEGER,
        suggestedStore TEXT,
        dateAdded INTEGER,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE global_prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        description TEXT,
        unit TEXT,
        defaultUnitPrice REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        date INTEGER,
        workerName TEXT,
        dailyRate REAL,
        overtimeAmount REAL,
        workCategory TEXT,
        note TEXT,
        isConfirmed INTEGER,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE project_partners (
        projectId INTEGER,
        partnerId INTEGER,
        PRIMARY KEY (projectId, partnerId),
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE,
        FOREIGN KEY (partnerId) REFERENCES partners (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE partner_agreements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        partnerId INTEGER,
        category TEXT,
        amount REAL,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE,
        FOREIGN KEY (partnerId) REFERENCES partners (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE market_archive (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        subCategory TEXT DEFAULT 'ΓΕΝΙΚΑ',
        type TEXT,
        supplier TEXT,
        price REAL,
        unit TEXT,
        hasVat INTEGER DEFAULT 0,
        dateAdded INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE market_sub_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE partner_bids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        partnerId INTEGER,
        partnerName TEXT,
        category TEXT,
        amount REAL,
        notes TEXT,
        dateAdded INTEGER,
        isAccepted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE job_recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        description TEXT,
        materialsJson TEXT,
        estimatedLabor REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE portfolio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uri TEXT,
        category TEXT,
        description TEXT,
        dateAdded INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE project_checklists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        title TEXT,
        isChecked INTEGER DEFAULT 0,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE project_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        content TEXT,
        dateAdded INTEGER,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE project_sketches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        title TEXT,
        folder TEXT DEFAULT 'ΓΕΝΙΚΑ',
        imagePath TEXT,
        vectorDataJson TEXT,
        dateAdded INTEGER,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE project_documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectId INTEGER,
        title TEXT,
        filePath TEXT,
        fileExtension TEXT,
        dateAdded INTEGER,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE global_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        companyName TEXT,
        tagline TEXT,
        logoUri TEXT,
        aiApiUrl TEXT,
        aiApiKey TEXT
      )
    ''');
  }

  // CRUD for Projects
  Future<int> insertProject(Project project) async {
    if (kIsWeb) {
      return _webInsert('projects', project.toMap());
    }
    Database? db = await database;
    return await db!.insert('projects', project.toMap());
  }

  Future<List<Project>> getProjects() async {
    if (kIsWeb) return (_webMemory['projects'] ?? []).map((e) => Project.fromMap(e)).toList();
    Database? db = await database;
    var result = await db!.query('projects');
    return result.map((e) => Project.fromMap(e)).toList();
  }

  Future<List<Project>> getProjectsForClient(int clientId) async {
    if (kIsWeb) return (_webMemory['projects'] ?? []).map((e) => Project.fromMap(e)).where((p) => p.clientId == clientId).toList();
    Database? db = await database;
    var result = await db!.query(
      'projects',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );
    return result.map((e) => Project.fromMap(e)).toList();
  }

  Future<int> updateProject(Project project) async {
    if (kIsWeb) {
      return _webUpdate('projects', project.toMap(), project.id);
    }
    Database? db = await database;
    return await db!.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> deleteProject(int id) async {
    if (kIsWeb) {
      return _webDelete('projects', id);
    }
    Database? db = await database;
    return await db!.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // Clients
  Future<int> insertClient(Client client) async {
    if (kIsWeb) {
      return _webInsert('clients', client.toMap());
    }
    Database? db = await database;
    return await db!.insert('clients', client.toMap());
  }

  Future<List<Client>> getClients() async {
    if (kIsWeb) return (_webMemory['clients'] ?? []).map((e) => Client.fromMap(e)).toList();
    Database? db = await database;
    var result = await db!.query('clients');
    return result.map((e) => Client.fromMap(e)).toList();
  }

  Future<int> updateClient(Client client) async {
    if (kIsWeb) {
      return _webUpdate('clients', client.toMap(), client.id);
    }
    Database? db = await database;
    return await db!.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    if (kIsWeb) {
      return _webDelete('clients', id);
    }
    Database? db = await database;
    return await db!.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // Partners
  Future<int> insertPartner(Partner partner) async {
    if (kIsWeb) {
      return _webInsert('partners', partner.toMap());
    }
    Database? db = await database;
    return await db!.insert('partners', partner.toMap());
  }

  Future<List<Partner>> getPartners() async {
    if (kIsWeb) return (_webMemory['partners'] ?? []).map((e) => Partner.fromMap(e)).toList();
    Database? db = await database;
    var result = await db!.query('partners');
    return result.map((e) => Partner.fromMap(e)).toList();
  }

  Future<int> updatePartner(Partner partner) async {
    if (kIsWeb) {
      return _webUpdate('partners', partner.toMap(), partner.id);
    }
    Database? db = await database;
    return await db!.update(
      'partners',
      partner.toMap(),
      where: 'id = ?',
      whereArgs: [partner.id],
    );
  }

  Future<int> deletePartner(int id) async {
    if (kIsWeb) {
      return _webDelete('partners', id);
    }
    Database? db = await database;
    return await db!.delete('partners', where: 'id = ?', whereArgs: [id]);
  }

  // Managers
  Future<int> insertManager(Manager manager) async {
    if (kIsWeb) {
      return _webInsert('managers', manager.toMap());
    }
    Database? db = await database;
    return await db!.insert('managers', manager.toMap());
  }

  Future<List<Manager>> getManagers() async {
    if (kIsWeb) return (_webMemory['managers'] ?? []).map((e) => Manager.fromMap(e)).toList();
    Database? db = await database;
    var result = await db!.query('managers');
    return result.map((e) => Manager.fromMap(e)).toList();
  }

  Future<int> updateManager(Manager manager) async {
    if (kIsWeb) {
      return _webUpdate('managers', manager.toMap(), manager.id);
    }
    Database? db = await database;
    return await db!.update(
      'managers',
      manager.toMap(),
      where: 'id = ?',
      whereArgs: [manager.id],
    );
  }

  Future<int> deleteManager(int id) async {
    if (kIsWeb) {
      return _webDelete('managers', id);
    }
    Database? db = await database;
    return await db!.delete('managers', where: 'id = ?', whereArgs: [id]);
  }

  // Project Partners (Join Table)
  Future<List<Partner>> getPartnersForProject(int projectId) async {
    if (kIsWeb) {
      final projectPartners = (_webMemory['project_partners'] ?? [])
          .where((pp) => pp['projectId'] == projectId)
          .map((pp) => pp['partnerId'])
          .toSet();
      return (_webMemory['partners'] ?? [])
          .map((e) => Partner.fromMap(e))
          .where((p) => projectPartners.contains(p.id))
          .toList();
    }
    Database? db = await database;
    final List<Map<String, dynamic>> maps = await db!.rawQuery(
      '''
      SELECT partners.* FROM partners
      INNER JOIN project_partners ON partners.id = project_partners.partnerId
      WHERE project_partners.projectId = ?
    ''',
      [projectId],
    );
    return maps.map((e) => Partner.fromMap(e)).toList();
  }

  Future<void> addPartnerToProject(int projectId, int partnerId) async {
    if (kIsWeb) {
      _webMemory.putIfAbsent('project_partners', () => []);
      bool exists = _webMemory['project_partners']!
          .any((pp) => pp['projectId'] == projectId && pp['partnerId'] == partnerId);
      if (!exists) {
        _webMemory['project_partners']!.add({
          'projectId': projectId,
          'partnerId': partnerId,
        });
      }
      return;
    }
    Database? db = await database;
    await db!.insert('project_partners', {
      'projectId': projectId,
      'partnerId': partnerId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removePartnerFromProject(int projectId, int partnerId) async {
    if (kIsWeb) return;
    Database? db = await database;
    await db!.delete(
      'project_partners',
      where: 'projectId = ? AND partnerId = ?',
      whereArgs: [projectId, partnerId],
    );
  }

  // Partner Agreements
  Future<List<PartnerAgreement>> getPartnerAgreements(int projectId) async {
    if (kIsWeb) {
      return (_webMemory['partner_agreements'] ?? [])
          .map((e) => PartnerAgreement.fromMap(e))
          .where((e) => e.projectId == projectId)
          .toList();
    }
    Database? db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'partner_agreements',
      where: 'projectId = ?',
      whereArgs: [projectId],
    );
    return maps.map((e) => PartnerAgreement.fromMap(e)).toList();
  }

  Future<int> insertPartnerAgreement(PartnerAgreement agreement) async {
    if (kIsWeb) {
      return _webInsert('partner_agreements', agreement.toMap());
    }
    Database? db = await database;
    return await db!.insert('partner_agreements', agreement.toMap());
  }

  Future<int> updatePartnerAgreement(PartnerAgreement agreement) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.update(
      'partner_agreements',
      agreement.toMap(),
      where: 'id = ?',
      whereArgs: [agreement.id],
    );
  }

  Future<int> deletePartnerAgreement(int id) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete(
      'partner_agreements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Market Archive
  Future<List<MarketArchiveItem>> getMarketArchive() async {
    if (kIsWeb) {
      return (_webMemory['market_archive'] ?? [])
          .map((e) => MarketArchiveItem.fromMap(e))
          .toList();
    }
    Database? db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'market_archive',
      orderBy: 'category ASC, dateAdded DESC',
    );
    return maps.map((e) => MarketArchiveItem.fromMap(e)).toList();
  }

  Future<int> insertMarketArchiveItem(MarketArchiveItem item) async {
    if (kIsWeb) {
      return _webInsert('market_archive', item.toMap());
    }
    Database? db = await database;
    return await db!.insert('market_archive', item.toMap());
  }

  Future<int> updateMarketArchiveItem(MarketArchiveItem item) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.update(
      'market_archive',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMarketArchiveItem(int id) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete('market_archive', where: 'id = ?', whereArgs: [id]);
  }

  // Market Subcategories
  Future<List<String>> getMarketSubCategories() async {
    if (kIsWeb) {
      return (_webMemory['market_sub_categories'] ?? [])
          .map((e) => e['name'] as String)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('market_sub_categories', orderBy: 'name ASC');
    return result.map((e) => e['name'] as String).toList();
  }

  Future<int> insertMarketSubCategory(String name) async {
    if (kIsWeb) {
      _webMemory.putIfAbsent('market_sub_categories', () => []);
      _webMemory['market_sub_categories']!.add({'name': name});
      return 1;
    }
    Database? db = await database;
    return await db!.insert('market_sub_categories', {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> deleteMarketSubCategory(String name) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete(
      'market_sub_categories',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  // Partner Bids
  Future<List<PartnerBid>> getPartnerBids(int projectId) async {
    if (kIsWeb) {
      return (_webMemory['partner_bids'] ?? [])
          .map((e) => PartnerBid.fromMap(e))
          .where((e) => e.projectId == projectId)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('partner_bids', where: 'projectId = ?', orderBy: 'amount ASC', whereArgs: [projectId]);
    return result.map((e) => PartnerBid.fromMap(e)).toList();
  }

  Future<int> insertPartnerBid(PartnerBid bid) async {
    if (kIsWeb) {
      return _webInsert('partner_bids', bid.toMap());
    }
    Database? db = await database;
    return await db!.insert('partner_bids', bid.toMap());
  }

  Future<int> updatePartnerBid(PartnerBid bid) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.update('partner_bids', bid.toMap(), where: 'id = ?', whereArgs: [bid.id]);
  }

  Future<int> deletePartnerBid(int id) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete('partner_bids', where: 'id = ?', whereArgs: [id]);
  }

  // Job Recipes
  Future<List<JobRecipe>> getJobRecipes() async {
    if (kIsWeb) {
      return (_webMemory['job_recipes'] ?? [])
          .map((e) => JobRecipe.fromMap(e))
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('job_recipes');
    return result.map((e) => JobRecipe.fromMap(e)).toList();
  }

  Future<int> insertJobRecipe(JobRecipe recipe) async {
    if (kIsWeb) {
      return _webInsert('job_recipes', recipe.toMap());
    }
    Database? db = await database;
    return await db!.insert('job_recipes', recipe.toMap());
  }

  Future<int> deleteJobRecipe(int id) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete('job_recipes', where: 'id = ?', whereArgs: [id]);
  }

  // Portfolio
  Future<List<PortfolioItem>> getPortfolio() async {
    if (kIsWeb) {
      return (_webMemory['portfolio'] ?? [])
          .map((e) => PortfolioItem.fromMap(e))
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('portfolio', orderBy: 'dateAdded DESC');
    return result.map((e) => PortfolioItem.fromMap(e)).toList();
  }

  Future<int> insertPortfolioItem(PortfolioItem item) async {
    if (kIsWeb) {
      return _webInsert('portfolio', item.toMap());
    }
    Database? db = await database;
    return await db!.insert('portfolio', item.toMap());
  }

  Future<int> deletePortfolioItem(int id) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete('portfolio', where: 'id = ?', whereArgs: [id]);
  }

  // Project Checklists
  Future<List<ProjectChecklistItem>> getProjectChecklist(int projectId) async {
    if (kIsWeb) {
      return (_webMemory['project_checklists'] ?? [])
          .map((e) => ProjectChecklistItem.fromMap(e))
          .where((e) => e.projectId == projectId)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('project_checklists', where: 'projectId = ?', whereArgs: [projectId]);
    return result.map((e) => ProjectChecklistItem.fromMap(e)).toList();
  }

  Future<int> insertChecklistItem(ProjectChecklistItem item) async {
    if (kIsWeb) {
      return _webInsert('project_checklists', item.toMap());
    }
    Database? db = await database;
    return await db!.insert('project_checklists', item.toMap());
  }

  Future<int> updateChecklistItem(ProjectChecklistItem item) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.update('project_checklists', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteChecklistItem(int id) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete('project_checklists', where: 'id = ?', whereArgs: [id]);
  }

  // Project Notes
  Future<List<ProjectNote>> getProjectNotes(int projectId) async {
    if (kIsWeb) {
      return (_webMemory['project_notes'] ?? [])
          .map((e) => ProjectNote.fromMap(e))
          .where((e) => e.projectId == projectId)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('project_notes', where: 'projectId = ?', orderBy: 'dateAdded DESC', whereArgs: [projectId]);
    return result.map((e) => ProjectNote.fromMap(e)).toList();
  }

  Future<int> insertProjectNote(ProjectNote note) async {
    if (kIsWeb) {
      return _webInsert('project_notes', note.toMap());
    }
    Database? db = await database;
    return await db!.insert('project_notes', note.toMap());
  }

  Future<int> updateProjectNote(ProjectNote note) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.update('project_notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> deleteProjectNote(int id) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete('project_notes', where: 'id = ?', whereArgs: [id]);
  }

  // Project Sketches
  Future<List<ProjectSketch>> getProjectSketches(int projectId) async {
    if (kIsWeb) {
      return (_webMemory['project_sketches'] ?? [])
          .map((e) => ProjectSketch.fromMap(e))
          .where((e) => e.projectId == projectId)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('project_sketches', where: 'projectId = ?', orderBy: 'dateAdded DESC', whereArgs: [projectId]);
    return result.map((e) => ProjectSketch.fromMap(e)).toList();
  }

  Future<int> insertProjectSketch(ProjectSketch sketch) async {
    if (kIsWeb) {
      return _webInsert('project_sketches', sketch.toMap());
    }
    Database? db = await database;
    return await db!.insert('project_sketches', sketch.toMap());
  }

  Future<int> deleteProjectSketch(int id) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete('project_sketches', where: 'id = ?', whereArgs: [id]);
  }

  // Project Documents
  Future<List<ProjectDocument>> getProjectDocuments(int projectId) async {
    if (kIsWeb) {
      return (_webMemory['project_documents'] ?? [])
          .map((e) => ProjectDocument.fromMap(e))
          .where((e) => e.projectId == projectId)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('project_documents', where: 'projectId = ?', orderBy: 'dateAdded DESC', whereArgs: [projectId]);
    return result.map((e) => ProjectDocument.fromMap(e)).toList();
  }

  Future<int> insertProjectDocument(ProjectDocument doc) async {
    if (kIsWeb) {
      return _webInsert('project_documents', doc.toMap());
    }
    Database? db = await database;
    return await db!.insert('project_documents', doc.toMap());
  }

  Future<int> deleteProjectDocument(int id) async {
    if (kIsWeb) return 0;
    Database? db = await database;
    return await db!.delete('project_documents', where: 'id = ?', whereArgs: [id]);
  }

  // Global Settings (Syncable part)
  Future<Map<String, dynamic>?> getGlobalSettings() async {
    if (kIsWeb) return _webMemory['global_settings']?.first;
    Database? db = await database;
    var result = await db!.query('global_settings', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> updateGlobalSettings(Map<String, dynamic> settings) async {
    if (kIsWeb) {
      _webMemory['global_settings'] = [settings];
      return;
    }
    Database? db = await database;
    await db!.insert('global_settings', settings, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Incomes
  Future<List<Income>> getIncomes(int projectId) async {
    if (kIsWeb) return (_webMemory['incomes'] ?? []).map((e) => Income.fromMap(e)).where((i) => i.projectId == projectId).toList();
    Database? db = await database;
    var result = await db!.query(
      'incomes',
      where: 'projectId = ?',
      whereArgs: [projectId],
    );
    return result.map((e) => Income.fromMap(e)).toList();
  }

  Future<List<Income>> getAllIncomes() async {
    if (kIsWeb) return (_webMemory['incomes'] ?? []).map((e) => Income.fromMap(e)).toList();
    Database? db = await database;
    var result = await db!.query('incomes');
    return result.map((e) => Income.fromMap(e)).toList();
  }

  Future<int> insertIncome(Income income) async {
    if (kIsWeb) {
      return _webInsert('incomes', income.toMap());
    }
    Database? db = await database;
    return await db!.insert('incomes', income.toMap());
  }

  Future<int> updateIncome(Income income) async {
    if (kIsWeb) {
      return _webUpdate('incomes', income.toMap(), income.id);
    }
    Database? db = await database;
    return await db!.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    if (kIsWeb) {
      return _webDelete('incomes', id);
    }
    Database? db = await database;
    return await db!.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  // Expenses
  Future<List<Expense>> getExpenses(int projectId) async {
    if (kIsWeb) return (_webMemory['expenses'] ?? []).map((e) => Expense.fromMap(e)).where((e) => e.projectId == projectId).toList();
    Database? db = await database;
    var result = await db!.query(
      'expenses',
      where: 'projectId = ?',
      whereArgs: [projectId],
    );
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<List<Expense>> getAllExpenses() async {
    if (kIsWeb) return (_webMemory['expenses'] ?? []).map((e) => Expense.fromMap(e)).toList();
    Database? db = await database;
    var result = await db!.query('expenses');
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    if (kIsWeb) {
      return _webInsert('expenses', expense.toMap());
    }
    Database? db = await database;
    return await db!.insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(Expense expense) async {
    if (kIsWeb) {
      return _webUpdate('expenses', expense.toMap(), expense.id);
    }
    Database? db = await database;
    return await db!.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    if (kIsWeb) {
      return _webDelete('expenses', id);
    }
    Database? db = await database;
    return await db!.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Materials
  Future<List<MaterialEntity>> getMaterials(
    int? projectId,
    String locationType,
    String category,
  ) async {
    if (kIsWeb) {
      var list = (_webMemory['materials'] ?? []).map((e) => MaterialEntity.fromMap(e));
      if (projectId != null) {
        list = list.where((m) => m.projectId == projectId);
      }
      list = list.where((m) => m.locationType == locationType);
      if (category != "ΟΛΑ") {
        list = list.where((m) => m.category == category);
      }
      return list.toList();
    }
    Database? db = await database;
    String where = 'locationType = ?';
    List<dynamic> whereArgs = [locationType];
    if (projectId != null) {
      where += ' AND projectId = ?';
      whereArgs.add(projectId);
    }
    if (category != "ΟΛΑ") {
      where += ' AND category = ?';
      whereArgs.add(category);
    }
    var result = await db!.query(
      'materials',
      where: where,
      whereArgs: whereArgs,
    );
    return result.map((e) => MaterialEntity.fromMap(e)).toList();
  }

  Future<int> insertMaterial(MaterialEntity material) async {
    if (kIsWeb) {
      return _webInsert('materials', material.toMap());
    }
    Database? db = await database;
    return await db!.insert('materials', material.toMap());
  }

  Future<int> updateMaterial(MaterialEntity material) async {
    if (kIsWeb) {
      return _webUpdate('materials', material.toMap(), material.id);
    }
    Database? db = await database;
    return await db!.update(
      'materials',
      material.toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<int> deleteMaterial(int id) async {
    if (kIsWeb) {
      return _webDelete('materials', id);
    }
    Database? db = await database;
    return await db!.delete('materials', where: 'id = ?', whereArgs: [id]);
  }

  // Attendance
  Future<List<AttendanceEntity>> getAttendance(
    int? projectId,
    int? start,
    int? end,
  ) async {
    if (kIsWeb) {
      var list = (_webMemory['attendance'] ?? []).map((e) => AttendanceEntity.fromMap(e));
      if (projectId != null) {
        list = list.where((a) => a.projectId == projectId);
      }
      if (start != null && end != null) {
        list = list.where((a) => a.date >= start && a.date <= end);
      }
      return list.toList();
    }
    Database? db = await database;
    String where = '';
    List<dynamic> whereArgs = [];
    if (projectId != null) {
      where = 'projectId = ?';
      whereArgs.add(projectId);
    }
    if (start != null && end != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'date >= ? AND date <= ?';
      whereArgs.add(start);
      whereArgs.add(end);
    }
    var result = await db!.query(
      'attendance',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    return result.map((e) => AttendanceEntity.fromMap(e)).toList();
  }

  Future<int> insertAttendance(AttendanceEntity record) async {
    if (kIsWeb) {
      return _webInsert('attendance', record.toMap());
    }
    Database? db = await database;
    return await db!.insert('attendance', record.toMap());
  }

  Future<int> updateAttendance(AttendanceEntity record) async {
    if (kIsWeb) {
      return _webUpdate('attendance', record.toMap(), record.id);
    }
    Database? db = await database;
    return await db!.update(
      'attendance',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteAttendance(int id) async {
    if (kIsWeb) {
      return _webDelete('attendance', id);
    }
    Database? db = await database;
    return await db!.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getPayments(int start, int end) async {
    if (kIsWeb) {
      return (_webMemory['expenses'] ?? [])
          .map((e) => Expense.fromMap(e))
          .where((e) => e.expenseType == 'PAYMENT' && e.date >= start && e.date <= end)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query(
      'expenses',
      where: 'expenseType = ? AND date >= ? AND date <= ?',
      whereArgs: ['PAYMENT', start, end],
    );
    return result.map((e) => Expense.fromMap(e)).toList();
  }

  // Tasks
  Future<List<Task>> getTasks() async {
    if (kIsWeb) {
      return (_webMemory['tasks'] ?? []).map((e) => Task.fromMap(e)).toList();
    }
    Database? db = await database;
    var result = await db!.query('tasks');
    return result.map((e) => Task.fromMap(e)).toList();
  }

  Future<int> insertTask(Task task) async {
    if (kIsWeb) {
      return _webInsert('tasks', task.toMap());
    }
    Database? db = await database;
    return await db!.insert('tasks', task.toMap());
  }

  Future<int> updateTask(Task task) async {
    if (kIsWeb) {
      return _webUpdate('tasks', task.toMap(), task.id);
    }
    Database? db = await database;
    return await db!.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    if (kIsWeb) {
      return _webDelete('tasks', id);
    }
    Database? db = await database;
    return await db!.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Shopping List
  Future<List<ShoppingItemEntity>> getShoppingList(int projectId) async {
    if (kIsWeb) {
      return (_webMemory['shopping_list'] ?? [])
          .map((e) => ShoppingItemEntity.fromMap(e))
          .where((e) => e.projectId == projectId)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query(
      'shopping_list',
      where: 'projectId = ?',
      orderBy: 'isBought ASC, dateAdded DESC',
      whereArgs: [projectId],
    );
    return result.map((e) => ShoppingItemEntity.fromMap(e)).toList();
  }

  Future<int> insertShoppingItem(ShoppingItemEntity item) async {
    if (kIsWeb) {
      return _webInsert('shopping_list', item.toMap());
    }
    Database? db = await database;
    return await db!.insert('shopping_list', item.toMap());
  }

  Future<int> updateShoppingItem(ShoppingItemEntity item) async {
    if (kIsWeb) {
      return _webUpdate('shopping_list', item.toMap(), item.id);
    }
    Database? db = await database;
    return await db!.update(
      'shopping_list',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteShoppingItem(int id) async {
    if (kIsWeb) {
      return _webDelete('shopping_list', id);
    }
    Database? db = await database;
    return await db!.delete('shopping_list', where: 'id = ?', whereArgs: [id]);
  }

  // Project Stages (Timeline)
  Future<List<ProjectStageEntity>> getProjectStages(int projectId) async {
    if (kIsWeb) {
      return (_webMemory['project_stages'] ?? [])
          .map((e) => ProjectStageEntity.fromMap(e))
          .where((e) => e.projectId == projectId)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query(
      'project_stages',
      where: 'projectId = ?',
      orderBy: 'displayOrder ASC',
      whereArgs: [projectId],
    );
    return result.map((e) => ProjectStageEntity.fromMap(e)).toList();
  }

  Future<int> insertProjectStage(ProjectStageEntity stage) async {
    if (kIsWeb) {
      return _webInsert('project_stages', stage.toMap());
    }
    Database? db = await database;
    return await db!.insert('project_stages', stage.toMap());
  }

  Future<int> updateProjectStage(ProjectStageEntity stage) async {
    if (kIsWeb) {
      return _webUpdate('project_stages', stage.toMap(), stage.id);
    }
    Database? db = await database;
    return await db!.update(
      'project_stages',
      stage.toMap(),
      where: 'id = ?',
      whereArgs: [stage.id],
    );
  }

  Future<int> deleteProjectStage(int id) async {
    if (kIsWeb) {
      return _webDelete('project_stages', id);
    }
    Database? db = await database;
    return await db!.delete('project_stages', where: 'id = ?', whereArgs: [id]);
  }

  // Company Expenses
  Future<List<CompanyExpenseEntity>> getCompanyExpenses() async {
    if (kIsWeb) {
      return (_webMemory['company_expenses'] ?? [])
          .map((e) => CompanyExpenseEntity.fromMap(e))
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('company_expenses');
    return result.map((e) => CompanyExpenseEntity.fromMap(e)).toList();
  }

  Future<int> insertCompanyExpense(CompanyExpenseEntity e) async {
    if (kIsWeb) {
      return _webInsert('company_expenses', e.toMap());
    }
    Database? db = await database;
    return await db!.insert('company_expenses', e.toMap());
  }

  Future<int> updateCompanyExpense(CompanyExpenseEntity e) async {
    if (kIsWeb) {
      return _webUpdate('company_expenses', e.toMap(), e.id);
    }
    Database? db = await database;
    return await db!.update(
      'company_expenses',
      e.toMap(),
      where: 'id = ?',
      whereArgs: [e.id],
    );
  }

  Future<int> deleteCompanyExpense(int id) async {
    if (kIsWeb) {
      return _webDelete('company_expenses', id);
    }
    Database? db = await database;
    return await db!.delete(
      'company_expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllQuoteItems() async {
    if (kIsWeb) return _webMemory['quote_items'] ?? [];
    Database? db = await database;
    return await db!.query('quote_items');
  }

  Future<List<String>> getMaterialCategories() async {
    if (kIsWeb) {
      return (_webMemory['material_categories'] ?? [])
          .map((e) => e['name'] as String)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('material_categories');
    return result.map((e) => e['name'] as String).toList();
  }

  Future<int> insertMaterialCategory(String name) async {
    if (kIsWeb) {
      return _webInsert('material_categories', {'name': name});
    }
    Database? db = await database;
    return await db!.insert('material_categories', {'name': name});
  }

  // Tools
  Future<List<Tool>> getTools(
    int? locationId,
    String locationType,
    String category,
  ) async {
    if (kIsWeb) {
      var list = (_webMemory['tools'] ?? []).map((e) => Tool.fromMap(e));
      if (locationType != "TOTAL") {
        list = list.where((t) => t.locationType == locationType);
        if (locationId != null && locationType == "PROJECT") {
          list = list.where((t) => t.locationId == locationId);
        }
      }
      if (category != "ΟΛΑ") {
        list = list.where((t) => t.category == category);
      }
      return list.toList();
    }
    Database? db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (locationType != "TOTAL") {
      where = 'locationType = ?';
      whereArgs.add(locationType);
      if (locationId != null && locationType == "PROJECT") {
        where += ' AND locationId = ?';
        whereArgs.add(locationId);
      }
    }

    if (category != "ΟΛΑ") {
      if (where.isNotEmpty) where += ' AND ';
      where += 'category = ?';
      whereArgs.add(category);
    }

    var result = await db!.query(
      'tools',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    return result.map((e) => Tool.fromMap(e)).toList();
  }

  Future<int> insertTool(Tool tool) async {
    if (kIsWeb) {
      return _webInsert('tools', tool.toMap());
    }
    Database? db = await database;
    return await db!.insert('tools', tool.toMap());
  }

  Future<int> updateTool(Tool tool) async {
    if (kIsWeb) {
      return _webUpdate('tools', tool.toMap(), tool.id);
    }
    Database? db = await database;
    return await db!.update(
      'tools',
      tool.toMap(),
      where: 'id = ?',
      whereArgs: [tool.id],
    );
  }

  Future<int> deleteTool(int id) async {
    if (kIsWeb) {
      return _webDelete('tools', id);
    }
    Database? db = await database;
    return await db!.delete('tools', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getToolCategories() async {
    if (kIsWeb) {
      return (_webMemory['tool_categories'] ?? [])
          .map((e) => e['name'] as String)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query('tool_categories');
    return result.map((e) => e['name'] as String).toList();
  }

  Future<int> insertToolCategory(String name) async {
    if (kIsWeb) {
      return _webInsert('tool_categories', {'name': name});
    }
    Database? db = await database;
    return await db!.insert('tool_categories', {'name': name});
  }

  // Vehicle
  Future<VehicleEntity> getVehicle() async {
    if (kIsWeb) {
      if ((_webMemory['vehicles'] ?? []).isNotEmpty) {
        return VehicleEntity.fromMap(_webMemory['vehicles']!.first);
      }
      return VehicleEntity(name: "ΕΤΑΙΡΙΚΟ ΒΑΝ");
    }
    Database? db = await database;
    var result = await db!.query('vehicles', limit: 1);
    if (result.isNotEmpty) {
      return VehicleEntity.fromMap(result.first);
    } else {
      final v = VehicleEntity(name: "ΕΤΑΙΡΙΚΟ ΒΑΝ");
      await db!.insert('vehicles', v.toMap());
      return v;
    }
  }

  Future<int> updateVehicle(VehicleEntity vehicle) async {
    if (kIsWeb) {
      return _webUpdate('vehicles', vehicle.toMap(), vehicle.id);
    }
    Database? db = await database;
    return await db!.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<List<VehicleMaintenanceEntity>> getMaintenance(int vehicleId) async {
    if (kIsWeb) {
      return (_webMemory['vehicle_maintenance'] ?? [])
          .map((e) => VehicleMaintenanceEntity.fromMap(e))
          .where((e) => e.vehicleId == vehicleId)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query(
      'vehicle_maintenance',
      where: 'vehicleId = ?',
      orderBy: 'date DESC',
      whereArgs: [vehicleId],
    );
    return result.map((e) => VehicleMaintenanceEntity.fromMap(e)).toList();
  }

  Future<int> insertMaintenance(VehicleMaintenanceEntity m) async {
    if (kIsWeb) {
      return _webInsert('vehicle_maintenance', m.toMap());
    }
    Database? db = await database;
    return await db!.insert('vehicle_maintenance', m.toMap());
  }

  Future<int> deleteMaintenance(int id) async {
    if (kIsWeb) {
      return _webDelete('vehicle_maintenance', id);
    }
    Database? db = await database;
    return await db!.delete(
      'vehicle_maintenance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Quote Items
  Future<List<QuoteItem>> getQuoteItems(int projectId) async {
    if (kIsWeb) return (_webMemory['quote_items'] ?? []).map((e) => QuoteItem.fromMap(e)).where((i) => i.id.contains(projectId.toString())).toList();
    Database? db = await database;
    var result = await db!.query(
      'quote_items',
      where: 'projectId = ?',
      whereArgs: [projectId],
    );
    return result.map((e) => QuoteItem.fromMap(e)).toList();
  }

  Future<int> insertQuoteItem(int projectId, QuoteItem item) async {
    if (kIsWeb) {
      return _webInsert('quote_items', item.toMap(projectId));
    }
    Database? db = await database;
    return await db!.insert('quote_items', item.toMap(projectId));
  }

  Future<int> updateQuoteItem(int projectId, QuoteItem item) async {
    if (kIsWeb) {
      // QuoteItem ID is a String in model but int in DB, handle carefully
      int? id = int.tryParse(item.id);
      if (id == null) return 0;
      return _webUpdate('quote_items', item.toMap(projectId), id);
    }
    Database? db = await database;
    return await db!.update(
      'quote_items',
      item.toMap(projectId),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteQuoteItem(int id) async {
    if (kIsWeb) {
      return _webDelete('quote_items', id);
    }
    Database? db = await database;
    return await db!.delete('quote_items', where: 'id = ?', whereArgs: [id]);
  }

  // Photos
  Future<List<ProjectPhotoEntity>> getProjectPhotos(int projectId) async {
    if (kIsWeb) {
      return (_webMemory['project_photos'] ?? [])
          .map((e) => ProjectPhotoEntity.fromMap(e))
          .where((e) => e.projectId == projectId)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query(
      'project_photos',
      where: 'projectId = ?',
      orderBy: 'dateAdded DESC',
      whereArgs: [projectId],
    );
    return result.map((e) => ProjectPhotoEntity.fromMap(e)).toList();
  }

  Future<int> insertPhoto(ProjectPhotoEntity photo) async {
    if (kIsWeb) {
      return _webInsert('project_photos', photo.toMap());
    }
    Database? db = await database;
    return await db!.insert('project_photos', photo.toMap());
  }

  Future<int> updatePhoto(ProjectPhotoEntity photo) async {
    if (kIsWeb) {
      return _webUpdate('project_photos', photo.toMap(), photo.id);
    }
    Database? db = await database;
    return await db!.update(
      'project_photos',
      photo.toMap(),
      where: 'id = ?',
      whereArgs: [photo.id],
    );
  }

  Future<int> deletePhoto(int id) async {
    if (kIsWeb) {
      return _webDelete('project_photos', id);
    }
    Database? db = await database;
    return await db!.delete('project_photos', where: 'id = ?', whereArgs: [id]);
  }

  // Global Prices
  Future<List<GlobalPriceEntity>> getGlobalPrices(String category) async {
    if (kIsWeb) {
      return (_webMemory['global_prices'] ?? [])
          .map((e) => GlobalPriceEntity.fromMap(e))
          .where((e) => e.category == category)
          .toList();
    }
    Database? db = await database;
    var result = await db!.query(
      'global_prices',
      where: 'category = ?',
      whereArgs: [category],
    );
    return result.map((e) => GlobalPriceEntity.fromMap(e)).toList();
  }

  Future<int> insertGlobalPrice(GlobalPriceEntity price) async {
    if (kIsWeb) {
      return _webInsert('global_prices', price.toMap());
    }
    Database? db = await database;
    return await db!.insert('global_prices', price.toMap());
  }

  Future<int> updateGlobalPrice(GlobalPriceEntity price) async {
    if (kIsWeb) {
      return _webUpdate('global_prices', price.toMap(), price.id);
    }
    Database? db = await database;
    return await db!.update(
      'global_prices',
      price.toMap(),
      where: 'id = ?',
      whereArgs: [price.id],
    );
  }

  Future<int> deleteGlobalPrice(int id) async {
    if (kIsWeb) {
      return _webDelete('global_prices', id);
    }
    Database? db = await database;
    return await db!.delete('global_prices', where: 'id = ?', whereArgs: [id]);
  }

  // Backup & Restore (Full ZIP)
  Future<void> backupDatabase() async {
    if (kIsWeb) return;
    Database? db = await database;
    Map<String, dynamic> backup = {};
    final tables = [
      'projects',
      'clients',
      'expenses',
      'tasks',
      'partners',
      'incomes',
      'quote_items',
      'tools',
      'materials',
      'company_expenses',
      'project_stages',
      'project_photos',
      'material_categories',
      'tool_categories',
      'vehicles',
      'vehicle_maintenance',
      'shopping_list',
      'global_prices',
      'attendance',
      'project_partners',
      'partner_agreements',
      'market_archive',
      'market_sub_categories',
      'project_checklists',
      'project_notes',
      'partner_bids',
      'job_recipes',
      'portfolio',
      'project_sketches',
      'project_documents',
      'global_settings',
    ];
    for (var table in tables) {
      backup[table] = await db!.query(table);
    }

    final jsonString = jsonEncode(backup);

    final appDir = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();
    final zipFile = File('${tempDir.path}/mtc_full_backup.zip');

    final encoder = ZipFileEncoder();
    encoder.create(zipFile.path);

    // 1. Add JSON data
    final jsonFile = File('${tempDir.path}/data.json');
    await jsonFile.writeAsString(jsonString);
    encoder.addFile(jsonFile);

    // 2. Add all files from app directory (photos, etc.)
    final files = appDir.listSync(recursive: true);
    for (var file in files) {
      if (file is File) {
        final relativePath = file.path.replaceFirst(appDir.path, 'files');
        encoder.addFile(file, relativePath);
      }
    }

    encoder.close();
    await Share.shareXFiles([
      XFile(zipFile.path),
    ], text: 'MTC Full Backup (ZIP)');
  }

  Future<void> restoreDatabase(File zipFile) async {
    if (kIsWeb) return;
    print("Restore: Starting database restoration...");
    final appDir = await getApplicationDocumentsDirectory();

    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    String? jsonData;

    for (final file in archive) {
      if (file.isFile) {
        if (file.name.endsWith('data.json')) {
          print("Restore: Found data.json inside ZIP.");
          jsonData = utf8.decode(file.content as List<int>);
        } else if (file.name.contains('/files/') ||
            file.name.startsWith('files/')) {
          String fileName = file.name.split('/').last;
          final destFile = File('${appDir.path}/$fileName');
          await destFile.create(recursive: true);
          await destFile.writeAsBytes(file.content as List<int>);
          print("Restore: Extracted file: $fileName");
        }
      }
    }

    if (jsonData == null) {
      try {
        print(
          "Restore: ZIP didn't contain data.json, trying to read ZIP as raw JSON...",
        );
        jsonData = await zipFile.readAsString();
      } catch (e) {
        throw Exception(
          "Invalid backup file: data.json not found and not a valid JSON",
        );
      }
    }

    Database? db = await database;
    Map<String, dynamic> backup = jsonDecode(jsonData);

    // Map old app keys to new table names
    final tableMapping = {
      'projects': 'projects',
      'quoteItems': 'quote_items',
      'quote_items': 'quote_items',
      'expenses': 'expenses',
      'tasks': 'tasks',
      'partners': 'partners',
      'incomes': 'incomes',
      'customCategories': 'custom_categories',
      'custom_categories': 'custom_categories',
      'attendance': 'attendance',
      'tools': 'tools',
      'materials': 'materials',
      'photos': 'project_photos',
      'project_photos': 'project_photos',
      'companyExpenses': 'company_expenses',
      'company_expenses': 'company_expenses',
      'stages': 'project_stages',
      'project_stages': 'project_stages',
      'materialCategories': 'material_categories',
      'material_categories': 'material_categories',
      'toolCategories': 'tool_categories',
      'tool_categories': 'tool_categories',
      'vehicles': 'vehicles',
      'maintenance': 'vehicle_maintenance',
      'vehicle_maintenance': 'vehicle_maintenance',
      'shoppingItems': 'shopping_list',
      'shopping_list': 'shopping_list',
      'globalPrices': 'global_prices',
      'global_prices': 'global_prices',
      'clients': 'clients',
      'project_partners': 'project_partners',
      'partner_agreements': 'partner_agreements',
      'marketArchive': 'market_archive',
      'market_archive': 'market_archive',
      'marketSubCategories': 'market_sub_categories',
      'market_sub_categories': 'market_sub_categories',
      'project_checklists': 'project_checklists',
      'project_notes': 'project_notes',
      'partner_bids': 'partner_bids',
      'job_recipes': 'job_recipes',
      'portfolio': 'portfolio',
      'project_sketches': 'project_sketches',
      'project_documents': 'project_documents',
      'global_settings': 'global_settings',
    };

    final currentAppDirPath = appDir.path;

    await db!.transaction((txn) async {
      for (var jsonKey in backup.keys) {
        final tableName = tableMapping[jsonKey];
        if (tableName == null) {
          print("Restore: Unknown key in JSON: $jsonKey. Skipping.");
          continue;
        }

        final tableExists = await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName],
        );
        if (tableExists.isEmpty) {
          print(
            "Restore: Table '$tableName' does not exist in schema. Skipping.",
          );
          continue;
        }

        print("Restore: Clearing existing data from table '$tableName'...");
        await txn.delete(tableName);

        final rows = backup[jsonKey];
        if (rows is List) {
          print("Restore: Inserting ${rows.length} rows into '$tableName'...");
          int insertedCount = 0;
          for (var row in rows) {
            if (row is Map) {
              Map<String, dynamic> mutableRow = Map<String, dynamic>.from(row);

              // SQLite FFI doesn't support bool type, convert to int
              mutableRow.forEach((key, value) {
                if (value is bool) {
                  mutableRow[key] = value ? 1 : 0;
                }
              });

              // Fix absolute paths for photos, sketches, and documents
              if (tableName == 'project_photos' &&
                  mutableRow.containsKey('uri')) {
                String? oldUri = mutableRow['uri'];
                if (oldUri != null) {
                  String fileName = oldUri.split('/').last;
                  mutableRow['uri'] = '$currentAppDirPath/photos/$fileName';
                }
              } else if (tableName == 'project_sketches' &&
                  mutableRow.containsKey('imagePath')) {
                String? oldPath = mutableRow['imagePath'];
                if (oldPath != null) {
                  String fileName = oldPath.split('/').last;
                  mutableRow['imagePath'] = '$currentAppDirPath/$fileName';
                }
              } else if (tableName == 'project_documents' &&
                  mutableRow.containsKey('filePath')) {
                String? oldPath = mutableRow['filePath'];
                int? pId = mutableRow['projectId'];
                if (oldPath != null && pId != null) {
                  String fileName = oldPath.split('/').last;
                  mutableRow['filePath'] = '$currentAppDirPath/documents/$pId/$fileName';
                }
              }

              try {
                await txn.insert(tableName, mutableRow);
                insertedCount++;
              } catch (e) {
                print(
                  "Restore error into $tableName at row $insertedCount: $e",
                );
              }
            }
          }
          print(
            "Restore: Successfully inserted $insertedCount rows into '$tableName'.",
          );
        }
      }
    });
    print("Restore: Database restoration completed successfully.");
  }

  // --- MANUAL CLOUD SYNC HELPERS ---

  Future<Map<String, dynamic>> getAllDataForSync() async {
    if (kIsWeb) {
      return Map<String, dynamic>.from(_webMemory);
    }
    Database? db = await database;
    Map<String, dynamic> data = {};
    final tables = [
      'projects',
      'clients',
      'expenses',
      'tasks',
      'partners',
      'incomes',
      'quote_items',
      'tools',
      'materials',
      'company_expenses',
      'project_stages',
      'project_photos',
      'material_categories',
      'tool_categories',
      'vehicles',
      'vehicle_maintenance',
      'shopping_list',
      'global_prices',
      'attendance',
      'project_partners',
      'partner_agreements',
      'market_archive',
      'market_sub_categories',
      'project_checklists',
      'project_notes',
      'partner_bids',
      'job_recipes',
      'portfolio',
      'project_sketches',
      'project_documents',
      'global_settings',
    ];

    for (var table in tables) {
      var rows = await db!.query(table);

      // Handle Photos & Global Logo: Convert to Base64 to store in MongoDB
      if (table == 'project_photos') {
        List<Map<String, dynamic>> rowsWithImageData = [];
        for (var row in rows) {
          Map<String, dynamic> mutableRow = Map<String, dynamic>.from(row);
          String? uri = mutableRow['uri'];
          if (uri != null && File(uri).existsSync()) {
            try {
              List<int> imageBytes = await File(uri).readAsBytes();
              mutableRow['base64Data'] = base64Encode(imageBytes);
            } catch (e) {
              print("Sync: Could not encode image $uri: $e");
            }
          }
          rowsWithImageData.add(mutableRow);
        }
        data[table] = rowsWithImageData;
      } else if (table == 'global_settings') {
        List<Map<String, dynamic>> rowsWithLogo = [];
        for (var row in rows) {
          Map<String, dynamic> mutableRow = Map<String, dynamic>.from(row);
          String? logoUri = mutableRow['logoUri'];
          if (logoUri != null && File(logoUri).existsSync()) {
            try {
              List<int> imageBytes = await File(logoUri).readAsBytes();
              mutableRow['logoBase64'] = base64Encode(imageBytes);
            } catch (_) {}
          }
          rowsWithLogo.add(mutableRow);
        }
        data[table] = rowsWithLogo;
      } else {
        data[table] = rows;
      }
    }

    return data;
  }

  Future<void> importDataFromSync(Map<String, dynamic> backup) async {
    if (kIsWeb) {
      print("Web Import: Processing received data...");
      
      // Handle nested "data" wrapper from server
      final Map<String, dynamic> source = (backup.containsKey('data') && backup['data'] is Map)
          ? Map<String, dynamic>.from(backup['data'])
          : backup;

      source.forEach((key, value) {
        if (value is List) {
          _webMemory[key] = List<Map<String, dynamic>>.from(value);
          print("Web Import: Loaded $key (${(value).length} rows)");
        }
      });
      _saveWebMemoryToLocal();
      return;
    }
    Database? db = await database;
    final appDir = await getApplicationDocumentsDirectory();
    final currentAppDirPath = appDir.path;

    final tableMapping = {
      'projects': 'projects',
      'clients': 'clients',
      'expenses': 'expenses',
      'tasks': 'tasks',
      'partners': 'partners',
      'incomes': 'incomes',
      'quote_items': 'quote_items',
      'tools': 'tools',
      'materials': 'materials',
      'company_expenses': 'company_expenses',
      'project_stages': 'project_stages',
      'project_photos': 'project_photos',
      'material_categories': 'material_categories',
      'tool_categories': 'tool_categories',
      'vehicles': 'vehicles',
      'vehicle_maintenance': 'vehicle_maintenance',
      'shopping_list': 'shopping_list',
      'global_prices': 'global_prices',
      'attendance': 'attendance',
      'project_partners': 'project_partners',
      'partner_agreements': 'partner_agreements',
      'market_archive': 'market_archive',
      'market_sub_categories': 'market_sub_categories',
      'project_checklists': 'project_checklists',
      'project_notes': 'project_notes',
      'partner_bids': 'partner_bids',
      'job_recipes': 'job_recipes',
      'portfolio': 'portfolio',
      'project_sketches': 'project_sketches',
      'project_documents': 'project_documents',
      'global_settings': 'global_settings',
    };

    await db!.transaction((txn) async {
      for (var jsonKey in backup.keys) {
        final tableName = tableMapping[jsonKey];
        if (tableName == null) continue;

        final tableExists = await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName],
        );
        if (tableExists.isEmpty) continue;

        await txn.delete(tableName);

        final rows = backup[jsonKey];
        if (rows is List) {
          for (var row in rows) {
            if (row is Map) {
              Map<String, dynamic> mutableRow = Map<String, dynamic>.from(row);
              mutableRow.forEach((key, value) {
                if (value is bool) mutableRow[key] = value ? 1 : 0;
              });

              // Restore Project Photos from Base64
              if (tableName == 'project_photos' &&
                  mutableRow.containsKey('base64Data')) {
                try {
                  String base64 = mutableRow['base64Data'];
                  String fileName =
                      "photo_${DateTime.now().microsecondsSinceEpoch}.jpg";
                  if (mutableRow['uri'] != null) {
                    fileName = mutableRow['uri'].split('/').last;
                  }

                  final photoDir = Directory('$currentAppDirPath/photos');
                  if (!await photoDir.exists())
                    await photoDir.create(recursive: true);

                  final file = File('${photoDir.path}/$fileName');
                  await file.writeAsBytes(base64Decode(base64));

                  mutableRow['uri'] = file.path;
                  mutableRow.remove('base64Data');
                } catch (e) {
                  print("Sync: Error restoring photo: $e");
                }
              } else if (tableName == 'global_settings' &&
                  mutableRow.containsKey('logoBase64')) {
                try {
                  String base64 = mutableRow['logoBase64'];
                  final file = File('$currentAppDirPath/company_logo.png');
                  await file.writeAsBytes(base64Decode(base64));
                  mutableRow['logoUri'] = file.path;
                  mutableRow.remove('logoBase64');
                } catch (_) {}
              } else if (tableName == 'project_photos' &&
                  mutableRow.containsKey('uri')) {
                // Fallback for old style sync
                String? oldUri = mutableRow['uri'];
                if (oldUri != null) {
                  String fileName = oldUri.split('/').last;
                  mutableRow['uri'] = '$currentAppDirPath/photos/$fileName';
                }
              } else if (tableName == 'project_sketches' &&
                  mutableRow.containsKey('imagePath')) {
                String? oldPath = mutableRow['imagePath'];
                if (oldPath != null) {
                  String fileName = oldPath.split('/').last;
                  mutableRow['imagePath'] = '$currentAppDirPath/$fileName';
                }
              } else if (tableName == 'project_documents' &&
                  mutableRow.containsKey('filePath')) {
                String? oldPath = mutableRow['filePath'];
                if (oldPath != null) {
                  String fileName = oldPath.split('/').last;
                  // Documents are in documents/projectId/fileName
                  // But since we don't have projectId easily here without parsing row, 
                  // and we just want to point to the current app dir's documents folder if it exists.
                  // Actually, project_documents table has projectId.
                  int? pId = mutableRow['projectId'];
                  if (pId != null) {
                    mutableRow['filePath'] = '$currentAppDirPath/documents/$pId/$fileName';
                  }
                }
              }

              try {
                await txn.insert(tableName, mutableRow);
              } catch (e) {
                print("Import error into $tableName: $e");
              }
            }
          }
        }
      }
    });
  }
}
