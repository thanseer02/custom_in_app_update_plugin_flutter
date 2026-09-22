import 'package:flutter/material.dart';
import 'package:my_in_app_update/my_in_app_update.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: InAppUpdateDemoPage(),
  ));
}

class InAppUpdateDemoPage extends StatefulWidget {
  const InAppUpdateDemoPage({super.key});

  @override
  State<InAppUpdateDemoPage> createState() => _InAppUpdateDemoPageState();
}

class _InAppUpdateDemoPageState extends State<InAppUpdateDemoPage> {
  final MyInAppUpdate _updater = MyInAppUpdate();
  UpdateInfo? _latestUpdateInfo;
  String _statusMessage = 'Idle. Tap a button below to test.';
  bool _isLoading = false;

  void _setStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  // ---------------------------------------------------------------------------
  // USAGE 1: Default UI (Out-of-the-box Sane Defaults)
  // ---------------------------------------------------------------------------
  Future<void> _checkWithDefaultUI() async {
    setState(() => _isLoading = true);
    _setStatus('Checking for updates (Default UI)...');

    try {
      final info = await _updater.checkForUpdate(
        context: context,
        onProgress: (progress) {
          _setStatus('Downloading: ${progress.downloadProgress * 100}%');
        },
        onError: (err) {
          _setStatus('Error during update: $err');
        },
      );

      setState(() => _latestUpdateInfo = info);
      _setStatus(
        info.isUpdateAvailable
            ? 'Update available (v${info.versionCode}) - Dialog presented.'
            : 'App is up to date (No update available).',
      );
    } catch (e) {
      _setStatus('Check failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // USAGE 2: Custom AlertDialog UI
  // ---------------------------------------------------------------------------
  Future<void> _checkWithCustomDialogUI() async {
    setState(() => _isLoading = true);
    _setStatus('Checking for updates (Custom Dialog UI)...');

    try {
      final info = await _updater.checkForUpdate(
        context: context,
        uiBuilder: (dialogContext, updateInfo, onUpdate, onDismiss) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.system_security_update,
              size: 40,
              color: Colors.deepPurple,
            ),
            title: Text(
              'Exciting New Version ${updateInfo.versionCode}!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priority Level: ${updateInfo.priority}/5 '
                  '${updateInfo.immediateAllowed ? "(Mandatory)" : "(Optional)"}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('What\'s new in this release:'),
                const SizedBox(height: 6),
                const Text('• Enhanced stability & bug fixes'),
                const Text('• Polished animations & UI tweaks'),
                const Text('• Performance optimizations'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: onDismiss,
                child: const Text('Not Now'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                icon: const Icon(Icons.download),
                label: const Text('Upgrade'),
                onPressed: onUpdate,
              ),
            ],
          );
        },
      );

      setState(() => _latestUpdateInfo = info);
      _setStatus(
        info.isUpdateAvailable
            ? 'Custom dialog displayed for v${info.versionCode}.'
            : 'No update available.',
      );
    } catch (e) {
      _setStatus('Check failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // USAGE 3: Custom Bottom Sheet UI with Live Download Stream
  // ---------------------------------------------------------------------------
  Future<void> _checkWithBottomSheetUI() async {
    setState(() => _isLoading = true);
    _setStatus('Checking for updates (Custom Bottom Sheet)...');

    try {
      final info = await _updater.checkForUpdate();
      setState(() => _latestUpdateInfo = info);

      if (!mounted) return;

      if (!info.isUpdateAvailable) {
        _setStatus('App is already up to date.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No updates available at this time.')),
        );
        return;
      }

      // Present custom bottom sheet
      _showCustomUpdateBottomSheet(info);
      _setStatus('Bottom sheet presented for v${info.versionCode}.');
    } catch (e) {
      _setStatus('Check failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCustomUpdateBottomSheet(UpdateInfo info) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StreamBuilder<DownloadProgress>(
          stream: _updater.downloadProgressStream,
          builder: (context, snapshot) {
            final progress = snapshot.data;
            final isDownloaded = progress?.isDownloaded ?? false;
            final isDownloading = progress?.isDownloading ?? false;

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.rocket_launch, color: Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Version ${info.versionCode} Ready',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Flexible In-App Update Available',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isDownloading) ...[
                    Text(
                      'Downloading update: ${(progress?.percentage ?? 0).toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress?.progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 16),
                  ] else if (isDownloaded) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Download complete! Ready to install.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Text(
                      'Download in background while you continue using the app.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(bottomSheetContext).pop(),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isDownloaded
                            ? FilledButton(
                                onPressed: () {
                                  Navigator.of(bottomSheetContext).pop();
                                  _updater.completeFlexibleUpdate();
                                },
                                child: const Text('Restart & Apply'),
                              )
                            : FilledButton(
                                onPressed: () {
                                  if (info.immediateAllowed) {
                                    Navigator.of(bottomSheetContext).pop();
                                    _updater.startImmediateUpdate();
                                  } else {
                                    _updater.startFlexibleUpdate();
                                  }
                                },
                                child: const Text('Start Download'),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In-App Update Showcase'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status & Inspector',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: TextStyle(color: Colors.grey.shade800),
                    ),
                    if (_latestUpdateInfo != null) ...[
                      const Divider(height: 24),
                      Text('• Version Code: ${_latestUpdateInfo!.versionCode}'),
                      Text('• Availability: ${_latestUpdateInfo!.availability.name}'),
                      Text('• Priority: ${_latestUpdateInfo!.priority}'),
                      Text('• Immediate Allowed: ${_latestUpdateInfo!.immediateAllowed}'),
                      Text('• Flexible Allowed: ${_latestUpdateInfo!.flexibleAllowed}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'UI Integration Patterns',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Pattern 1: Default Sane UI
            _buildPatternTile(
              title: '1. Default Built-in UI',
              subtitle: 'updater.checkForUpdate(context: context) with zero custom code.',
              icon: Icons.auto_awesome,
              color: Colors.blue,
              onTap: _isLoading ? null : _checkWithDefaultUI,
            ),
            const SizedBox(height: 12),

            // Pattern 2: Custom AlertDialog
            _buildPatternTile(
              title: '2. Custom AlertDialog UI',
              subtitle: 'Supplies custom uiBuilder with branded layout & changelog.',
              icon: Icons.dashboard_customize,
              color: Colors.deepPurple,
              onTap: _isLoading ? null : _checkWithCustomDialogUI,
            ),
            const SizedBox(height: 12),

            // Pattern 3: Custom Bottom Sheet
            _buildPatternTile(
              title: '3. Custom Bottom Sheet & Live Stream',
              subtitle: 'Renders bottom sheet reacting live to downloadProgressStream.',
              icon: Icons.vertical_align_bottom,
              color: Colors.teal,
              onTap: _isLoading ? null : _checkWithBottomSheetUI,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(35),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
