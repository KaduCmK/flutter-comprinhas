import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The [AppTheme] defines light and dark themes for the app.
///
/// Use it with DynamicColorBuilder like this:
/// ```dart
/// DynamicColorBuilder(
///   builder: (lightDynamic, darkDynamic) => MaterialApp(
///     theme: AppTheme.light(colorScheme: lightDynamic),
///     darkTheme: AppTheme.dark(colorScheme: darkDynamic),
///   ),
/// );
/// ```
abstract final class AppTheme {
  // The FlexColorScheme defined light mode scheme colors.
  static const _lightScheme = FlexSchemeColor(
    primary: Color(0xFF00296B),
    primaryContainer: Color(0xFFA0C2ED),
    secondary: Color(0xFFD26900),
    secondaryContainer: Color(0xFFFFD270),
    tertiary: Color(0xFF5C5C95),
    tertiaryContainer: Color(0xFFC8DBF8),
    appBarColor: Color(0xFFC8DCF8),
    swapOnMaterial3: true,
  );

  // The FlexColorScheme defined dark mode scheme colors.
  static const _darkScheme = FlexSchemeColor(
    primary: Color(0xFFB1CFF5),
    primaryContainer: Color(0xFF3873BA),
    primaryLightRef: Color(0xFF00296B),
    secondary: Color(0xFFFFD270),
    secondaryContainer: Color(0xFFD26900),
    secondaryLightRef: Color(0xFFD26900),
    tertiary: Color(0xFFC9CBFC),
    tertiaryContainer: Color(0xFF535393),
    tertiaryLightRef: Color(0xFF5C5C95),
    appBarColor: Color(0xFF00102B),
    swapOnMaterial3: true,
  );

  /// Returns the light theme, optionally based on a dynamic [colorScheme].
  static ThemeData light({ColorScheme? colorScheme}) => FlexThemeData.light(
    colorScheme: colorScheme,
    colors: colorScheme == null ? _lightScheme : null,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      inputDecoratorIsFilled: true,
      alignedDropdown: true,
      tooltipRadius: 4,
      tooltipSchemeColor: SchemeColor.inverseSurface,
      tooltipOpacity: 0.9,
      snackBarElevation: 6,
      snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
      navigationRailUseIndicator: true,
    ),
    keyColors: const FlexKeyColors(),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  /// Returns the dark theme, optionally based on a dynamic [colorScheme].
  static ThemeData dark({ColorScheme? colorScheme}) => FlexThemeData.dark(
    colorScheme: colorScheme,
    colors: colorScheme == null ? _darkScheme : null,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      blendOnColors: true,
      inputDecoratorIsFilled: true,
      alignedDropdown: true,
      tooltipRadius: 4,
      tooltipSchemeColor: SchemeColor.inverseSurface,
      tooltipOpacity: 0.9,
      snackBarElevation: 6,
      snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
      navigationRailUseIndicator: true,
    ),
    keyColors: const FlexKeyColors(),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
