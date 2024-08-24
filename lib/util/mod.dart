import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mosim_modloader/util/api_session.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/download_util.dart';
import 'package:mosim_modloader/util/user.dart';

class Mod {
  int id;
  String name;
  String description;
  List<String> robots;
  bool verified;
  String version;
  String baseSimVersion;
  String thumbnail;
  String link;
  String sourceCode;
  String windowsPath;
  String linuxPath;
  String macPath;
  User author;

  int downloads;

  DateTime uploadDate;
  DateTime lastUpdated;

  late String readableUploadDate;
  late String readableLastUpdateDate;

  Mod({
    required this.id,
    required this.name,
    required this.description,
    required this.robots,
    required this.verified,
    required this.version,
    required this.baseSimVersion,
    required this.thumbnail,
    required this.link,
    required this.sourceCode,
    required this.windowsPath,
    required this.linuxPath,
    required this.macPath,
    required this.author,
    required this.uploadDate,
    required this.lastUpdated,
    required this.downloads,
  }) {
    DateFormat formatter = DateFormat("MM-dd-yy");

    readableUploadDate = formatter.format(uploadDate);
    readableLastUpdateDate = formatter.format(lastUpdated);

  }

  factory Mod.fromJson(Map<String, dynamic> json) {
    return Mod(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      robots: List<String>.from(json['robots']),
      verified: json['verified'],
      version: json['version'],
      baseSimVersion: json['baseSimVersion'],
      thumbnail: json['thumbnail'],
      link: json['link'],
      sourceCode: json['sourceCode'],
      windowsPath: json['windowsPath'],
      linuxPath: json['linuxPath'],
      macPath: json['macPath'],
      author: User.fromJson(json['poster']),
      uploadDate: DateTime.parse(json['createdAt']).toLocal(),
      lastUpdated: DateTime.parse(json['updatedAt']).toLocal(),
      downloads: json['downloads'],
      )
    ;
  }

  static Future<bool> isAvailable(String name) async {

    var result = await APISession.get("/mod/checkAvailability");

    var jsonVal = jsonDecode(result.body);

    return jsonVal['available'];
  }

  static Future<void> postMod(
    String name,
    String downloadURL,
    String description,
    String version,
    String baseSimVersion,
    String sourceCode,
    List<String> robots,
    String thumbnail,
    String windowsPath,
    String macPath,
    String linuxPath,
    User author,
    BuildContext context,
  ) async {

    var result = await APISession.post("/mod/create", jsonEncode({
      "name": name,
      "link": downloadURL,
      "description": description,
      "version": version,
      "baseSimVersion": baseSimVersion,
      "sourceCode": sourceCode,
      "robots": robots,
      "thumbnail": thumbnail,
      "windowsPath": windowsPath,
      "macPath": macPath,
      "linuxPath": linuxPath,
      "author": author.id,
    }));

    if (result.statusCode != 200) {
      APIConstants.showErrorToast("Failed to post mod: ${result.body}", context);
    } else {
      APIConstants.showSuccessToast("Posted mod: $name. It will be reviewed and verified or returned to you for edits", context);
      Navigator.of(context).pop();
    }

  }

  static Future<List<Mod>> getMods() async {
    var result = await APISession.get("/mod/getAll");

    List<dynamic> jsonVal = jsonDecode(result.body);

    List<Mod> mods = [];

    for (var mod in jsonVal) {
      mods.add(Mod.fromJson(mod));
    }

    return mods;
  }

  Future<void> downloadMod(BuildContext context, Function(double) downloadProgressConsumer, Function() onFinishDownload, Function() onFinishUnzip, Function() onUnzipFail) async {
    bool downloadSuccess = await DownloadUtil.downloadModFile(name, link, context, downloadProgressConsumer);

    if(downloadSuccess) {
      onFinishDownload();

      var response = await APISession.postWithParams("/mod/addDownload", {"id": id.toString()});

      bool unzipSuccess = await DownloadUtil.unzipFile(name, true, context);

      if(unzipSuccess) {
        String pathForMetadataFile = "${await DownloadUtil.getModloaderPath()}/$name/metadata.json";

        File file = File(pathForMetadataFile);

        file.createSync();

        file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
          "id": id,
          "name": name,
          "description": description,
          "robots": robots,
          "verified": verified,
          "version": version,
          "baseSimVersion": baseSimVersion,
          "link": link,
          "sourceCode": sourceCode,
          "windowsPath": windowsPath,
          "linuxPath": linuxPath,
          "macPath": macPath,
          "author": author.id,
          "uploadDate": uploadDate.toIso8601String(),
          "lastUpdated": lastUpdated.toIso8601String(),
        }));

        onFinishUnzip();
      } else {
        onUnzipFail();
      }
    } else {
    }

  }

  static Future<List<Mod>> loadInstalledMods(List<Mod> allMods) async {

      Directory modsDir = Directory(await DownloadUtil.getModloaderPath());

      List<int> downloadedIds = [];

      modsDir.listSync().forEach((e) {
        if(e is Directory) {
          File metadataFile = File("${e.path}/metadata.json");

          if(metadataFile.existsSync()) {
            Map<String, dynamic> json = jsonDecode(metadataFile.readAsStringSync());
            
            downloadedIds.add(json['id']);
        }
      }
      });

      return allMods.where((e) => downloadedIds.contains(e.id)).toList();

  }

  void launchMod() async {
    String executablePath = "${await DownloadUtil.getModloaderPath()}/${Platform.isWindows ? windowsPath : Platform.isLinux ? linuxPath : macPath}".replaceAll("/", "\\");

    Process.run(executablePath, [' start ']).then((ProcessResult results) {
      print(results.stdout);
    });

  }
  
}