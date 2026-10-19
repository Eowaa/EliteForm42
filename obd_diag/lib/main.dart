import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/obd_provider.dart';
import 'ui/home_shell.dart';

void main() => runApp(const ObdDiagApp());

class ObdDiagApp extends StatelessWidget {
  const ObdDiagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ObdProvider(),
      child: MaterialApp(
        title: 'OBD Diag',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3DDC97),
            brightness: Brightness.dark,
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}
