import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class APIConstants {
  // String baseUrl = "http://localhost:3000";
  String baseUrl = "http://40.233.83.5:3000";
  String userToken = "token";

  static void showSuccessToast(String message, BuildContext? context,
      {int seconds = 5}) {
    try {
      if (context != null) {
        toastification.show(
            context: context,
            autoCloseDuration: Duration(seconds: seconds),
            type: ToastificationType.success,
            style: ToastificationStyle.flatColored,
            title: Text(message));
      }
    } catch (e) {
      stderr.writeln("Error showing toast: $e");
    }
  }

  static void showErrorToast(String message, BuildContext? context,
      {int seconds = 5}) {
    try {
      if (context != null) {
        toastification.show(
            context: context,
            autoCloseDuration: Duration(seconds: seconds),
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: Text(message));
      }
    } catch (e) {
      stderr.writeln("Error showing toast: $e");
    }
  }
}

class StyleConstants {
  static TextStyle titleStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 48,
  );

  static TextStyle subtitleStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 24,
  );

  static TextStyle graySubtitle = const TextStyle(
    fontSize: 24,
    color: Colors.grey
  );

  static TextStyle h3Style =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 18);

  static TextStyle statStyle =
      const TextStyle(fontWeight: FontWeight.bold, fontSize: 32);

  static BoxDecoration shadedDecoration(BuildContext context) {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.2));
  }

  static BoxDecoration alternateShadedDecoration(BuildContext context) {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.8));
  }

  static BoxDecoration warningShadedDecoration(BuildContext context) {
    return BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.yellow),
        color: Colors.yellow.withOpacity(0.2));
  }

  static EdgeInsets margin = const EdgeInsets.all(8);
  static EdgeInsets padding = const EdgeInsets.fromLTRB(16, 8, 16, 8);
}
