import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../obd/adapter_probe.dart';

/// Zeigt, was ein Adapter kann – und wo er aufhört.
class ProbePage extends StatelessWidget {
  const ProbePage({super.key, required this.result});

  final ProbeResult result;

  Color _color(BuildContext context) => switch (result.verdict) {
        ProbeVerdict.elmCompatible => Colors.green,
        ProbeVerdict.respondsUnknown => Colors.orange,
        _ => Theme.of(context).colorScheme.error,
      };

  IconData get _icon => switch (result.verdict) {
        ProbeVerdict.elmCompatible => Icons.check_circle,
        ProbeVerdict.respondsUnknown => Icons.help,
        _ => Icons.cancel,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptertest'),
        actions: [
          IconButton(
            tooltip: 'Bericht kopieren',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: result.toReport()));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bericht kopiert.')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(_icon, color: _color(context)),
              title: Text(result.deviceName),
              subtitle: Text(result.summary),
              isThreeLine: true,
            ),
          ),
          if (result.identification != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Kennung: ${result.identification}'),
            ),
          if (result.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                result.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),

          if (result.steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Befehle', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final step in result.steps)
              Card(
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    step.answered ? Icons.south_west : Icons.block,
                    size: 20,
                    color: step.answered ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    step.command,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  subtitle: Text(
                    step.answered ? step.response : 'keine Antwort',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
          ],

          const SizedBox(height: 16),
          Text('GATT-Profil', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final service in result.services)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.uuid,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final c in service.characteristics)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${c.uuid}  [${c.properties.join(', ')}]',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (c.uuid == result.writeCharacteristic)
                              const Icon(Icons.upload, size: 16),
                            if (c.uuid == result.notifyCharacteristic)
                              const Icon(Icons.download, size: 16),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
