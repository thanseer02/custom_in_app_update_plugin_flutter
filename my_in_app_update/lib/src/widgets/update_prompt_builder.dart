import 'package:flutter/material.dart';
import '../../my_in_app_update.dart';

/// A declarative widget that checks for updates on mount and builds
/// custom UI (e.g. banners, inline cards, bottom sheets) via [builder].
class UpdatePromptBuilder extends StatefulWidget {
  /// The plugin instance to use (defaults to a new [MyInAppUpdate] instance).
  final MyInAppUpdate? plugin;

  /// Builder invoked when an update is available (defaults to [defaultUiBuilder]).
  final UpdateUIBuilder? builder;

  /// Optional builder invoked while checking for updates.
  final WidgetBuilder? loadingBuilder;

  /// Optional builder invoked when no update is available.
  final WidgetBuilder? noUpdateBuilder;

  /// Optional builder invoked when an error occurs.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Callback when update download progress changes (flexible updates).
  final void Function(UpdateInfo info)? onProgress;

  /// Whether to auto-check on widget initialization.
  final bool autoCheck;

  const UpdatePromptBuilder({
    super.key,
    this.builder,
    this.plugin,
    this.loadingBuilder,
    this.noUpdateBuilder,
    this.errorBuilder,
    this.onProgress,
    this.autoCheck = true,
  });

  @override
  State<UpdatePromptBuilder> createState() => _UpdatePromptBuilderState();
}

class _UpdatePromptBuilderState extends State<UpdatePromptBuilder> {
  late final MyInAppUpdate _plugin;
  UpdateInfo? _updateInfo;
  bool _isLoading = false;
  Object? _error;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _plugin = widget.plugin ?? MyInAppUpdate();
    if (widget.autoCheck) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _isDismissed = false;
    });

    try {
      final info = await _plugin.checkForUpdate();
      if (mounted) {
        setState(() {
          _updateInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  void _onUpdate() async {
    final info = _updateInfo;
    if (info == null) return;

    if (info.immediateAllowed) {
      await _plugin.startImmediateUpdate();
    } else if (info.flexibleAllowed) {
      await _plugin.startFlexibleUpdate(
        onProgress: (updated) {
          if (mounted) {
            setState(() {
              _updateInfo = updated;
            });
          }
          widget.onProgress?.call(updated);
        },
      );
    }
  }

  void _onDismiss() {
    if (mounted) {
      setState(() {
        _isDismissed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
    }

    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ?? const SizedBox.shrink();
    }

    final info = _updateInfo;
    if (!_isDismissed && info != null && info.isUpdateAvailable) {
      final effectiveBuilder = widget.builder ?? defaultUiBuilder;
      return effectiveBuilder(context, info, _onUpdate, _onDismiss);
    }

    return widget.noUpdateBuilder?.call(context) ?? const SizedBox.shrink();
  }
}
