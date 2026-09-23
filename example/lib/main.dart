import 'package:flutter/material.dart';
import 'package:custom_in_app_update/custom_in_app_update.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'custom_in_app_update example',
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      CustomInAppUpdate.resumeStalledUpdateIfNeeded();
    }
  }

  // 1. Simplest usage: no uiBuilder, falls back to the built-in dialog.
  Future<void> _checkWithDefaultUi() {
    return CustomInAppUpdate.checkForUpdate(
      context: context,
      iosBundleId: 'com.example.app',
      iosInstalledVersion: '1.0.0', // normally from package_info_plus
    );
  }

  // 2. Custom bottom sheet UI.
  Future<void> _checkWithBottomSheet() {
    return CustomInAppUpdate.checkForUpdate(
      context: context,
      iosBundleId: 'com.example.app',
      iosInstalledVersion: '1.0.0',
      uiBuilder: (context, info, onUpdate, onDismiss) {
        showModalBottomSheet<void>(
          context: context,
          isDismissible: !info.immediateAllowed,
          builder: (sheetContext) => _UpdateBottomSheet(
            info: info,
            onUpdate: () {
              Navigator.of(sheetContext).pop();
              onUpdate();
            },
            onDismiss: () {
              Navigator.of(sheetContext).pop();
              onDismiss();
            },
          ),
        );
        return null;
      },
    );
  }

  // 3. Custom top banner UI (no dialog/sheet at all — an in-page widget).
  UpdateInfo? _bannerInfo;
  VoidCallback? _bannerOnUpdate;

  Future<void> _checkWithBanner() {
    return CustomInAppUpdate.checkForUpdate(
      context: context,
      iosBundleId: 'com.example.app',
      iosInstalledVersion: '1.0.0',
      uiBuilder: (context, info, onUpdate, onDismiss) {
        setState(() {
          _bannerInfo = info;
          _bannerOnUpdate = onUpdate;
        });
        return null; // nothing pushed via Navigator — handled by our own state
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('custom_in_app_update example')),
      body: Column(
        children: [
          if (_bannerInfo != null && _bannerInfo!.updateAvailable)
            MaterialBanner(
              content: Text('Update ${_bannerInfo!.availableVersion ?? ''} available'),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _bannerInfo = null),
                  child: const Text('Dismiss'),
                ),
                FilledButton(
                  onPressed: () {
                    _bannerOnUpdate?.call();
                    setState(() => _bannerInfo = null);
                  },
                  child: const Text('Update'),
                ),
              ],
            ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _checkWithDefaultUi,
                    child: const Text('Check for update — default dialog'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _checkWithBottomSheet,
                    child: const Text('Check for update — custom bottom sheet'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _checkWithBanner,
                    child: const Text('Check for update — custom banner'),
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

/// Example of a fully custom bottom sheet, styled however the app wants.
class _UpdateBottomSheet extends StatelessWidget {
  const _UpdateBottomSheet({
    required this.info,
    required this.onUpdate,
    required this.onDismiss,
  });

  final UpdateInfo info;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New update available', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Version ${info.availableVersion ?? ''} is ready to install.'),
            const SizedBox(height: 20),
            StreamBuilder<UpdateInfo>(
              stream: CustomInAppUpdate.downloadProgressStream,
              builder: (context, snapshot) {
                final progress = snapshot.data?.downloadProgress;
                if (progress == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(value: progress / 100),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!info.immediateAllowed)
                  TextButton(onPressed: onDismiss, child: const Text('Not now')),
                const SizedBox(width: 8),
                FilledButton(onPressed: onUpdate, child: const Text('Update now')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
