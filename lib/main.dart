import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:suivi_mvt_armoire_seche/screens/home_screen.dart';
import 'models/stock_model.dart';
import 'database/stock_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await StockDatabase.init();

  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Suivi des Stocks',
      theme: ThemeData.light(),
      home:  HomeScreen(),
    );
  }
}
