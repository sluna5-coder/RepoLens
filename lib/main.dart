import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app.dart';

/// Punto de entrada de RepoLens.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // En el navegador, SQLite corre como WebAssembly (web/sqlite3.wasm) y guarda
  // los datos en IndexedDB. En Android se usa el SQLite nativo.
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  runApp(const RepoLensApp());
}
