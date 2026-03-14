import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class SystemMonitorDialog extends StatefulWidget {
  const SystemMonitorDialog({super.key});

  @override
  State<SystemMonitorDialog> createState() => _SystemMonitorDialogState();
}

class _SystemMonitorDialogState extends State<SystemMonitorDialog> {
  Timer? _timer;
  List<Map<String, String>> _processes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchStats());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    if (!Platform.isLinux) return; // Feature specifically built for Linux

    try {
      // Get top 30 processes sorted by CPU usage
      final result = await Process.run('ps', ['aux', '--sort=-%cpu']);
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).trim().split('\n');
        if (lines.isEmpty) return;
        
        // Skip header
        final parsed = lines.skip(1).take(30).map((line) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 11) {
            return {
              'USER': parts[0],
              'PID': parts[1],
              'CPU': parts[2],
              'MEM': parts[3],
              'COMMAND': parts.sublist(10).join(' '),
            };
          }
          return <String, String>{};
        }).where((p) => p.isNotEmpty).toList();

        if (mounted) {
          setState(() {
            _processes = parsed;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching stats: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'System Monitor (htop-like)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const Text('Refreshing every 2s...', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _processes.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Header
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.grey.withOpacity(0.2),
                        child: const Row(
                          children: [
                            Expanded(flex: 1, child: Text('PID', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('USER', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('%CPU', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('%MEM', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 4, child: Text('COMMAND', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                      );
                    }
                    
                    final p = _processes[index - 1];
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Text(p['PID'] ?? '')),
                          Expanded(flex: 1, child: Text(p['USER'] ?? '')),
                          Expanded(
                            flex: 1, 
                            child: Text(
                              p['CPU'] ?? '', 
                              style: TextStyle(
                                color: (double.tryParse(p['CPU'] ?? '0') ?? 0) > 10 ? Colors.red : null,
                                fontWeight: FontWeight.bold
                              )
                            )
                          ),
                          Expanded(flex: 1, child: Text(p['MEM'] ?? '')),
                          Expanded(flex: 4, child: Text(p['COMMAND'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
