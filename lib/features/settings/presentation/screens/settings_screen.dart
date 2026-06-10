import 'package:flutter/material.dart';

import '../../../../features/history/data/repositories/history_repository.dart';
import '../../../../services/database/app_database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final HistoryRepository _historyRepository;

  bool _isClearing = false;

  @override
  void initState() {
    super.initState();

    _historyRepository = HistoryRepository(
      database: AppDatabase.instance,
    );
  }

  Future<void> _clearAllHistory() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear all history?'),
          content: const Text(
            'All saved recycling records will be deleted from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    setState(() => _isClearing = true);

    try {
      await _historyRepository.clearAllHistory();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All history has been cleared'),
        ),
      );
    } catch (error) {
      debugPrint('Failed to clear history: $error');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear history'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF3),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFF7FAF3),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SettingsSection(
              title: 'Application',
              children: [
                _SettingsTile(
                  icon: Icons.wifi_off_rounded,
                  title: 'Offline Mode',
                  subtitle: 'This app stores all data locally on this device.',
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SettingsSection(
              title: 'Data',
              children: [
                _SettingsTile(
                  icon: Icons.delete_sweep_rounded,
                  title: 'Clear All History',
                  subtitle: 'Remove all saved recycling records.',
                  trailing: _isClearing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _clearAllHistory,
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: Colors.redAccent,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SettingsSection(
              title: 'About',
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Recycle AI',
                  subtitle:
                      'AI-based recyclable material classification and price estimation app.',
                ),
                _SettingsTile(
                  icon: Icons.storage_rounded,
                  title: 'Storage',
                  subtitle: 'SQLite local database, no cloud connection.',
                ),
                _SettingsTile(
                  icon: Icons.code_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE4ECE0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1F4F28),
                    ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
      ),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF1F4F28),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF1E211D),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF5E665B),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
    );
  }
}