import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/obd_provider.dart';
import 'widgets/sparkline.dart';

class LivePage extends StatelessWidget {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final obd = context.watch<ObdProvider>();
    final pids = obd.activePids;

    return Scaffold(
      appBar: AppBar(title: const Text('Live-Daten')),
      body: pids.isEmpty
          ? const Center(child: Text('Keine unterstützten PIDs gefunden.'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 128,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: pids.length,
              itemBuilder: (context, index) {
                final pid = pids[index];
                final value = obd.values[pid.request];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pid.label,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              value == null
                                  ? '--'
                                  : value.toStringAsFixed(pid.decimals),
                              style:
                                  Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              pid.unit,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Sparkline(
                          values: obd.history[pid.request] ?? const <double>[],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
