import 'dart:async';

import 'package:custom_app_update/custom_app_update.dart';
import 'package:flutter/material.dart';

import 'demo_update_backend.dart';

void main() => runApp(const UpdateExample());

class UpdateExample extends StatefulWidget {
  const UpdateExample({
    super.key,
    this.demoMode = const bool.fromEnvironment('UPDATE_DEMO'),
  });

  final bool demoMode;

  @override
  State<UpdateExample> createState() => _UpdateExampleState();
}

class _UpdateExampleState extends State<UpdateExample> {
  late final DemoUpdateBackend? demo;
  late final CustomAppUpdateController updates;

  @override
  void initState() {
    super.initState();
    demo = widget.demoMode ? DemoUpdateBackend() : null;
    updates = CustomAppUpdateController(backend: demo);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(updates.check());
    });
  }

  @override
  void dispose() {
    updates.dispose();
    demo?.dispose();
    super.dispose();
  }

  Widget updateContent() => UpdateContent(
        controller: updates,
        demoMode: widget.demoMode,
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Custom app update • Example')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Your update. Your UI.',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      const Text('One controller, three presentations. Close '
                          'one and open another to see the same update state.'),
                      const SizedBox(height: 20),
                      Card.filled(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(widget.demoMode
                              ? 'DEMO MODE — Simulated bytes and installation. '
                                  'No Google Play prompt or actual app update.'
                              : 'GOOGLE PLAY MODE — Requires an eligible '
                                  'Play-installed app and a newer release.'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListenableBuilder(
                        listenable: updates,
                        builder: (_, child) => Text(
                          updates.isChecking
                              ? 'Checking for updates…'
                              : 'Current state: ${updates.phase.name}',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              useSafeArea: true,
                              builder: (_) => SingleChildScrollView(
                                child: updateContent(),
                              ),
                            ),
                            child: const Text('Bottom sheet'),
                          ),
                          FilledButton.tonal(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => Dialog(
                                child: SingleChildScrollView(
                                  child: updateContent(),
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
                                      child: Center(child: updateContent()),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            child: const Text('Full screen'),
                          ),
                        ],
                      ),
                      if (demo != null) ...[
                        const SizedBox(height: 32),
                        Text('Test a scenario',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ListenableBuilder(
                          listenable: updates,
                          builder: (_, child) {
                            final busy = updates.isChecking || const {
                              UpdatePhase.awaitingConsent,
                              UpdatePhase.pending,
                              UpdatePhase.downloading,
                              UpdatePhase.installing,
                            }.contains(updates.phase);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final scenario in DemoScenario.values)
                                      ChoiceChip(
                                        label: Text(switch (scenario) {
                                          DemoScenario.success => 'Success',
                                          DemoScenario.canceled => 'Cancel',
                                          DemoScenario.downloadFailure => 'Download fails',
                                          DemoScenario.installFailure => 'Install fails',
                                        }),
                                        selected: demo!.scenario == scenario,
                                        onSelected: busy ? null : (_) {
                                          setState(() => demo!.scenario = scenario);
                                          demo!.reset();
                                          unawaited(updates.check());
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: busy ? null : () {
                                    demo!.reset();
                                    unawaited(updates.check());
                                  },
                                  icon: const Icon(Icons.replay),
                                  label: const Text('Reset demo'),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                      const Text('Example build '
                          '${String.fromEnvironment('EXAMPLE_BUILD', defaultValue: '10')}'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Replace this entire widget with your own design. Only the controller API
/// matters; the update implementation does not depend on Material widgets.
class UpdateContent extends StatelessWidget {
  const UpdateContent({super.key, required this.controller, this.demoMode = false});

  final CustomAppUpdateController controller;
  final bool demoMode;

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
          UpdatePhase.awaitingConsent => demoMode
              ? 'Starting simulated download…'
              : 'Confirm the update in Google Play.',
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
                  if (controller.downloadProgress != null) ...[
                    const SizedBox(height: 8),
                    Text('${(controller.downloadProgress! * 100).round()}% downloaded'),
                  ],
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
                    child: Text(demoMode ? 'Finish demo installation' : 'Restart and install'),
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
