import 'package:mtc2026/models/enums.dart';
import 'dart:convert';

class Project {
  final int id;
  final String name;
  final String clientName;
  final String address;
  final int dateCreated;
  final bool isCompleted;
  final double taxableAmountForVat;
  final int? clientId;
  final String clientPhone;
  final String clientEmail;
  final int? startDate;
  final int? deliveryDate;
  final int status; // 0: Lead, 1: Active, 2: Completed
  final double proposalValue;
  final int? managerId;

  Project({
    this.id = 0,
    required this.name,
    required this.clientName,
    required this.address,
    int? dateCreated,
    this.isCompleted = false,
    this.taxableAmountForVat = 0.0,
    this.clientId,
    this.clientPhone = "",
    this.clientEmail = "",
    this.startDate,
    this.deliveryDate,
    this.status = 1,
    this.proposalValue = 0.0,
    this.managerId,
  }) : dateCreated = dateCreated ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'clientName': clientName,
      'address': address,
      'dateCreated': dateCreated,
      'isCompleted': isCompleted ? 1 : 0,
      'taxableAmountForVat': taxableAmountForVat,
      'clientId': clientId,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'startDate': startDate,
      'deliveryDate': deliveryDate,
      'status': status,
      'proposalValue': proposalValue,
      'managerId': managerId,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? 0,
      name: map['name'] ?? "",
      clientName: map['clientName'] ?? "",
      address: map['address'] ?? "",
      dateCreated: map['dateCreated'] ?? DateTime.now().millisecondsSinceEpoch,
      isCompleted: map['isCompleted'] == 1,
      taxableAmountForVat: (map['taxableAmountForVat'] as num?)?.toDouble() ?? 0.0,
      clientId: map['clientId'],
      clientPhone: map['clientPhone'] ?? "",
      clientEmail: map['clientEmail'] ?? "",
      startDate: map['startDate'],
      deliveryDate: map['deliveryDate'],
      status: map['status'] ?? (map['isCompleted'] == 1 ? 2 : 1),
      proposalValue: (map['proposalValue'] as num?)?.toDouble() ?? 0.0,
      managerId: map['managerId'],
    );
  }

  Project copyWith({
    int? id,
    String? name,
    String? clientName,
    String? address,
    int? dateCreated,
    bool? isCompleted,
    double? taxableAmountForVat,
    int? clientId,
    String? clientPhone,
    String? clientEmail,
    int? startDate,
    int? deliveryDate,
    int? status,
    double? proposalValue,
    int? managerId,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      dateCreated: dateCreated ?? this.dateCreated,
      isCompleted: isCompleted ?? this.isCompleted,
      taxableAmountForVat: taxableAmountForVat ?? this.taxableAmountForVat,
      clientId: clientId ?? this.clientId,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      startDate: startDate ?? this.startDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      proposalValue: proposalValue ?? this.proposalValue,
      managerId: managerId ?? this.managerId,
    );
  }
}

class Client {
  final int id;
  final String name;
  final String phone;
  final String email;
  final int dateAdded;
  final String status; // LEAD, ACTIVE, PAST
  final int? followUpDate;

  Client({
    this.id = 0,
    required this.name,
    required this.phone,
    required this.email,
    int? dateAdded,
    this.status = "ACTIVE",
    this.followUpDate,
  }) : dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'dateAdded': dateAdded,
      'status': status,
      'followUpDate': followUpDate,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      dateAdded: map['dateAdded'],
      status: map['status'] ?? "ACTIVE",
      followUpDate: map['followUpDate'],
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    int? dateAdded,
    String? status,
    int? followUpDate,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateAdded: dateAdded ?? this.dateAdded,
      status: status ?? this.status,
      followUpDate: followUpDate ?? this.followUpDate,
    );
  }
}

class Expense {
  final int id;
  final int? projectId;
  final int date;
  final String description;
  final String workerName;
  final double amount;
  final bool hasVat;
  final String? linkedCategory;
  final String? invoiceNumber;
  final String expenseType;
  final bool isGeneral;
  final String categoryType; // LABOR / MATERIAL

  Expense({
    this.id = 0,
    this.projectId,
    required this.date,
    required this.description,
    required this.workerName,
    required this.amount,
    this.hasVat = false,
    this.linkedCategory,
    this.invoiceNumber,
    this.expenseType = "PAYMENT",
    this.isGeneral = false,
    this.categoryType = "LABOR",
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'date': date,
      'description': description,
      'workerName': workerName,
      'amount': amount,
      'hasVat': hasVat ? 1 : 0,
      'linkedCategory': linkedCategory,
      'invoiceNumber': invoiceNumber,
      'expenseType': expenseType,
      'isGeneral': isGeneral ? 1 : 0,
      'categoryType': categoryType,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      projectId: map['projectId'],
      date: map['date'],
      description: map['description'],
      workerName: map['workerName'],
      amount: (map['amount'] as num).toDouble(),
      hasVat: map['hasVat'] == 1,
      linkedCategory: map['linkedCategory'],
      invoiceNumber: map['invoiceNumber'],
      expenseType: map['expenseType'] ?? "PAYMENT",
      isGeneral: map['isGeneral'] == 1,
      categoryType: map['categoryType'] ?? "LABOR",
    );
  }
}

class Task {
  final int id;
  final int projectId;
  final int date;
  final String description;
  final bool isCompleted;
  final int? reminderTime;
  final String? reminderType;

  Task({
    this.id = 0,
    required this.projectId,
    required this.date,
    required this.description,
    this.isCompleted = false,
    this.reminderTime,
    this.reminderType,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'date': date,
      'description': description,
      'isCompleted': isCompleted ? 1 : 0,
      'reminderTime': reminderTime,
      'reminderType': reminderType,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      projectId: map['projectId'],
      date: map['date'],
      description: map['description'],
      isCompleted: map['isCompleted'] == 1,
      reminderTime: map['reminderTime'],
      reminderType: map['reminderType'],
    );
  }
}

class Partner {
  final int id;
  final String name;
  final String phone;
  final String trade;
  final double baseRate;

  Partner({
    this.id = 0,
    required this.name,
    required this.phone,
    required this.trade,
    this.baseRate = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'phone': phone,
      'trade': trade,
      'baseRate': baseRate,
    };
  }

  factory Partner.fromMap(Map<String, dynamic> map) {
    return Partner(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      trade: map['trade'],
      baseRate: (map['baseRate'] as num).toDouble(),
    );
  }
}

class Settings {
  final int id;
  final String ownerName;
  final String companyName;
  final String phone;
  final String email;
  final String tagline;
  final bool isPaymentReminderEnabled;
  final String? logoUri;
  final String vatNumber;
  final String appTheme;
  final String dbApiUrl;
  final String aiApiUrl;
  final String aiApiKey;

  Settings({
    this.id = 1,
    this.ownerName = "",
    this.companyName = "",
    this.phone = "",
    this.email = "",
    this.tagline = "",
    this.isPaymentReminderEnabled = true,
    this.logoUri,
    this.vatNumber = "",
    this.appTheme = "SYSTEM",
    this.dbApiUrl = "",
    this.aiApiUrl = "",
    this.aiApiKey = "",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerName': ownerName,
      'companyName': companyName,
      'phone': phone,
      'email': email,
      'tagline': tagline,
      'isPaymentReminderEnabled': isPaymentReminderEnabled ? 1 : 0,
      'logoUri': logoUri,
      'vatNumber': vatNumber,
      'appTheme': appTheme,
      'dbApiUrl': dbApiUrl,
      'aiApiUrl': aiApiUrl,
      'aiApiKey': aiApiKey,
    };
  }

  factory Settings.fromMap(Map<String, dynamic> map) {
    return Settings(
      id: map['id'] ?? 1,
      ownerName: map['ownerName'] ?? "",
      companyName: map['companyName'] ?? "",
      phone: map['phone'] ?? "",
      email: map['email'] ?? "",
      tagline: map['tagline'] ?? "",
      isPaymentReminderEnabled: map['isPaymentReminderEnabled'] == 1,
      logoUri: map['logoUri'],
      vatNumber: map['vatNumber'] ?? "",
      appTheme: map['appTheme'] ?? "SYSTEM",
      dbApiUrl: map['dbApiUrl'] ?? "",
      aiApiUrl: map['aiApiUrl'] ?? "",
      aiApiKey: map['aiApiKey'] ?? "",
    );
  }
}

class Income {
  final int id;
  final int projectId;
  final int date;
  final String description;
  final double amount;
  final bool hasVat;

  Income({
    this.id = 0,
    required this.projectId,
    int? date,
    required this.description,
    required this.amount,
    this.hasVat = false,
  }) : date = date ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'date': date,
      'description': description,
      'amount': amount,
      'hasVat': hasVat ? 1 : 0,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      projectId: map['projectId'],
      date: map['date'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      hasVat: map['hasVat'] == 1,
    );
  }
}

class QuoteItem {
  final String id;
  final AppDestinations category;
  final String subCategory;
  final String description;
  final String unit;
  final String quantity;
  final String unitPrice;
  final double categoryProfitMargin;
  final bool useCustomMargin;
  final double customProfitMargin;
  final String internalNote;
  final bool hasVat;
  final bool isVatInclusive;
  final bool showVatToClient;
  final bool showPriceToClient;

  QuoteItem({
    this.id = "",
    required this.category,
    this.subCategory = "",
    required this.description,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.categoryProfitMargin = 20.0,
    this.useCustomMargin = false,
    this.customProfitMargin = 20.0,
    this.internalNote = "",
    this.hasVat = false,
    this.isVatInclusive = true,
    this.showVatToClient = false,
    this.showPriceToClient = true,
  });

  double get cost {
    final q = double.tryParse(quantity.replaceAll(',', '.')) ?? 0.0;
    final p = double.tryParse(unitPrice.replaceAll(',', '.')) ?? 0.0;
    final total = q * p;
    return (hasVat && isVatInclusive) ? total / 1.24 : total;
  }

  double get priceForClient {
    final basePrice = (hasVat && !showVatToClient)
        ? (isVatInclusive
            ? (double.tryParse(quantity.replaceAll(',', '.')) ?? 0.0) * (double.tryParse(unitPrice.replaceAll(',', '.')) ?? 0.0)
            : (double.tryParse(quantity.replaceAll(',', '.')) ?? 0.0) * (double.tryParse(unitPrice.replaceAll(',', '.')) ?? 0.0) * 1.24)
        : cost;
    final margin = useCustomMargin ? customProfitMargin : categoryProfitMargin;
    return basePrice * (1 + (margin / 100));
  }

  double get netPriceForClient {
    // Always returns the price WITHOUT VAT
    final q = double.tryParse(quantity.replaceAll(',', '.')) ?? 0.0;
    final p = double.tryParse(unitPrice.replaceAll(',', '.')) ?? 0.0;
    final total = q * p;
    final netBase = (hasVat && isVatInclusive) ? total / 1.24 : total;
    final margin = useCustomMargin ? customProfitMargin : categoryProfitMargin;
    return netBase * (1 + (margin / 100));
  }

  Map<String, dynamic> toMap(int projectId) {
    return {
      if (id.isNotEmpty && int.tryParse(id) != null) 'id': int.parse(id),
      'projectId': projectId,
      'category': category.name,
      'subCategory': subCategory,
      'description': description,
      'unit': unit,
      'quantity': double.tryParse(quantity.replaceAll(',', '.')) ?? 0.0,
      'unitPrice': double.tryParse(unitPrice.replaceAll(',', '.')) ?? 0.0,
      'categoryProfitMargin': categoryProfitMargin,
      'useCustomMargin': useCustomMargin ? 1 : 0,
      'customProfitMargin': customProfitMargin,
      'internalNote': internalNote,
      'hasVat': hasVat ? 1 : 0,
      'isVatInclusive': isVatInclusive ? 1 : 0,
      'showVatToClient': showVatToClient ? 1 : 0,
      'showPriceToClient': showPriceToClient ? 1 : 0,
    };
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      id: map['id'].toString(),
      category: AppDestinations.values.firstWhere((e) => e.name == map['category'], orElse: () => AppDestinations.GENERAL),
      subCategory: map['subCategory'] ?? "",
      description: map['description'],
      unit: map['unit'],
      quantity: map['quantity'].toString(),
      unitPrice: map['unitPrice'].toString(),
      categoryProfitMargin: (map['categoryProfitMargin'] as num).toDouble(),
      useCustomMargin: map['useCustomMargin'] == 1,
      customProfitMargin: (map['customProfitMargin'] as num).toDouble(),
      internalNote: map['internalNote'] ?? "",
      hasVat: map['hasVat'] == 1,
      isVatInclusive: map['isVatInclusive'] == 1,
      showVatToClient: map['showVatToClient'] == 1,
      showPriceToClient: map['showPriceToClient'] == null ? true : map['showPriceToClient'] == 1,
    );
  }
}

class Tool {
  final int id;
  final String name;
  final String category;
  final String locationType;
  final int locationId;
  final String? customLocationName;
  final int lastLocationUpdate;
  final String comments;
  final int dateAdded;
  final double quantity;

  Tool({
    this.id = 0,
    required this.name,
    this.category = "ΓΕΝΙΚΑ",
    this.locationType = "WAREHOUSE",
    this.locationId = 0,
    this.customLocationName,
    int? lastLocationUpdate,
    this.comments = "",
    int? dateAdded,
    this.quantity = 1.0,
  })  : lastLocationUpdate = lastLocationUpdate ?? DateTime.now().millisecondsSinceEpoch,
        dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'category': category,
      'locationType': locationType,
      'locationId': locationId,
      'customLocationName': customLocationName,
      'lastLocationUpdate': lastLocationUpdate,
      'comments': comments,
      'dateAdded': dateAdded,
      'quantity': quantity,
    };
  }

  factory Tool.fromMap(Map<String, dynamic> map) {
    return Tool(
      id: map['id'],
      name: map['name'],
      category: map['category'] ?? "ΓΕΝΙΚΑ",
      locationType: map['locationType'] ?? "WAREHOUSE",
      locationId: map['locationId'] ?? 0,
      customLocationName: map['customLocationName'],
      lastLocationUpdate: map['lastLocationUpdate'],
      comments: map['comments'] ?? "",
      dateAdded: map['dateAdded'],
      quantity: (map['quantity'] as num).toDouble(),
    );
  }
}

class MaterialEntity {
  final int id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final String locationType;
  final String? colorCode;
  final int? purchaseDate;
  final int? projectId;
  final int lastUpdated;
  final double minStockThreshold;

  MaterialEntity({
    this.id = 0,
    required this.name,
    required this.category,
    required this.quantity,
    this.unit = "",
    this.locationType = "WAREHOUSE",
    this.colorCode,
    this.purchaseDate,
    this.projectId,
    int? lastUpdated,
    this.minStockThreshold = 0.0,
  }) : lastUpdated = lastUpdated ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'locationType': locationType,
      'colorCode': colorCode,
      'purchaseDate': purchaseDate,
      'projectId': projectId,
      'lastUpdated': lastUpdated,
      'minStockThreshold': minStockThreshold,
    };
  }

  factory MaterialEntity.fromMap(Map<String, dynamic> map) {
    return MaterialEntity(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] ?? "",
      locationType: map['locationType'] ?? "WAREHOUSE",
      colorCode: map['colorCode'],
      purchaseDate: map['purchaseDate'],
      projectId: map['projectId'],
      lastUpdated: map['lastUpdated'],
      minStockThreshold: (map['minStockThreshold'] as num).toDouble(),
    );
  }
}

class ProjectROIData {
  final double quoteAmount;
  final double actualIncome;
  final double laborCosts;
  final double materialExpenses;
  final double fixedCostsContribution;
  final double netProfit;
  final double roiPercentage;
  final double realNetProfit;
  final double realRoiPercentage;

  ProjectROIData({
    required this.quoteAmount,
    required this.actualIncome,
    required this.laborCosts,
    required this.materialExpenses,
    required this.fixedCostsContribution,
    required this.netProfit,
    required this.roiPercentage,
    required this.realNetProfit,
    required this.realRoiPercentage,
  });
}

class ProjectPhotoEntity {
  final int id;
  final int projectId;
  final String uri;
  final String description;
  final int dateAdded;
  final String folderName;

  ProjectPhotoEntity({
    this.id = 0,
    required this.projectId,
    required this.uri,
    this.description = "",
    int? dateAdded,
    this.folderName = "ΓΕΝΙΚΑ",
  }) : dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'uri': uri,
      'description': description,
      'dateAdded': dateAdded,
      'folderName': folderName,
    };
  }

  factory ProjectPhotoEntity.fromMap(Map<String, dynamic> map) {
    return ProjectPhotoEntity(
      id: map['id'],
      projectId: map['projectId'],
      uri: map['uri'],
      description: map['description'] ?? "",
      dateAdded: map['dateAdded'],
      folderName: map['folderName'] ?? "ΓΕΝΙΚΑ",
    );
  }
}

class AttendanceEntity {
  final int id;
  final int? projectId;
  final int date;
  final String workerName;
  final double dailyRate;
  final double overtimeAmount;
  final String workCategory;
  final String note;
  final bool isConfirmed;

  AttendanceEntity({
    this.id = 0,
    this.projectId,
    required this.date,
    required this.workerName,
    required this.dailyRate,
    this.overtimeAmount = 0.0,
    this.workCategory = "ΓΕΝΙΚΑ",
    this.note = "",
    this.isConfirmed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'date': date,
      'workerName': workerName,
      'dailyRate': dailyRate,
      'overtimeAmount': overtimeAmount,
      'workCategory': workCategory,
      'note': note,
      'isConfirmed': isConfirmed ? 1 : 0,
    };
  }

  factory AttendanceEntity.fromMap(Map<String, dynamic> map) {
    return AttendanceEntity(
      id: map['id'],
      projectId: map['projectId'],
      date: map['date'],
      workerName: map['workerName'],
      dailyRate: (map['dailyRate'] as num).toDouble(),
      overtimeAmount: (map['overtimeAmount'] as num?)?.toDouble() ?? 0.0,
      workCategory: map['workCategory'] ?? "ΓΕΝΙΚΑ",
      note: map['note'] ?? "",
      isConfirmed: map['isConfirmed'] == 1,
    );
  }
}

class CompanyExpenseEntity {
  final int id;
  final int date;
  final String description;
  final double amount;
  final bool isMonthly;
  final bool hasVat;
  final String? invoiceNumber;

  CompanyExpenseEntity({
    this.id = 0,
    int? date,
    required this.description,
    required this.amount,
    this.isMonthly = false,
    this.hasVat = false,
    this.invoiceNumber,
  }) : date = date ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'date': date,
      'description': description,
      'amount': amount,
      'isMonthly': isMonthly ? 1 : 0,
      'hasVat': hasVat ? 1 : 0,
      'invoiceNumber': invoiceNumber,
    };
  }

  factory CompanyExpenseEntity.fromMap(Map<String, dynamic> map) {
    return CompanyExpenseEntity(
      id: map['id'],
      date: map['date'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      isMonthly: map['isMonthly'] == 1,
      hasVat: map['hasVat'] == 1,
      invoiceNumber: map['invoiceNumber'],
    );
  }
}

class ProjectStageEntity {
  final int id;
  final int projectId;
  final String name;
  final double progress;
  final int displayOrder;

  ProjectStageEntity({
    this.id = 0,
    required this.projectId,
    required this.name,
    this.progress = 0.0,
    this.displayOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'name': name,
      'progress': progress,
      'displayOrder': displayOrder,
    };
  }

  factory ProjectStageEntity.fromMap(Map<String, dynamic> map) {
    return ProjectStageEntity(
      id: map['id'],
      projectId: map['projectId'],
      name: map['name'],
      progress: (map['progress'] as num).toDouble(),
      displayOrder: map['displayOrder'] ?? 0,
    );
  }

  ProjectStageEntity copyWith({double? progress}) {
    return ProjectStageEntity(
      id: id,
      projectId: projectId,
      name: name,
      progress: progress ?? this.progress,
      displayOrder: displayOrder,
    );
  }
}

class ShoppingItemEntity {
  final int id;
  final int projectId;
  final String description;
  final String quantity;
  final bool isBought;
  final String suggestedStore;
  final int dateAdded;

  ShoppingItemEntity({
    this.id = 0,
    required this.projectId,
    required this.description,
    this.quantity = "",
    this.isBought = false,
    this.suggestedStore = "",
    int? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'description': description,
      'quantity': quantity,
      'isBought': isBought ? 1 : 0,
      'suggestedStore': suggestedStore,
      'dateAdded': dateAdded,
    };
  }

  factory ShoppingItemEntity.fromMap(Map<String, dynamic> map) {
    return ShoppingItemEntity(
      id: map['id'],
      projectId: map['projectId'],
      description: map['description'],
      quantity: map['quantity'] ?? "",
      isBought: map['isBought'] == 1,
      suggestedStore: map['suggestedStore'] ?? "",
      dateAdded: map['dateAdded'],
    );
  }

  ShoppingItemEntity copyWith({bool? isBought}) {
    return ShoppingItemEntity(
      id: id,
      projectId: projectId,
      description: description,
      quantity: quantity,
      isBought: isBought ?? this.isBought,
      suggestedStore: suggestedStore,
      dateAdded: dateAdded,
    );
  }
}

class VehicleEntity {
  final int id;
  final String name;
  final String plateNumber;
  final int insuranceExpiry;
  final int kteoExpiry;
  final int currentMileage;
  final int lastServiceMileage;

  VehicleEntity({
    this.id = 0,
    this.name = "ΕΤΑΙΡΙΚΟ ΒΑΝ",
    this.plateNumber = "",
    int? insuranceExpiry,
    int? kteoExpiry,
    this.currentMileage = 0,
    this.lastServiceMileage = 0,
  })  : insuranceExpiry = insuranceExpiry ?? DateTime.now().millisecondsSinceEpoch,
        kteoExpiry = kteoExpiry ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'plateNumber': plateNumber,
      'insuranceExpiry': insuranceExpiry,
      'kteoExpiry': kteoExpiry,
      'currentMileage': currentMileage,
      'lastServiceMileage': lastServiceMileage,
    };
  }

  factory VehicleEntity.fromMap(Map<String, dynamic> map) {
    return VehicleEntity(
      id: map['id'],
      name: map['name'] ?? "ΕΤΑΙΡΙΚΟ ΒΑΝ",
      plateNumber: map['plateNumber'] ?? "",
      insuranceExpiry: map['insuranceExpiry'],
      kteoExpiry: map['kteoExpiry'],
      currentMileage: map['currentMileage'] ?? 0,
      lastServiceMileage: map['lastServiceMileage'] ?? 0,
    );
  }

  VehicleEntity copyWith({String? name, String? plateNumber, int? currentMileage, int? lastServiceMileage, int? insuranceExpiry, int? kteoExpiry}) {
    return VehicleEntity(
      id: id,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      currentMileage: currentMileage ?? this.currentMileage,
      lastServiceMileage: lastServiceMileage ?? this.lastServiceMileage,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      kteoExpiry: kteoExpiry ?? this.kteoExpiry,
    );
  }
}

class VehicleMaintenanceEntity {
  final int id;
  final int vehicleId;
  final int date;
  final String description;
  final double cost;
  final int mileage;

  VehicleMaintenanceEntity({
    this.id = 0,
    required this.vehicleId,
    int? date,
    required this.description,
    this.cost = 0.0,
    this.mileage = 0,
  }) : date = date ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'vehicleId': vehicleId,
      'date': date,
      'description': description,
      'cost': cost,
      'mileage': mileage,
    };
  }

  factory VehicleMaintenanceEntity.fromMap(Map<String, dynamic> map) {
    return VehicleMaintenanceEntity(
      id: map['id'],
      vehicleId: map['vehicleId'],
      date: map['date'],
      description: map['description'],
      cost: (map['cost'] as num).toDouble(),
      mileage: map['mileage'] ?? 0,
    );
  }
}

class GlobalPriceEntity {
  final int id;
  final String category;
  final String description;
  final String unit;
  final double defaultUnitPrice;

  GlobalPriceEntity({this.id = 0, required this.category, required this.description, required this.unit, required this.defaultUnitPrice});

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'category': category,
      'description': description,
      'unit': unit,
      'defaultUnitPrice': defaultUnitPrice,
    };
  }

  factory GlobalPriceEntity.fromMap(Map<String, dynamic> map) {
    return GlobalPriceEntity(
      id: map['id'],
      category: map['category'],
      description: map['description'],
      unit: map['unit'],
      defaultUnitPrice: (map['defaultUnitPrice'] as num).toDouble(),
    );
  }
}

class PartnerAgreement {
  final int id;
  final int projectId;
  final int partnerId;
  final String category;
  final double amount;

  PartnerAgreement({
    this.id = 0,
    required this.projectId,
    required this.partnerId,
    required this.category,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'partnerId': partnerId,
      'category': category,
      'amount': amount,
    };
  }

  factory PartnerAgreement.fromMap(Map<String, dynamic> map) {
    return PartnerAgreement(
      id: map['id'],
      projectId: map['projectId'],
      partnerId: map['partnerId'],
      category: map['category'],
      amount: (map['amount'] as num).toDouble(),
    );
  }
}

class MarketArchiveItem {
  final int id;
  final String name;
  final String category;
  final String subCategory;
  final String type; // MATERIAL / TOOL
  final String supplier;
  final double price;
  final String unit;
  final bool hasVat;
  final int dateAdded;

  MarketArchiveItem({
    this.id = 0,
    required this.name,
    required this.category,
    this.subCategory = "ΓΕΝΙΚΑ",
    required this.type,
    required this.supplier,
    required this.price,
    required this.unit,
    this.hasVat = false,
    required this.dateAdded,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'category': category,
      'subCategory': subCategory,
      'type': type,
      'supplier': supplier,
      'price': price,
      'unit': unit,
      'hasVat': hasVat ? 1 : 0,
      'dateAdded': dateAdded,
    };
  }

  factory MarketArchiveItem.fromMap(Map<String, dynamic> map) {
    return MarketArchiveItem(
      id: map['id'] ?? 0,
      name: map['name'] ?? "",
      category: map['category'] ?? "",
      subCategory: map['subCategory'] ?? "ΓΕΝΙΚΑ",
      type: map['type'] ?? "MATERIAL",
      supplier: map['supplier'] ?? "",
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] ?? "",
      hasVat: map['hasVat'] == 1,
      dateAdded: map['dateAdded'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class PartnerBid {
  final int id;
  final int projectId;
  final int partnerId;
  final String partnerName;
  final String category;
  final double amount;
  final String notes;
  final int dateAdded;
  final bool isAccepted;

  PartnerBid({
    this.id = 0,
    required this.projectId,
    required this.partnerId,
    required this.partnerName,
    required this.category,
    required this.amount,
    this.notes = "",
    int? dateAdded,
    this.isAccepted = false,
  }) : dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'category': category,
      'amount': amount,
      'notes': notes,
      'dateAdded': dateAdded,
      'isAccepted': isAccepted ? 1 : 0,
    };
  }

  factory PartnerBid.fromMap(Map<String, dynamic> map) {
    return PartnerBid(
      id: map['id'],
      projectId: map['projectId'],
      partnerId: map['partnerId'],
      partnerName: map['partnerName'] ?? "",
      category: map['category'] ?? "GENERAL",
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] ?? "",
      dateAdded: map['dateAdded'],
      isAccepted: map['isAccepted'] == 1,
    );
  }
}

class JobRecipe {
  final int id;
  final String name;
  final String category;
  final String description;
  final List<RecipeComponent> materials;
  final double estimatedLabor;

  JobRecipe({
    this.id = 0,
    required this.name,
    required this.category,
    this.description = "",
    required this.materials,
    this.estimatedLabor = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'category': category,
      'description': description,
      'materialsJson': jsonEncode(materials.map((m) => m.toMap()).toList()),
      'estimatedLabor': estimatedLabor,
    };
  }

  factory JobRecipe.fromMap(Map<String, dynamic> map) {
    final List<dynamic> matList = jsonDecode(map['materialsJson'] ?? '[]');
    return JobRecipe(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      description: map['description'] ?? "",
      materials: matList.map((m) => RecipeComponent.fromMap(m)).toList(),
      estimatedLabor: (map['estimatedLabor'] as num).toDouble(),
    );
  }
}

class RecipeComponent {
  final String name;
  final double quantityPerUnit; // e.g. per m2
  final String unit;

  RecipeComponent({required this.name, required this.quantityPerUnit, required this.unit});

  Map<String, dynamic> toMap() => {'name': name, 'quantityPerUnit': quantityPerUnit, 'unit': unit};
  factory RecipeComponent.fromMap(Map<String, dynamic> map) => RecipeComponent(
    name: map['name'] ?? "",
    quantityPerUnit: (map['quantityPerUnit'] as num).toDouble(),
    unit: map['unit'] ?? "",
  );
}

class PortfolioItem {
  final int id;
  final String uri;
  final String category; // e.g. BATHROOM, KITCHEN
  final String description;
  final int dateAdded;

  PortfolioItem({
    this.id = 0,
    required this.uri,
    required this.category,
    this.description = "",
    int? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'uri': uri,
      'category': category,
      'description': description,
      'dateAdded': dateAdded,
    };
  }

  factory PortfolioItem.fromMap(Map<String, dynamic> map) {
    return PortfolioItem(
      id: map['id'],
      uri: map['uri'],
      category: map['category'] ?? "GENERAL",
      description: map['description'] ?? "",
      dateAdded: map['dateAdded'],
    );
  }
}

class ProjectChecklistItem {
  final int id;
  final int projectId;
  final String title;
  final bool isChecked;

  ProjectChecklistItem({
    this.id = 0,
    required this.projectId,
    required this.title,
    this.isChecked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'title': title,
      'isChecked': isChecked ? 1 : 0,
    };
  }

  factory ProjectChecklistItem.fromMap(Map<String, dynamic> map) {
    return ProjectChecklistItem(
      id: map['id'],
      projectId: map['projectId'],
      title: map['title'] ?? "",
      isChecked: map['isChecked'] == 1,
    );
  }
}

class ProjectNote {
  final int id;
  final int projectId;
  final String content;
  final int dateAdded;

  ProjectNote({
    this.id = 0,
    required this.projectId,
    required this.content,
    int? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'content': content,
      'dateAdded': dateAdded,
    };
  }

  factory ProjectNote.fromMap(Map<String, dynamic> map) {
    return ProjectNote(
      id: map['id'],
      projectId: map['projectId'],
      content: map['content'] ?? "",
      dateAdded: map['dateAdded'],
    );
  }

  ProjectNote copyWith({String? content}) {
    return ProjectNote(
      id: id,
      projectId: projectId,
      content: content ?? this.content,
      dateAdded: dateAdded,
    );
  }
}

class ProjectSketch {
  final int id;
  final int projectId;
  final String title;
  final String folder;
  final String imagePath;
  final String vectorDataJson; // Stores JSON of all shapes
  final int dateAdded;

  ProjectSketch({
    this.id = 0,
    required this.projectId,
    required this.title,
    this.folder = "ΓΕΝΙΚΑ",
    required this.imagePath,
    required this.vectorDataJson,
    int? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'title': title,
      'folder': folder,
      'imagePath': imagePath,
      'vectorDataJson': vectorDataJson,
      'dateAdded': dateAdded,
    };
  }

  factory ProjectSketch.fromMap(Map<String, dynamic> map) {
    return ProjectSketch(
      id: map['id'],
      projectId: map['projectId'],
      title: map['title'] ?? "",
      folder: map['folder'] ?? "ΓΕΝΙΚΑ",
      imagePath: map['imagePath'] ?? "",
      vectorDataJson: map['vectorDataJson'] ?? "[]",
      dateAdded: map['dateAdded'],
    );
  }
}

class ProjectDocument {
  final int id;
  final int projectId;
  final String title;
  final String filePath;
  final String fileExtension;
  final int dateAdded;

  ProjectDocument({
    this.id = 0,
    required this.projectId,
    required this.title,
    required this.filePath,
    required this.fileExtension,
    int? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() {
    return {
      if (id != 0) 'id': id,
      'projectId': projectId,
      'title': title,
      'filePath': filePath,
      'fileExtension': fileExtension,
      'dateAdded': dateAdded,
    };
  }

  factory ProjectDocument.fromMap(Map<String, dynamic> map) {
    return ProjectDocument(
      id: map['id'],
      projectId: map['projectId'],
      title: map['title'] ?? "",
      filePath: map['filePath'] ?? "",
      fileExtension: map['fileExtension'] ?? "",
      dateAdded: map['dateAdded'],
    );
  }
}

class Manager {
  final int id;
  final String name;
  final String pin;

  Manager({this.id = 0, required this.name, required this.pin});

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'name': name,
      'pin': pin,
    };
  }

  factory Manager.fromMap(Map<String, dynamic> map) {
    return Manager(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      pin: map['pin'] ?? '',
    );
  }
}
