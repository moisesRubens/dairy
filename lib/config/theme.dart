import 'package:flutter/material.dart';

/// Tokens de design da marca "Fazenda Boa Esperança".
///
/// Regra de ouro (ver CLAUDE.md): **nada de azul**. Verde para receita/
/// sucesso, vermelho para ações destrutivas. AppBar preta, fundo branco.
class AppColors {
  AppColors._();

  /// Acento de receita / sucesso.
  static const Color green = Color(0xFF2E7D32);

  /// Ações destrutivas (excluir, sair).
  static const Color red = Color(0xFFE74C3C);

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Superfícies — tema claro
  static const Color scaffoldLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFF5F5F5); // grey[100]
  static const Color borderLight = Color(0xFFE0E0E0); // grey[300]

  // Superfícies — tema escuro
  static const Color scaffoldDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceMutedDark = Color(0xFF262626);
  static const Color borderDark = Color(0xFF3A3A3A);

  static const Color grey = Color(0xFF9E9E9E);
}

/// Raios de borda padronizados.
class AppRadii {
  AppRadii._();

  static const double card = 16; // cards do grid de produtos
  static const double revenue = 12; // cards de receita / inputs grandes
  static const double table = 8; // tabelas
  static const double input = 4; // inputs inline
}

/// Espaçamentos base (múltiplos de 4).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Atalhos de cores que se adaptam ao tema (claro/escuro) a partir do
/// contexto. Evita repetir `Theme.of(context).brightness == ...` nas telas.
extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Fundo de cards/containers (branco no claro, cinza-escuro no escuro).
  Color get cardSurface =>
      isDarkMode ? AppColors.surfaceDark : AppColors.white;

  /// Fundo de cabeçalhos de tabela e áreas levemente destacadas.
  Color get mutedSurface =>
      isDarkMode ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight;

  /// Cor de bordas finas.
  Color get borderColor =>
      isDarkMode ? AppColors.borderDark : AppColors.borderLight;
}

/// Temas claro e escuro do app, derivados dos tokens acima.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.green,
      error: AppColors.red,
      surface: isDark ? AppColors.surfaceDark : AppColors.white,
    );

    final Color appBarColor = isDark ? AppColors.surfaceDark : AppColors.black;
    final Color borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.white),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.green : AppColors.black,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.revenue),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.revenue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.revenue),
          borderSide: BorderSide(
            color: isDark ? AppColors.green : AppColors.black,
            width: 2,
          ),
        ),
      ),
      dividerColor: borderColor,
      cardColor: isDark ? AppColors.surfaceDark : AppColors.white,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        selectedItemColor: isDark ? AppColors.white : AppColors.black,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
