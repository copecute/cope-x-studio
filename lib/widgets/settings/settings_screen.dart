import 'dart:async';

import 'package:cope_x_studio/l10n/app_locale.dart';
import 'package:cope_x_studio/l10n/model_l10n.dart';
import 'package:cope_x_studio/models/app_theme_mode.dart';
import 'package:cope_x_studio/models/root_access_mode.dart';
import 'package:cope_x_studio/models/text_encoding.dart';
import 'package:cope_x_studio/providers/locale_provider.dart';
import 'package:cope_x_studio/providers/security_provider.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:cope_x_studio/services/platform_bridge.dart';
import 'package:flutter/material.dart';
import 'package:cope_x_studio/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  RootAccessMode? _checkingRootMode;

  Future<void> _showPasswordSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: VsCodeColors.sidebar,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _AppLockPasswordSheet(),
    );
    if (!mounted || result == null) return;

    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result == 'changed' ? l10n.passwordChanged : l10n.passwordSet),
      ),
    );
    await context.read<WorkspaceProvider>().restartWebServerIfRunning();
  }

  Future<void> _onLockToggle(bool enabled) async {
    final security = context.read<SecurityProvider>();

    if (enabled) {
      if (!security.hasPassword) {
        await _showPasswordSheet();
        return;
      }
      try {
        await security.setLockEnabled(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }

    try {
      await security.setLockEnabled(false);
      if (!mounted) return;
      await context.read<WorkspaceProvider>().restartWebServerIfRunning();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _appLockSubtitle(SecurityProvider security, AppLocalizations l10n) {
    if (security.isLockEnabled) {
      return l10n.appLockSubtitleActive;
    }
    if (security.hasPassword) {
      return l10n.appLockSubtitleInactive;
    }
    return l10n.appLockSubtitleSetup;
  }

  Future<void> _onRootAccessModeChanged(RootAccessMode mode) async {
    if (_checkingRootMode != null) return;
    final workspace = context.read<WorkspaceProvider>();
    if (workspace.rootAccessMode == mode) return;

    if (mode.usesSuperuser) {
      setState(() => _checkingRootMode = mode);
    }

    final error = await workspace.setRootAccessMode(mode);

    if (!mounted) return;
    setState(() => _checkingRootMode = null);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _onThemeModeChanged(AppThemeMode value) async {
    final workspace = context.read<WorkspaceProvider>();
    if (workspace.appThemeMode == value) return;

    await workspace.setAppThemeMode(value);

    if (!mounted) return;

    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: VsCodeColors.sidebar,
          title: Text(l10n.restartAppTitle),
          content: Text(l10n.restartAppBody),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                PlatformBridge().restartApp();
              },
              child: Text(l10n.restartNow),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEncodingSheet() async {
    final workspace = context.read<WorkspaceProvider>();
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: VsCodeColors.sidebar,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.textEncodingSheetTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.textEncodingSheetSubtitle,
                style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.35),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: TextEncoding.values.length,
                itemBuilder: (_, index) {
                  final encoding = TextEncoding.values[index];
                  return RadioListTile<TextEncoding>(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(encoding.label),
                    value: encoding,
                    groupValue: workspace.textEncoding,
                    onChanged: (value) {
                      if (value == null) return;
                      workspace.setTextEncoding(value);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final security = context.watch<SecurityProvider>();
    final workspace = context.watch<WorkspaceProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: VsCodeColors.editor,
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: VsCodeColors.tabBar,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.language,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RadioListTile<Locale>(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.languageEnglish),
            value: AppLocale.english,
            groupValue: localeProvider.locale,
            onChanged: (_) => localeProvider.setLocale(AppLocale.english),
          ),
          RadioListTile<Locale>(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.languageVietnamese),
            value: AppLocale.vietnamese,
            groupValue: localeProvider.locale,
            onChanged: (_) => localeProvider.setLocale(AppLocale.vietnamese),
          ),
          Divider(height: 40, color: VsCodeColors.border),
          Text(
            l10n.sectionAppLock,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _AppLockTile(
            title: l10n.appLockTitle,
            enabled: security.isLockEnabled,
            subtitle: _appLockSubtitle(security, l10n),
            onTap: _showPasswordSheet,
            onToggle: _onLockToggle,
          ),
          if (!security.canUseBiometric)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.biometricNotSupported,
                style: TextStyle(color: VsCodeColors.foregroundDim),
              ),
            )
          else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.biometricUnlockTitle),
              subtitle: Text(
                security.hasPassword
                    ? l10n.biometricUnlockSubtitle
                    : l10n.biometricNeedsPassword,
              ),
              value: security.isBiometricEnabled,
              onChanged: security.hasPassword
                  ? (v) async {
                      try {
                        await security.setBiometricEnabled(v);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    }
                  : null,
            ),
          Divider(height: 40, color: VsCodeColors.border),
          Text(
            l10n.sectionRootAccess,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...RootAccessMode.values.map(
            (mode) {
              final checking = _checkingRootMode == mode;
              return RadioListTile<RootAccessMode>(
                contentPadding: EdgeInsets.zero,
                title: Text(mode.localizedLabel(l10n)),
                subtitle: checking
                    ? Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            l10n.checkingSuperuser,
                            style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.35),
                          ),
                        ],
                      )
                    : Text(
                        mode.localizedDescription(l10n),
                        style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.35),
                      ),
                value: mode,
                groupValue: workspace.rootAccessMode,
                onChanged: _checkingRootMode != null
                    ? null
                    : (value) {
                        if (value != null) unawaited(_onRootAccessModeChanged(value));
                      },
              );
            },
          ),
          Divider(height: 40, color: VsCodeColors.border),
          Text(
            l10n.sectionDisplay,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.showHiddenFiles),
            subtitle: Text(l10n.showHiddenFilesSubtitle),
            value: workspace.showHidden,
            onChanged: (v) {
              workspace.setShowHidden(v);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.openApkAsZip),
            subtitle: Text(l10n.openApkAsZipSubtitle),
            value: workspace.openApkAsZip,
            onChanged: workspace.setOpenApkAsZip,
          ),
          Divider(height: 40, color: VsCodeColors.border),
          Text(
            l10n.sectionTextEditor,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.textEncoding),
            subtitle: Text(workspace.textEncoding.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showEncodingSheet,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.editorFontSize(workspace.editorFontSize.toInt())),
            subtitle: Text(l10n.editorFontSizeSubtitle),
            trailing: SizedBox(
              width: 140,
              child: Slider(
                value: workspace.editorFontSize,
                min: 10,
                max: 28,
                divisions: 18,
                label: workspace.editorFontSize.toInt().toString(),
                onChanged: workspace.setEditorFontSize,
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.editorLineNumbers),
            subtitle: Text(l10n.editorLineNumbersSubtitle),
            value: workspace.editorShowLineNumbers,
            onChanged: workspace.setEditorShowLineNumbers,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.editorWordWrap),
            subtitle: Text(l10n.editorWordWrapSubtitle),
            value: workspace.editorWordWrap,
            onChanged: workspace.setEditorWordWrap,
          ),
          Divider(height: 40, color: VsCodeColors.border),
          Text(
            l10n.sectionUiAndActions,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.themeModeTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          ...AppThemeMode.values.map(
            (mode) => RadioListTile<AppThemeMode>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(mode.localizedLabel(l10n)),
              value: mode,
              groupValue: workspace.appThemeMode,
              onChanged: (value) {
                if (value != null) unawaited(_onThemeModeChanged(value));
              },
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.uiScale((workspace.uiScale * 100).round())),
            subtitle: Slider(
              value: workspace.uiScale,
              min: 0.8,
              max: 1.4,
              divisions: 12,
              label: '${(workspace.uiScale * 100).round()}%',
              onChanged: workspace.setUiScale,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.fullscreen),
            subtitle: Text(l10n.fullscreenSubtitle),
            value: workspace.fullscreenEnabled,
            onChanged: workspace.setFullscreenEnabled,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.hapticFeedback),
            subtitle: Text(l10n.hapticFeedbackSubtitle),
            value: workspace.hapticEnabled,
            onChanged: workspace.setHapticEnabled,
          ),
          Divider(height: 40, color: VsCodeColors.border),
          Text(
            l10n.sectionApplication,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.rememberLastPath),
            subtitle: Text(l10n.rememberLastPathSubtitle),
            value: workspace.rememberLastPath,
            onChanged: workspace.setRememberLastPath,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.requireExitConfirmation),
            subtitle: Text(l10n.requireExitConfirmationSubtitle),
            value: workspace.requireExitConfirmation,
            onChanged: workspace.setRequireExitConfirmation,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.useTrash),
            subtitle: Text(l10n.useTrashSubtitle),
            value: workspace.useTrash,
            onChanged: workspace.setUseTrash,
          ),
        ],
      ),
    );
  }
}

class _AppLockTile extends StatelessWidget {
  const _AppLockTile({
    required this.title,
    required this.enabled,
    required this.subtitle,
    required this.onTap,
    required this.onToggle,
  });

  final String title;
  final bool enabled;
  final String subtitle;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: VsCodeColors.foregroundDim, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 1,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: VsCodeColors.border.withValues(alpha: 0.6),
        ),
        Switch(value: enabled, onChanged: onToggle),
      ],
    );
  }
}

class _AppLockPasswordSheet extends StatefulWidget {
  const _AppLockPasswordSheet();

  @override
  State<_AppLockPasswordSheet> createState() => _AppLockPasswordSheetState();
}

class _AppLockPasswordSheetState extends State<_AppLockPasswordSheet> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  String? _error;
  bool _saving = false;
  late final bool _wasChanging;

  @override
  void initState() {
    super.initState();
    _wasChanging = context.read<SecurityProvider>().hasPassword;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final password = _ctrl.text;
    if (password.isEmpty) {
      setState(() => _error = context.l10n.passwordEmptyError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final security = context.read<SecurityProvider>();
    try {
      if (_wasChanging) {
        await security.updatePassword(password);
      } else {
        await security.setPassword(password);
      }
      if (!mounted) return;
      Navigator.pop(context, _wasChanging ? 'changed' : 'set');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _wasChanging ? l10n.changePassword : l10n.setPassword,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.passwordHint,
            style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            obscureText: _obscure,
            autofocus: true,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: l10n.passwordLabel,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_wasChanging ? l10n.savePassword : l10n.setPassword),
          ),
        ],
      ),
    );
  }
}
