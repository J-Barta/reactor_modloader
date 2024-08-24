import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:path_provider/path_provider.dart';

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

  static Future<bool> unzipFile(String modName, bool deleteOriginal, BuildContext context) async {

    try {

      String zipPath = await getModZipFilePath(modName);

      final inputStream = InputFileStream(zipPath);

      final archive = ZipDecoder().decodeBuffer(inputStream);

      await extractArchiveToDisk(
          archive, "${await getModloaderPath()}/$modName");

      APIConstants.showSuccessToast("File Unzipped!", context);

      if(deleteOriginal) {
        // File(zipPath).deleteSync();
      }

      return true;
    } catch (e) {
      APIConstants.showErrorToast("Failed to unzip file: $e", context);

      return false;
    }
  }

  static Future<String> getModZipFilePath(String name) async {
    return "${await getModloaderPath()}/$name.zip";
  }

  static Future<void> ensureModloaderDirectoryExists() async {
    Directory(await getModloaderPath()).createSync(recursive: true);
  }

  static Future<String> getModloaderPath() async {
    return await getApplicationDocumentsDirectory()
        .then((value) => ("${value.path}/reactor_modloader"));
  }
}
