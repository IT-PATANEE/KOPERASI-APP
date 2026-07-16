import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Constants {
  //Primary color
  static var primaryColor = const Color.fromARGB(255, 0, 87, 31);
  static var bg = Color.fromARGB(255, 250, 250, 250);
  static var greenColor= Colors.green[700];
  // static var greenColors= Color.fromARGB(255, 0, 164, 81);
  static var greenColors= Color.fromARGB(255, 22, 150, 75);
  static var blackColor = Colors.black54;
  static var redColor = const Color.fromARGB(255, 170, 17, 6);
  static var greyLight = const Color.fromARGB(136, 238, 234, 234);
  

  //Onboarding texts
  static var titleOne = "Learn more about plants";
  static var descriptionOne =
      "Read how to care for plants in our rich plants guide.";
  static var titleTwo = "Find a plant lover friend";
  static var descriptionTwo =
      "Are you a plant lover? Connect with other plant lovers.";
  static var titleThree = "Plant a tree, green the Earth";
  static var descriptionThree =
      "Find almost all types of plants that you like here.";
}

class ThemeStyle {
  static TextStyle primaryHead = const TextStyle(
      fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.white);
  static TextStyle primaryTitle = const TextStyle(
    color: Colors.white,
    fontSize: 20,
  );

  static ThemeData lightTheme(BuildContext context) {
    final scaleFactor = MediaQuery.of(context).textScaleFactor;

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Constants.primaryColor,
      scaffoldBackgroundColor: Constants.bg,
      fontFamily: 'Kanit', // ใช้ฟอนต์ไทย
      textTheme: TextTheme(
        displayLarge: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 96 * scaleFactor),
        displayMedium: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 60 * scaleFactor),
        displaySmall: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 48 * scaleFactor),
        headlineMedium: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 34 * scaleFactor),
        headlineSmall: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 24 * scaleFactor),
        titleLarge: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 20 * scaleFactor),
        bodyLarge: GoogleFonts.kanit(fontSize: 16 * scaleFactor, fontWeight: FontWeight.normal),
        bodyMedium: GoogleFonts.kanit(fontSize: 14 * scaleFactor, fontWeight: FontWeight.normal),
        titleMedium: GoogleFonts.kanit(fontSize: 16 * scaleFactor, fontWeight: FontWeight.normal),
        titleSmall: GoogleFonts.kanit(fontSize: 14 * scaleFactor, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.kanit(fontSize: 14 * scaleFactor, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.kanit(fontSize: 12 * scaleFactor, fontWeight: FontWeight.normal),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 16 * scaleFactor),
          backgroundColor: Constants.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.kanit(fontWeight: FontWeight.w600, fontSize: 16 * scaleFactor),
          foregroundColor: Constants.primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.kanit(fontSize: 14 * scaleFactor, color: Colors.black54),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Constants.greenColors, // หรือใส่สีเขียวตามโค้ดสีคอนเซปต์ของแอปคุณ เช่น Color(0xFF...)
    ),
    );
  }
}

TextTheme defaultText = TextTheme(
    displayLarge: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 96),
    displayMedium:
        GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 60),
    displaySmall: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 48),
    headlineMedium:
        GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 34),
    headlineSmall:
        GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 24),
    titleLarge: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 20),
    bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.normal,
    ),
    titleMedium:
        GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.normal),
    titleSmall: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.normal));
