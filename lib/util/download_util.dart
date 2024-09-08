import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadUtil {

  /// Downloads a mod file from the given URL and saves it to the modloader directory
  static Future<bool> downloadModFile(String name, String downloadURL, BuildContext context, Function(double) downloadDecimalSetter) async {
    //Create the download directory if necessary
    Directory(await getModloaderPath()).createSync(recursive: true);

    String filePath = await getModZipFilePath(name);

    Dio dioDownload = Dio();

    String downloadPath = downloadURL;

    if (downloadPath.isNotEmpty) {
      final response = await dioDownload.download(downloadPath, filePath,
          onReceiveProgress: (actualBytes, int totalBytes) {
        double received = (actualBytes / totalBytes);


        downloadDecimalSetter(received.toDouble());
      });
      if (response.statusCode == 200) {
        APIConstants.showSuccessToast("Download Succeeded!", context);

        return true;
      } else {
        APIConstants.showErrorToast("Download Failed!", context);

        return false;
      }
    } else {
      return false;
    }
  }

  static Future<bool> unzipFile(String modName, BuildContext context) async {

    try {

      String zipPath = await getModZipFilePath(modName);

      await extractFileToDisk(zipPath, "${await getModloaderPath()}/$modName");

      APIConstants.showSuccessToast("File Unzipped!", context);

      return true;
    } catch (e) {
      APIConstants.showErrorToast("Failed to unzip file: $e", context);

      return false;
    }
  }

  static Future<String> getModZipFilePath(String name) async {
    return "${await getModloaderPath()}/$name.zip";
  }

  static Future<String> getModDirectory(String name) async {
    return "${await getModloaderPath()}/$name";
  }

  static Future<void> ensureModloaderDirectoryExists() async {
    Directory(await getModloaderPath()).createSync(recursive: true);
  }

  static Future<String> getModloaderPath() async {
    return await getBaseStorageLocation()
        .then((value) => ("$value/${getBaseDirectoryName()}"));
  }

  static Future<void> setBaseStorageLocation(String location, BuildContext context) async {
    try {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString(APIConstants().storageLocation, location);

    APIConstants.showSuccessToast("Successfully set save location", context);

    } catch (e) {
        APIConstants.showErrorToast("Failed to set save location", context);
    }
  }

  static Future<String> getBaseStorageLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? storageLocation = prefs.getString(APIConstants().storageLocation);

    if(storageLocation != null) {
      return storageLocation;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }

  static String getBaseDirectoryName() {
    return "reactor_modloader";
  }
}
