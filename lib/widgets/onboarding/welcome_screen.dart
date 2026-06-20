import 'dart:io';

import 'package:cope_x_studio/l10n/app_locale.dart';
import 'package:cope_x_studio/l10n/model_l10n.dart';
import 'package:cope_x_studio/models/app_theme_mode.dart';
import 'package:cope_x_studio/providers/locale_provider.dart';
import 'package:cope_x_studio/providers/onboarding_provider.dart';
import 'package:cope_x_studio/providers/workspace_provider.dart';
import 'package:cope_x_studio/services/permission_service.dart';
import 'package:cope_x_studio/theme/vscode_theme.dart';
import 'package:cope_x_studio/utils/l10n_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.initialPage = 0});

  final int initialPage;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with WidgetsBindingObserver {
  static const _pageCount = 3;
  static const _logoSize = 96.0;

  final _permissionService = PermissionService();

  int _page = 0;
  bool _requestingStorage = false;
  bool _requestingNotification = false;
  bool _notificationGranted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _page = widget.initialPage.clamp(0, _pageCount - 1);
    _refreshNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<WorkspaceProvider>().recheckPermissions();
      _refreshNotificationPermission();
    }
  }

  Future<void> _refreshNotificationPermission() async {
    final granted = await _permissionService.hasNotificationPermission();
    if (mounted) setState(() => _notificationGranted = granted);
  }

  bool get _needsStoragePermission {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  bool get _needsNotificationPermission {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  bool _canGoNext(WorkspaceProvider workspace) {
    if (_page != 1) return true;
    if (!_needsStoragePermission) return true;
    return workspace.storageGranted;
  }

  Future<void> _finish() async {
    final onboarding = context.read<OnboardingProvider>();
    final workspace = context.read<WorkspaceProvider>();
    await onboarding.complete();
    workspace.onOnboardingComplete();
  }

  void _goNext(WorkspaceProvider workspace) {
    if (!_canGoNext(workspace)) return;
    if (_page < _pageCount - 1) {
      setState(() => _page++);
    }
  }

  void _goBack() {
    if (_page > 0) setState(() => _page--);
  }

  Future<void> _grantStorage() async {
    setState(() => _requestingStorage = true);
    try {
      await context.read<WorkspaceProvider>().requestManageExternalStorage();
    } finally {
      if (mounted) setState(() => _requestingStorage = false);
    }
  }

  Future<void> _grantNotification() async {
    setState(() => _requestingNotification = true);
    try {
      await _permissionService.requestNotificationPermission();
      await _refreshNotificationPermission();
    } finally {
      if (mounted) setState(() => _requestingNotification = false);
    }
  }

  String _logoAsset(Brightness brightness) {
    return brightness == Brightness.dark
        ? 'assets/images/logo-light.png'
        : 'assets/images/logo-dark.png';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final workspace = context.watch<WorkspaceProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final brightness = Theme.of(context).brightness;
    final logo = _logoAsset(brightness);
    final canGoNext = _canGoNext(workspace);
    final permissionsOnly = context.watch<OnboardingProvider>().permissionsOnly;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeHeader(page: _page, total: _pageCount),
            Expanded(
              child: IndexedStack(
                index: _page,
                sizing: StackFit.expand,
                children: [
                  _IntroPage(
                    logoAsset: logo,
                    localeProvider: localeProvider,
                    themeMode: workspace.appThemeMode,
                    onThemeChanged: workspace.setAppThemeMode,
                  ),
                  _PermissionsPage(
                    needsStorage: _needsStoragePermission,
                    storageGranted: workspace.storageGranted,
                    requestingStorage: _requestingStorage,
                    onGrantStorage: _grantStorage,
                    needsNotification: _needsNotificationPermission,
                    notificationGranted: _notificationGranted,
                    requestingNotification: _requestingNotification,
                    onGrantNotification: _grantNotification,
                  ),
                  _DonePage(logoAsset: logo),
                ],
              ),
            ),
            if (_page == 1 && !canGoNext)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  l10n.welcomeStorageRequiredHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: VsCodeColors.error, fontSize: 13),
                ),
              ),
            _WelcomeFooter(
              showBack: _page > 0 && !(_page == 1 && permissionsOnly),
              primaryLabel: _page == _pageCount - 1 ? l10n.welcomeGetStarted : l10n.welcomeNext,
              onBack: _goBack,
              onPrimary: _page == _pageCount - 1 ? _finish : () => _goNext(workspace),
              primaryEnabled: _page != 1 || canGoNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            l10n.welcomeStep(page + 1, total),
            style: TextStyle(
              color: VsCodeColors.foregroundDim,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(total, (i) {
              final active = i == page;
              final done = i < page;
              return Container(
                width: active ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: active || done
                      ? VsCodeColors.accent
                      : VsCodeColors.foregroundDim.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WelcomeFooter extends StatelessWidget {
  const _WelcomeFooter({
    required this.showBack,
    required this.primaryLabel,
    required this.onBack,
    required this.onPrimary,
    required this.primaryEnabled,
  });

  final bool showBack;
  final String primaryLabel;
  final VoidCallback onBack;
  final VoidCallback onPrimary;
  final bool primaryEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: showBack
                ? TextButton(onPressed: onBack, child: Text(context.l10n.welcomeBack))
                : null,
          ),
          const Spacer(),
          FilledButton(
            onPressed: primaryEnabled ? onPrimary : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(120, 44),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Text(primaryLabel),
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: VsCodeColors.hover,
        shape: BoxShape.circle,
        border: Border.all(color: VsCodeColors.border),
        boxShadow: [
          BoxShadow(
            color: VsCodeColors.accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(asset, width: _WelcomeScreenState._logoSize, height: _WelcomeScreenState._logoSize),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VsCodeColors.hover,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VsCodeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.logoAsset,
    required this.localeProvider,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final String logoAsset;
  final LocaleProvider localeProvider;
  final AppThemeMode themeMode;
  final ValueChanged<AppThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const SizedBox(height: 8),
        Center(child: _LogoBadge(asset: logoAsset)),
        const SizedBox(height: 28),
        Text(
          l10n.welcomeTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.welcomeSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.5, fontSize: 15),
        ),
        const SizedBox(height: 32),
        _SectionCard(
          title: l10n.welcomeLanguage,
          child: Row(
            children: [
              Expanded(
                child: _OptionTile(
                  label: l10n.languageEnglish,
                  selected: localeProvider.isSelected(AppLocale.english),
                  onTap: () => localeProvider.setLocale(AppLocale.english),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OptionTile(
                  label: l10n.languageVietnamese,
                  selected: localeProvider.isSelected(AppLocale.vietnamese),
                  onTap: () => localeProvider.setLocale(AppLocale.vietnamese),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: l10n.welcomeTheme,
          child: Column(
            children: AppThemeMode.values.map((mode) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionTile(
                  label: mode.localizedLabel(l10n),
                  icon: switch (mode) {
                    AppThemeMode.dark => Icons.dark_mode_outlined,
                    AppThemeMode.light => Icons.light_mode_outlined,
                    AppThemeMode.system => Icons.brightness_auto_outlined,
                  },
                  selected: themeMode == mode,
                  onTap: () => onThemeChanged(mode),
                  expanded: true,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({
    required this.needsStorage,
    required this.storageGranted,
    required this.requestingStorage,
    required this.onGrantStorage,
    required this.needsNotification,
    required this.notificationGranted,
    required this.requestingNotification,
    required this.onGrantNotification,
  });

  final bool needsStorage;
  final bool storageGranted;
  final bool requestingStorage;
  final VoidCallback onGrantStorage;
  final bool needsNotification;
  final bool notificationGranted;
  final bool requestingNotification;
  final VoidCallback onGrantNotification;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasAnyPermission = needsStorage || needsNotification;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const SizedBox(height: 12),
        Text(
          l10n.welcomePermissionsTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          hasAnyPermission ? l10n.welcomePermissionsSubtitle : l10n.welcomePermissionNotNeeded,
          textAlign: TextAlign.center,
          style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.5, fontSize: 15),
        ),
        const SizedBox(height: 28),
        if (needsStorage)
          _PermissionTile(
            icon: Icons.sd_storage_outlined,
            title: l10n.welcomePermissionTitle,
            body: l10n.welcomePermissionBody,
            granted: storageGranted,
            requesting: requestingStorage,
            grantLabel: l10n.welcomeGrantPermission,
            grantedLabel: l10n.welcomePermissionGranted,
            onGrant: onGrantStorage,
            required: true,
          ),
        if (needsStorage && needsNotification) const SizedBox(height: 12),
        if (needsNotification)
          _PermissionTile(
            icon: Icons.notifications_outlined,
            title: l10n.welcomeNotificationTitle,
            body: l10n.welcomeNotificationBody,
            granted: notificationGranted,
            requesting: requestingNotification,
            grantLabel: l10n.welcomeGrantNotification,
            grantedLabel: l10n.welcomeNotificationGranted,
            onGrant: onGrantNotification,
          ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.granted,
    required this.requesting,
    required this.grantLabel,
    required this.grantedLabel,
    required this.onGrant,
    this.required = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool granted;
  final bool requesting;
  final String grantLabel;
  final String grantedLabel;
  final VoidCallback onGrant;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VsCodeColors.hover,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted ? VsCodeColors.success.withValues(alpha: 0.5) : VsCodeColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: granted ? VsCodeColors.success : VsCodeColors.accent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                        if (required)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: VsCodeColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '*',
                              style: TextStyle(color: VsCodeColors.accent, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(body, style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.45, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (granted)
            Row(
              children: [
                Icon(Icons.check_circle, color: VsCodeColors.success, size: 18),
                const SizedBox(width: 8),
                Text(grantedLabel, style: TextStyle(color: VsCodeColors.success, fontWeight: FontWeight.w600)),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: requesting ? null : onGrant,
                child: requesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(grantLabel),
              ),
            ),
        ],
      ),
    );
  }
}

class _DonePage extends StatelessWidget {
  const _DonePage({required this.logoAsset});

  final String logoAsset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LogoBadge(asset: logoAsset),
          const SizedBox(height: 32),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: VsCodeColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 36, color: VsCodeColors.success),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.welcomeDoneTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.welcomeDoneBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: VsCodeColors.foregroundDim, height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final accent = VsCodeColors.accent;
    final child = Material(
      color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: expanded ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? accent : VsCodeColors.border),
          ),
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: selected ? accent : VsCodeColors.foregroundDim),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: expanded ? TextAlign.start : TextAlign.center,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? accent : VsCodeColors.foreground,
                  ),
                ),
              ),
              if (expanded && selected) ...[
                const Spacer(),
                Icon(Icons.check, size: 18, color: accent),
              ],
            ],
          ),
        ),
      ),
    );

    return expanded ? child : child;
  }
}
