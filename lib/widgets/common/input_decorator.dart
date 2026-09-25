import 'package:flutter/material.dart';

InputDecoration primaryInputDecoration(
  String hintText, {
  bool isOTP = false,
  Color fillColor = Colors.white,
  Color borderColor = Colors.grey,
}) {
  return InputDecoration(
    fillColor: fillColor,
    filled: true,
    contentPadding: EdgeInsets.symmetric(
      vertical: isOTP ? 15 : 20,
      horizontal: 16,
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),

    hintText: hintText,
    hintStyle: TextStyle(
      color: Colors.grey,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  );
}
