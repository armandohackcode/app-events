import 'package:app_events/config/theme/app_styles.dart';
import 'package:flutter/material.dart';

class AppTheme {
  OutlineInputBorder borderInput({Color color = AppStyles.fontColor}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color),
    );
  }

  ThemeData getTheme() => ThemeData(
    scaffoldBackgroundColor: AppStyles.backgroundColor,
    textTheme: Typography.blackRedmond.apply(
      bodyColor: AppStyles.fontColor,
      fontFamily: 'GoogleSans',
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: AppStyles.fontSecondaryColor),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.all(9),
      fillColor: Colors.white,
      filled: true,
      enabledBorder: borderInput(color: AppStyles.borderColor),
      focusedErrorBorder: borderInput(color: AppStyles.colorBaseBlue),
      focusedBorder: borderInput(color: AppStyles.colorBaseBlue),
      errorBorder: borderInput(color: Colors.red),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(9),
        fillColor: Colors.white,
        filled: true,
        enabledBorder: borderInput(color: AppStyles.borderColor),
        focusedErrorBorder: borderInput(color: AppStyles.colorBaseBlue),
        focusedBorder: borderInput(color: AppStyles.colorBaseBlue),
        errorBorder: borderInput(color: Colors.red),
      ),
    ),
    fontFamily: 'GoogleSans',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppStyles.colorAppbar,
      centerTitle: true,
      elevation: 0,
      foregroundColor: AppStyles.fontColor,
      shadowColor: AppStyles.borderColor,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppStyles.fontColor,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      foregroundColor: Colors.white,
      backgroundColor: AppStyles.colorBaseBlue,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppStyles.colorBaseBlue),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppStyles.colorBaseBlue,
        foregroundColor: Colors.white,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppStyles.colorBaseBlue,
      circularTrackColor: const Color(0xFFBBD6FF),
    ),
    primarySwatch: Colors.blue,
  );
}
