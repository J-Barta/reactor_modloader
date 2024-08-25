
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/api_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  int id;
  String name;
  String email;
  String randomToken;
  bool verified;
  List<String> roles;
  List<int> mods;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.randomToken,
    required this.verified,
    required this.roles,
    required this.mods,
  });

  User.blank()
      : id = -1,
        name = "",
        email = "",
        randomToken = "",
        verified = false,
        roles = [],
        mods = [];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      randomToken: json['randomToken'] ?? "",
      verified: json['verified'],
      roles: List<String>.from(json['roles']),
      mods: json['modIds'] != null ? json['modIds'].map<int>((e) => e as int).toList() : [],
    );
  }

  bool isAdmin() {
    return roles.contains("admin");
  }

  static Future<User?> getUserFromPrefs() async {
    String? token = await SharedPreferences.getInstance()
        .then((prefs) => prefs.getString(APIConstants().userToken));
    if (token != null) {
      User? user = await getFromToken(token);
      user?.randomToken = token;

      return user;
    } else {
      return null;
    }
  }

  static Future<void> logOut() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    prefs.remove(APIConstants().userToken);
  }

  Future<User> changeName(String newName, BuildContext context) async {
    var result = await APISession.patchWithParams(
        "/poster/changeName", {'token': randomToken, 'name': newName});

    if(context.mounted) {
      if (result.statusCode == 200) {
        APIConstants.showSuccessToast("Changed user name to: $newName", context);
      } else {
        APIConstants.showErrorToast(
            "Failed to change name: ${result.body}", context);
      }
    }

    return this;
  }


  static Future<User?> getFromToken(String token) async {
    var result =
        await APISession.getWithParams("/poster/fromToken", {"token": token});

    if (result.statusCode == 200) {
      return User.fromJson(jsonDecode(result.body));
    } else {
      return null;
    }
  }

  Future<User> deleteUser(BuildContext context, {String token = ""}) async {
    var result = await APISession.deleteWithParams("/poster/delete", {"email": email, "token": token});
    if(context.mounted) {
      if (result.statusCode == 200) {
        APIConstants.showSuccessToast("User deleted successfully", context);
      } else {
        APIConstants.showErrorToast("Failed to delete user: ${result.body}", context);
      }
    }

    return this;
  }

  static Future<User?> authenticate(
      String email, String password, BuildContext context) async {
    var result = await APISession.getWithParams(
        "/poster/authenticate", {"email": email, "password": password});
    
    if (result.statusCode == 200) {
      User user = User.fromJson(jsonDecode(result.body));
      if(context.mounted) {
        APIConstants.showSuccessToast(
            "Successfully logged in! Welcome ${user.name}!", context);
      }
      return user;
    } else {
      if(context.mounted) {
        APIConstants.showErrorToast("Failed to Log in: ${result.body}", context);
      }
      return null;
    }
  }

  static Future<bool> create(
      String email, String password, String name, BuildContext context) async {
    var result = await APISession.postWithParams(
        "/poster/create", {"email": email, "password": password, "name": name});

    if (context.mounted) {
      if (result.statusCode == 200) {
        APIConstants.showSuccessToast(
            "Created Account! Verification Email Sent!", context);
      } else {
        APIConstants.showErrorToast(
            "Failed to Create Account: ${result.body}", context);
      }
    }

    return result.statusCode == 200;
  }

  
}