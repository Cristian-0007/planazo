import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de color del kit de diseño de Planazo (modo oscuro).
class Paleta {
  const Paleta._();

  static const noche = Color(0xFF150F2E);
  static const noche2 = Color(0xFF1E1743);
  static const noche3 = Color(0xFF2A2158);
  static const borde = Color(0xFF39306B);
  static const papel = Color(0xFFF4F1FA);
  static const papelMut = Color(0xFFA79FC6);
  static const amarillo = Color(0xFFFFC93C);
  static const fucsia = Color(0xFFF5407E);
  static const menta = Color(0xFF4FE0B0);
  static const naranja = Color(0xFFFF8A3D);
  static const grisEstado = Color(0xFF7A7299);
}

/// Radios de borde del kit.
class Radios {
  const Radios._();

  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const xl = 30.0;
}

/// Tipografías del kit: Bricolage Grotesque para títulos y cifras,
/// Manrope para la interfaz y el cuerpo.
class Tipografia {
  const Tipografia._();

  static TextStyle display(
    double tamano, {
    FontWeight peso = FontWeight.w800,
    double? espaciado,
    double? altura,
    Color color = Paleta.papel,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: tamano,
      fontWeight: peso,
      letterSpacing: espaciado,
      height: altura,
      color: color,
    );
  }

  static TextStyle ui(
    double tamano, {
    FontWeight peso = FontWeight.w500,
    double? altura,
    Color color = Paleta.papel,
  }) {
    return GoogleFonts.manrope(
      fontSize: tamano,
      fontWeight: peso,
      height: altura,
      color: color,
    );
  }
}

/// Decoración de los campos de texto, según el kit (fondo noche-2,
/// borde morado, borde amarillo al enfocar).
InputDecoration decoracionCampo({
  required String etiqueta,
  IconData? icono,
  Widget? sufijo,
}) {
  OutlineInputBorder borde(Color color, [double ancho = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radios.sm),
      borderSide: BorderSide(color: color, width: ancho),
    );
  }

  return InputDecoration(
    labelText: etiqueta,
    labelStyle: Tipografia.ui(15, color: Paleta.papelMut),
    floatingLabelStyle:
        Tipografia.ui(14, peso: FontWeight.w700, color: Paleta.amarillo),
    prefixIcon: icono == null ? null : Icon(icono, color: Paleta.papelMut),
    suffixIcon: sufijo,
    filled: true,
    fillColor: Paleta.noche2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
    border: borde(Paleta.borde),
    enabledBorder: borde(Paleta.borde),
    focusedBorder: borde(Paleta.amarillo, 1.5),
    errorBorder: borde(Paleta.fucsia),
    focusedErrorBorder: borde(Paleta.fucsia, 1.5),
    errorStyle:
        Tipografia.ui(13, peso: FontWeight.w600, color: Paleta.fucsia),
  );
}

ThemeData construirTema() {
  const esquema = ColorScheme.dark(
    primary: Paleta.amarillo,
    onPrimary: Paleta.noche,
    secondary: Paleta.fucsia,
    onSecondary: Paleta.papel,
    error: Paleta.fucsia,
    onError: Paleta.papel,
    surface: Paleta.noche,
    onSurface: Paleta.papel,
    outline: Paleta.borde,
  );

  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: esquema,
    useMaterial3: true,
  );

  // Se arma con estilos sueltos (GoogleFonts.manrope) y no con
  // GoogleFonts.manropeTextTheme: en las versiones nuevas de google_fonts
  // ese método usa otro tipo de TextTheme, incompatible con el de Flutter.
  final texto = base.textTheme.copyWith(
    bodyLarge: Tipografia.ui(16),
    bodyMedium: Tipografia.ui(14),
    bodySmall: Tipografia.ui(12, color: Paleta.papelMut),
    labelLarge: Tipografia.ui(14, peso: FontWeight.w700),
    labelMedium: Tipografia.ui(12, peso: FontWeight.w600),
    labelSmall: Tipografia.ui(11, peso: FontWeight.w600),
    titleLarge: Tipografia.display(22, peso: FontWeight.w600),
    titleMedium: Tipografia.ui(16, peso: FontWeight.w600),
    titleSmall: Tipografia.ui(14, peso: FontWeight.w600),
  );

  return base.copyWith(
    scaffoldBackgroundColor: Paleta.noche,
    textTheme: texto,
    dividerColor: Paleta.borde,
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Paleta.amarillo),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Paleta.amarillo,
        foregroundColor: Paleta.noche,
        disabledBackgroundColor: Paleta.noche3,
        disabledForegroundColor: Paleta.papelMut,
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        textStyle: Tipografia.ui(15, peso: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Paleta.papel,
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        side: const BorderSide(color: Paleta.borde),
        textStyle: Tipografia.ui(15, peso: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Paleta.amarillo,
        minimumSize: const Size(44, 44),
        textStyle: Tipografia.ui(14, peso: FontWeight.w700),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((estados) {
        return estados.contains(WidgetState.selected)
            ? Paleta.amarillo
            : Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(Paleta.noche),
      side: const BorderSide(color: Paleta.papelMut, width: 1.5),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Paleta.noche3,
      contentTextStyle: Tipografia.ui(14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radios.sm),
        side: const BorderSide(color: Paleta.borde),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Paleta.noche2,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: 78,
      labelTextStyle: WidgetStateProperty.resolveWith((estados) {
        final activo = estados.contains(WidgetState.selected);
        return Tipografia.ui(
          12,
          peso: FontWeight.w600,
          color: activo ? Paleta.amarillo : Paleta.papelMut,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((estados) {
        final activo = estados.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: activo ? Paleta.amarillo : Paleta.papelMut,
        );
      }),
    ),
  );
}
