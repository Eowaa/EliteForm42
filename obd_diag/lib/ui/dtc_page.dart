import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../obd/dtc.dart';
import '../state/obd_provider.dart';

class DtcPage extends StatelessWidget {
  const DtcPage({super.key});

  @override
  Widget build(BuildContext context) {
    final obd = context.watch<ObdProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fehlerspeicher'),
        actions: [
          IconButton(
            tooltip: 'Auslesen',
            onPressed: obd.dtcBusy ? null : obd.readDtcs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: obd.dtcBusy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MilCard(status: obd.milStatus),
                const SizedBox(height: 16),
                _Section(
                  title: 'Gespeicherte Fehler (Mode 03)',
                  codes: obd.storedDtcs,
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Sporadische Fehler (Mode 07)',
                  codes: obd.pendingDtcs,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: obd.storedDtcs.isEmpty && obd.pendingDtcs.isEmpty
                      ? null
                      : () => _confirmClear(context, obd),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Fehlerspeicher löschen'),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Löschen setzt auch die Readiness-Monitore zurück. Bis '
                    'diese neu durchgelaufen sind, ist das Fahrzeug nicht '
                    'AU-fähig.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, ObdProvider obd) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fehlerspeicher löschen?'),
        content: const Text(
          'Alle Codes und die Readiness-Monitore werden zurückgesetzt. '
          'Ein Fehler, dessen Ursache nicht behoben ist, kommt wieder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final ok = await obd.clearDtcs();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Fehlerspeicher gelöscht.' : 'Löschen fehlgeschlagen.'),
      ),
    );
  }
}

class _MilCard extends StatelessWidget {
  const _MilCard({required this.status});
  final MilStatus? status;

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('Noch nicht ausgelesen'),
          subtitle: Text('Oben rechts auf Aktualisieren tippen.'),
        ),
      );
    }

    final lampOn = status!.lampOn;
    return Card(
      child: ListTile(
        leading: Icon(
          lampOn ? Icons.error : Icons.check_circle,
          color: lampOn ? Colors.orange : Colors.green,
        ),
        title: Text(
          lampOn ? 'Motorkontrollleuchte aktiv' : 'Keine Warnleuchte aktiv',
        ),
        subtitle: Text('${status!.dtcCount} Code(s) im Speicher'),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.codes});
  final String title;
  final List<Dtc> codes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (codes.isEmpty)
          const Text('Keine Einträge.')
        else
          for (final dtc in codes)
            Card(
              child: ListTile(
                title: Text(
                  dtc.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(dtc.description),
              ),
            ),
      ],
    );
  }
}
