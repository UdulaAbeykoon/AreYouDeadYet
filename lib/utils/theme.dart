import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF98D889); // Pastel Green
  static const Color backgroundColor = Color(0xFFEEEEEE); // Light Grey
  static const Color errorColor = Color(0xFFFF5252);
  
  static TextStyle get headerStyle => GoogleFonts.jaro(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  
  static TextStyle get bigHeaderStyle => GoogleFonts.jaro(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  
  static TextStyle get bodyStyle => GoogleFonts.roboto(
    fontSize: 14,
    color: Colors.black,
  );

  static ThemeData get theme => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headerStyle,
      iconTheme: const IconThemeData(color: Colors.black),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: primaryColor,
      secondary: primaryColor,
      background: backgroundColor,
    ),
    textTheme: TextTheme(
      displayLarge: bigHeaderStyle,
      headlineMedium: headerStyle,
      bodyMedium: bodyStyle,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: primaryColor,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      selectedLabelStyle: headerStyle.copyWith(fontSize: 12),
      unselectedLabelStyle: headerStyle.copyWith(fontSize: 12),
    ),
  );
}
