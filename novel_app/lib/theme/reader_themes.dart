import 'package:flutter/material.dart';

class ReaderTheme {
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color headerColor;
  final Color secondaryTextColor;
  final Color dividerColor;

  const ReaderTheme({
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.headerColor,
    required this.secondaryTextColor,
    required this.dividerColor,
  });
}

class ReaderThemes {
  static const List<ReaderTheme> themes = [

    ReaderTheme(
      name: 'Light',
      backgroundColor: Color(0xFFFDFDFD),
      textColor: Color(0xFF1E1E1E),
      headerColor: Color(0xFFF2F2F2),
      secondaryTextColor: Color(0xFF666666),
      dividerColor: Color(0xFFE0E0E0),
    ),

    ReaderTheme(
      name: 'Soft Grey',
      backgroundColor: Color(0xFFF4F4F4),
      textColor: Color(0xFF222222),
      headerColor: Color(0xFFE8E8E8),
      secondaryTextColor: Color(0xFF555555),
      dividerColor: Color(0xFFD6D6D6),
    ),

    ReaderTheme(
      name: 'Dark Blue',
      backgroundColor: Color(0xFF1F2A38),
      textColor: Color(0xFFE6EDF3),
      headerColor: Color(0xFF263445),
      secondaryTextColor: Color(0xFF9FB3C8),
      dividerColor: Color(0xFF324457),
    ),

    ReaderTheme(
      name: 'Dark',
      backgroundColor: Color(0xFF121212),
      textColor: Color(0xFFEAEAEA),
      headerColor: Color(0xFF1E1E1E),
      secondaryTextColor: Color(0xFFAAAAAA),
      dividerColor: Color(0xFF2A2A2A),
    ),
  ];
}
