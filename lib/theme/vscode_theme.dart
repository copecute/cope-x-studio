import 'package:cope_x_studio/theme/app_sizes.dart';
import 'package:flutter/material.dart';

class VsCodeColors {
  static const activityBar = Color(0xFF333333);
  static const sidebar = Color(0xFF252526);
  static const editor = Color(0xFF1E1E1E);
  static const tabBar = Color(0xFF2D2D2D);
  static const tabActive = Color(0xFF1E1E1E);
  static const tabInactive = Color(0xFF2D2D2D);
  static const statusBar = Color(0xFF007ACC);
  static const border = Color(0xFF3C3C3C);
  static const foreground = Color(0xFFCCCCCC);
  static const foregroundDim = Color(0xFF858585);
  static const accent = Color(0xFF007ACC);
  static const selection = Color(0xFF264F78);
  static const hover = Color(0xFF2A2D2E);
  static const error = Color(0xFFF48771);
  static const success = Color(0xFF89D185);
}

ThemeData buildVsCodeTheme() {
  const colorScheme = ColorScheme.dark(
    surface: VsCodeColors.editor,
    onSurface: VsCodeColors.foreground,
    primary: VsCodeColors.accent,
    onPrimary: Colors.white,
    secondary: VsCodeColors.sidebar,
    outline: VsCodeColors.border,
    error: VsCodeColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: VsCodeColors.editor,
    colorScheme: colorScheme,
    dividerColor: VsCodeColors.border,
    iconTheme: const IconThemeData(color: VsCodeColors.foreground, size: AppSizes.iconMedium),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        color: VsCodeColors.foreground,
        fontSize: AppSizes.fontBody,
        fontFamily: 'Segoe UI',
      ),
      bodySmall: TextStyle(
        color: VsCodeColors.foregroundDim,
        fontSize: AppSizes.fontSmall,
        fontFamily: 'Segoe UI',
      ),
      labelSmall: TextStyle(
        color: VsCodeColors.foregroundDim,
        fontSize: AppSizes.fontCaption,
        fontFamily: 'Segoe UI',
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: Color(0xFF383838)),
      textStyle: TextStyle(color: Colors.white, fontSize: 12),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF383838),
      textStyle: TextStyle(color: VsCodeColors.foreground, fontSize: 13),
    ),
    menuTheme: const MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF383838)),
      ),
    ),
  );
}
