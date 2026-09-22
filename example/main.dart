import 'dart:async';

import 'package:custom_app_update/custom_app_update.dart';
import 'package:flutter/material.dart';

void main() => runApp(const UpdateExample());

class UpdateExample extends StatefulWidget {
  const UpdateExample({super.key});

  @override
  State<UpdateExample> createState() => _UpdateExampleState();
}

class _UpdateExampleState extends State<UpdateExample> {
  late final CustomAppUpdateController updates;

  @override
  void initState() {
    super.initState();
    updates = CustomAppUpdateController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(updates.check());
    });
  }

  @override
  void dispose() {
    updates.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: const Text('Custom app updates')),
            body: Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      useSafeArea: true,
                      builder: (_) => SingleChildScrollView(
                        child: UpdateContent(controller: updates),
                      ),
                    ),
                    child: const Text('Bottom sheet'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        child: SingleChildScrollView(
                          child: UpdateContent(controller: updates),
                        ),
                      ),
                    ),
                    child: const Text('Dialog'),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('App update')),
                          body: SafeArea(
                            child: SingleChildScrollView(
                              child: Center(
                                child: UpdateContent(controller: updates),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Full screen'),
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

/// Replace this entire widget with your own design. Only the controller API
/// matters; the update implementation does not depend on Material widgets.
class UpdateContent extends StatelessWidget {
  const UpdateContent({super.key, required this.controller});

  final CustomAppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final phase = controller.phase;
        final progressing = const {
          UpdatePhase.awaitingConsent,
          UpdatePhase.pending,
          UpdatePhase.downloading,
          UpdatePhase.installing,
        }.contains(phase);
        final message = switch (phase) {
          UpdatePhase.idle => 'Check for a new version.',
          UpdatePhase.unsupported => 'In-app downloads require Android.',
          UpdatePhase.upToDate => 'You are up to date.',
          UpdatePhase.unavailable =>
            'An in-app download is not available right now.',
          UpdatePhase.available =>
            'A new version is available. Update when you are ready.',
          UpdatePhase.awaitingConsent => 'Confirm the update in Google Play.',
          UpdatePhase.pending => 'Your download is getting ready…',
          UpdatePhase.downloading =>
            'Downloading. You can close this and keep using the app.',
          UpdatePhase.readyToInstall =>
            'Your update is ready. Restart to finish installing.',
          UpdatePhase.installing => 'Installing your update…',
          UpdatePhase.installed => 'Your update is installed.',
          UpdatePhase.canceled => 'Update canceled. You can try again later.',
          UpdatePhase.failed =>
            'The update could not finish. Please try again.',
        };
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.system_update_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'App update',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Semantics(liveRegion: true, child: Text(message)),
                if (controller.error != null &&
                    phase != UpdatePhase.failed) ...[
                  const SizedBox(height: 8),
                  const Text('Something went wrong. Please try again.'),
                ],
                if (controller.isChecking || progressing) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(value: controller.downloadProgress),
                ],
                const SizedBox(height: 24),
                if (controller.canDownload)
                  FilledButton(
                    onPressed: () => unawaited(controller.download()),
                    child: const Text('Download update'),
                  ),
                if (controller.canInstall)
                  FilledButton(
                    onPressed: () => unawaited(controller.restartAndInstall()),
                    child: const Text('Restart and install'),
                  ),
                if (!controller.isChecking &&
                    !progressing &&
                    !controller.canDownload &&
                    !controller.canInstall &&
                    phase != UpdatePhase.unsupported)
                  OutlinedButton(
                    onPressed: () => unawaited(controller.check()),
                    child: const Text('Check again'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(progressing ? 'Continue using app' : 'Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
