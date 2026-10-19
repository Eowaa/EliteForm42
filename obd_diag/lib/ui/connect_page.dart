import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/obd_provider.dart';

class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final obd = context.watch<ObdProvider>();
    final scanning = obd.status == ObdStatus.scanning;
    final busy = obd.status == ObdStatus.connecting ||
        obd.status == ObdStatus.initializing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adapter verbinden'),
        actions: [
          if (obd.status == ObdStatus.ready)
            IconButton(
              tooltip: 'Trennen',
              onPressed: obd.disconnect,
              icon: const Icon(Icons.link_off),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (Platform.isIOS) const _IosHint(),
          if (obd.errorMessage != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(obd.errorMessage!),
              ),
            ),
          if (obd.status == ObdStatus.ready) _ConnectedCard(obd: obd),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy
                ? null
                : scanning
                    ? obd.stopScan
                    : obd.startScan,
            icon: Icon(scanning ? Icons.stop : Icons.search),
            label: Text(scanning ? 'Suche stoppen' : 'Geräte suchen'),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
          for (final result in obd.scanResults)
            ListTile(
              leading: const Icon(Icons.memory),
              title: Text(result.device.platformName),
              subtitle: Text(
                '${result.device.remoteId} · ${result.rssi} dBm',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: busy ? null : () => obd.connect(result.device),
            ),
          if (!scanning && !busy && obd.scanResults.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Kein Gerät gefunden. Adapter eingesteckt, Zündung an?',
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.obd});
  final ObdProvider obd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(obd.vehicle?.displayName ?? obd.client.deviceName ?? 'Adapter'),
        subtitle: Text(
          [
            if (obd.vehicle != null) 'VIN ${obd.vehicle!.vin}',
            if (obd.adapterVersion != null) obd.adapterVersion!,
            '${obd.activePids.length} unterstützte Messwerte erkannt',
          ].join('\n'),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _IosHint extends StatelessWidget {
  const _IosHint();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Hinweis für iOS: Es werden nur BLE-Adapter gefunden. Klassische '
          'Bluetooth-Dongles (SPP/RFCOMM) kann iOS systemseitig nicht '
          'ansprechen – die erscheinen hier nicht.',
        ),
      ),
    );
  }
}
