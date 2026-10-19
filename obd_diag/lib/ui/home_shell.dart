import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/obd_provider.dart';
import 'connect_page.dart';
import 'dtc_page.dart';
import 'live_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final connected = context.select<ObdProvider, bool>(
      (p) => p.status == ObdStatus.ready,
    );

    // Ohne Verbindung sind Live-Daten und Fehlerspeicher sinnlos.
    final effectiveIndex = connected ? _index : 0;

    return Scaffold(
      body: IndexedStack(
        index: effectiveIndex,
        children: const [ConnectPage(), LivePage(), DtcPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: effectiveIndex,
        onDestinationSelected: (i) {
          if (!connected && i != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erst Adapter verbinden.')),
            );
            return;
          }
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bluetooth),
            label: 'Verbinden',
          ),
          NavigationDestination(
            icon: Icon(Icons.speed),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber),
            label: 'Fehler',
          ),
        ],
      ),
    );
  }
}
