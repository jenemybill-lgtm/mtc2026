import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void initDatabaseForPlatform() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
