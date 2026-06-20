import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class VsCodePalette {
  const VsCodePalette({
    required this.activityBar,
    required this.sidebar,
    required this.editor,
    required this.editorGutter,
    required this.tabBar,
    required this.tabActive,
    required this.tabInactive,
    required this.statusBar,
    required this.border,
    required this.foreground,
    required this.foregroundDim,
    required this.accent,
    required this.selection,
    required this.hover,
    required this.error,
    required this.success,
    required this.menuBackground,
    required this.tooltipBackground,
  });

  final Color activityBar;
  final Color sidebar;
  final Color editor;
  final Color editorGutter;
  final Color tabBar;
  final Color tabActive;
  final Color tabInactive;
  final Color statusBar;
  final Color border;
  final Color foreground;
  final Color foregroundDim;
  final Color accent;
  final Color selection;
  final Color hover;
  final Color error;
  final Color success;
  final Color menuBackground;
  final Color tooltipBackground;

  static const dark = VsCodePalette(
    activityBar: Color(0xFF333333),
    sidebar: Color(0xFF252526),
    editor: Color(0xFF1E1E1E),
    editorGutter: Color(0xFF181818),
    tabBar: Color(0xFF2D2D2D),
    tabActive: Color(0xFF1E1E1E),
    tabInactive: Color(0xFF2D2D2D),
    statusBar: Color(0xFF007ACC),
    border: Color(0xFF3C3C3C),
    foreground: Color(0xFFCCCCCC),
    foregroundDim: Color(0xFF858585),
    accent: Color(0xFF007ACC),
    selection: Color(0xFF264F78),
    hover: Color(0xFF2A2D2E),
    error: Color(0xFFF48771),
    success: Color(0xFF89D185),
    menuBackground: Color(0xFF383838),
    tooltipBackground: Color(0xFF383838),
  );

  /// VS Code Default Light+ inspired palette.
  static const light = VsCodePalette(
    activityBar: Color(0xFF333333),
    sidebar: Color(0xFFF3F3F3),
    editor: Color(0xFFFFFFFF),
    editorGutter: Color(0xFFF5F5F5),
    tabBar: Color(0xFFECECEC),
    tabActive: Color(0xFFFFFFFF),
    tabInactive: Color(0xFFECECEC),
    statusBar: Color(0xFF007ACC),
    border: Color(0xFFE5E5E5),
    foreground: Color(0xFF333333),
    foregroundDim: Color(0xFF6E7681),
    accent: Color(0xFF007ACC),
    selection: Color(0xFFADD6FF),
    hover: Color(0xFFE8E8E8),
    error: Color(0xFFE51400),
    success: Color(0xFF388A34),
    menuBackground: Color(0xFFF3F3F3),
    tooltipBackground: Color(0xFF616161),
  );

  static VsCodePalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Palette hiện tại — cập nhật qua [VsCodeColors.bind] khi đổi theme.
class VsCodeColors {
  VsCodeColors._();

  static VsCodePalette _palette = VsCodePalette.dark;

  static void bind(VsCodePalette palette) => _palette = palette;

  static Color get activityBar => _palette.activityBar;
  static Color get sidebar => _palette.sidebar;
  static Color get editor => _palette.editor;
  static Color get editorGutter => _palette.editorGutter;
  static Color get tabBar => _palette.tabBar;
  static Color get tabActive => _palette.tabActive;
  static Color get tabInactive => _palette.tabInactive;
  static Color get statusBar => _palette.statusBar;
  static Color get border => _palette.border;
  static Color get foreground => _palette.foreground;
  static Color get foregroundDim => _palette.foregroundDim;
  static Color get accent => _palette.accent;
  static Color get selection => _palette.selection;
  static Color get hover => _palette.hover;
  static Color get error => _palette.error;
  static Color get success => _palette.success;
}

ThemeData buildVsCodeTheme(Brightness brightness) {
  final palette = VsCodePalette.forBrightness(brightness);
  final isDark = brightness == Brightness.dark;

  final colorScheme = isDark
      ? ColorScheme.dark(
          surface: palette.editor,
          onSurface: palette.foreground,
          primary: palette.accent,
          onPrimary: Colors.white,
          secondary: palette.sidebar,
          outline: palette.border,
          error: palette.error,
        )
      : ColorScheme.light(
          surface: palette.editor,
          onSurface: palette.foreground,
          primary: palette.accent,
          onPrimary: Colors.white,
          secondary: palette.sidebar,
          outline: palette.border,
          error: palette.error,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.editor,
    colorScheme: colorScheme,
    dividerColor: palette.border,
    iconTheme: IconThemeData(color: palette.foreground, size: AppSizes.iconMedium),
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        color: palette.foreground,
        fontSize: AppSizes.fontBody,
        fontFamily: 'Segoe UI',
      ),
      bodySmall: TextStyle(
        color: palette.foregroundDim,
        fontSize: AppSizes.fontSmall,
        fontFamily: 'Segoe UI',
      ),
      labelSmall: TextStyle(
        color: palette.foregroundDim,
        fontSize: AppSizes.fontCaption,
        fontFamily: 'Segoe UI',
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: palette.tooltipBackground),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.menuBackground,
      textStyle: TextStyle(color: palette.foreground, fontSize: 13),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(palette.menuBackground),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.accent;
        return palette.foregroundDim;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.accent;
        return palette.foregroundDim;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.accent.withValues(alpha: 0.45);
        }
        return palette.border;
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: palette.accent,
      inactiveTrackColor: palette.border,
      thumbColor: palette.accent,
    ),
  );
}

void applyVsCodeSystemOverlay(Brightness brightness, {required bool fullscreen}) {
  if (fullscreen) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    return;
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final palette = VsCodePalette.forBrightness(brightness);
  final iconBrightness = brightness == Brightness.dark ? Brightness.light : Brightness.dark;
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    systemNavigationBarColor: palette.editor,
    systemNavigationBarIconBrightness: iconBrightness,
  ));
}

/// Giữ tương thích code cũ gọi `buildVsCodeTheme()` không tham số.
ThemeData buildVsCodeDarkTheme() => buildVsCodeTheme(Brightness.dark);
