import 'package:flutter/material.dart';

ThemeData appTheme = ThemeData(
  useMaterial3: true,

  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromRGBO(82, 45, 11, 1),
    primary: const Color.fromRGBO(82, 45, 11, 1),    // Header Card & Button
    secondary: const Color.fromRGBO(82, 45, 11, 1),  // Switch "On" color
    surface: Colors.white, // Your Brown
  ),
  
  // ===== Scaffold =====
  scaffoldBackgroundColor: Color.fromRGBO(253, 251, 215, 1), // your cream background

  // ===== AppBar =====
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromRGBO(82, 45, 11, 1),
    foregroundColor: Colors.white,
    centerTitle: true,
  ),

  // ===== Text Theme (Topic 7 compliant) =====
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Color.fromRGBO(82, 45, 11, 1),
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: Colors.black,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      color: Colors.black54,
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
  backgroundColor: Color.fromRGBO(82, 45, 11, 1), // brown
  foregroundColor: Color.fromRGBO(253, 251, 215, 1), // cream icon
),


  // ===== Input Fields (used in SignUp / Register / Login) =====
   // ===== TextField / Input =====
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    labelStyle: const TextStyle(
      color: Color.fromRGBO(82, 45, 11, 1),
    ),
    prefixIconColor: const Color.fromRGBO(82, 45, 11, 1),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.black26),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: Color.fromRGBO(82, 45, 11, 1),
        width: 2,
      ),
    ),
  ),


  // ===== Buttons =====
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color.fromRGBO(82, 45, 11, 1),
      foregroundColor: Colors.white,
    ),
  ),
  // ===== Card / Surface =====
cardTheme: CardThemeData(
   surfaceTintColor: Colors.white,
  color: Colors.white,
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
),

// ===== Icon Theme =====
iconTheme: const IconThemeData(
  color: Colors.black54,
),

// ===== Text Button (used for links like distance) =====
textButtonTheme: TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: const Color.fromRGBO(82, 45, 11, 1),
  ),
),

);
