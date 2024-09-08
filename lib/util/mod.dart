import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mosim_modloader/util/api_session.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/download_util.dart';
import 'package:mosim_modloader/util/mod_update.dart';
import 'package:mosim_modloader/util/user.dart';
import 'package:process_run/shell.dart';

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

  ModUpdate? update;

  late String localVersion;

  Mod(
      {required this.id,
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
      this.update}) {
    DateFormat formatter = DateFormat("MM-dd-yy");

    readableUploadDate = formatter.format(uploadDate);
    readableLastUpdateDate = formatter.format(lastUpdated);

    localVersion = version;
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
      thumbnail: json['thumbnail'] ?? "",
      link: json['link'],
      sourceCode: json['sourceCode'],
      windowsPath: json['windowsPath'],
      linuxPath: json['linuxPath'],
      macPath: json['macPath'],
      author:
          json['poster'] != null ? User.fromJson(json['poster']) : User.blank(),
      uploadDate: DateTime.parse(json['createdAt']).toLocal(),
      lastUpdated: DateTime.parse(json['updatedAt']).toLocal(),
      downloads: json['downloads'] ?? -1,
      update:
          json['update'] != null ? ModUpdate.fromJson(json['update']) : null,
    );
  }

  static Future<bool> isAvailable(String name) async {
    var result = await APISession.get("/mod/checkAvailability");

    var jsonVal = jsonDecode(result.body);

    return jsonVal['available'];
  }

  static Future<Mod?> postMod(
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
      bool update,
      Mod? mod) async {
    var encodedData = jsonEncode({
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
      "id": mod?.id
    });

    var result = !update
        ? await APISession.post("/mod/create", encodedData)
        : await APISession.patch("/mod/update", encodedData);

    if (result.statusCode != 200) {
      APIConstants.showErrorToast(
          "Failed to post mod: ${result.body}", context);

      return null;
    } else {
      APIConstants.showSuccessToast(
          "Posted mod: $name. It will be reviewed and verified or returned to you for edits",
          context);

      return Mod.fromJson(jsonDecode(result.body));
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

  Future<void> downloadMod(
      BuildContext context,
      Function(double) downloadProgressConsumer,
      Function() onFinishDownload,
      Function() onFinishUnzip,
      Function() onUnzipFail) async {
    bool downloadSuccess = await DownloadUtil.downloadModFile(
        name, link, context, downloadProgressConsumer);

    if (downloadSuccess) {
      onFinishDownload();

      await APISession.postWithParams(
          "/mod/addDownload", {"id": id.toString()});

      bool unzipSuccess = await DownloadUtil.unzipFile(name, context);

      if (unzipSuccess) {
        generateMetadataFile();

        onFinishUnzip();
      } else {
        onUnzipFail();
      }
    } else {}
  }

  Future<void> generateMetadataFile() async {
    String pathForMetadataFile =
        "${await DownloadUtil.getModloaderPath()}/$name/metadata.json";

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
      "createdAt": uploadDate.toIso8601String(),
      "updatedAt": lastUpdated.toIso8601String(),
    }));
  }

  static Future<List<Mod>> loadInstalledMods(List<Mod> allMods) async {
    Directory modsDir = Directory(await DownloadUtil.getModloaderPath());

    if(!modsDir.existsSync()) {
      modsDir.createSync();
    }

    //Try to delete old zip files
    modsDir.listSync().forEach((e) {
      if (e is File) {
        if (e.path.endsWith(".zip")) {
          e.deleteSync();
        }
      }
    });

    Map<int, String> downloaded = {};

    modsDir.listSync().forEach((e) {
      if (e is Directory) {
        File metadataFile = File("${e.path}/metadata.json");

        if (metadataFile.existsSync()) {
          Map<String, dynamic> json =
              jsonDecode(metadataFile.readAsStringSync());

          downloaded.putIfAbsent(json['id'], () => json['version']);
        }
      }
    });

    List<Mod> mods =
        allMods.where((e) => downloaded.keys.contains(e.id)).toList();

    for (var element in mods) {
      element.localVersion = downloaded[element.id]!;
    }

    return mods;
  }

  static Future<List<Mod>> loadLocalMods() async {
    Directory modsDir = Directory(await DownloadUtil.getModloaderPath());

    List<Mod> mods = [];

    modsDir.listSync().forEach((e) {
      if (e is Directory) {
        File metadataFile = File("${e.path}/metadata.json");

        if (metadataFile.existsSync()) {
          Map<String, dynamic> json =
              jsonDecode(metadataFile.readAsStringSync());

          Mod loaded = Mod.fromJson(json);
          mods.add(loaded);
        }
      }
    });

    return mods;
  }

  Future<void> deleteMod(BuildContext context) async {
    try {
      Directory modDir =
          Directory("${await DownloadUtil.getModloaderPath()}/$name");

      modDir.deleteSync(recursive: true);

      File modZipFile =
          File("${await DownloadUtil.getModloaderPath()}/$name.zip");

      modZipFile.deleteSync();

      APIConstants.showSuccessToast("Uninstalled mod: $name", context);
    } catch (e) {
      APIConstants.showErrorToast(
          "Failed to uninstall mod: $name... $e", context);
    }
  }

  Future<void> verifyMod(BuildContext context) async {
    APISession.postWithParams("/mod/verify", {"id": id.toString()})
        .then((response) {
      if (response.statusCode == 200) {
        APIConstants.showSuccessToast("Verified mod: $name", context);
      } else {
        APIConstants.showErrorToast("Failed to verify mod: $name", context);
      }
    });
  }

  Future<bool> approveModUpdate(BuildContext context) async {
    var response = await APISession.patchWithParams("/mod/approveUpdate",
        {"id": id.toString(), "updateId": update!.id.toString()});

    if (response.statusCode == 200) {
      APIConstants.showSuccessToast("Approved update for mod: $name", context);
      return true;
    } else {
      APIConstants.showErrorToast(
          "Failed to approve update for mod: $name, ${response.body}", context);
      return false;
    }
  }

  Future<bool> rejectModUpdate(BuildContext context) async {
    var response = await APISession.deleteWithParams("/mod/rejectUpdate",
        {"id": id.toString(), "updateId": update!.id.toString()});

    if (response.statusCode == 200) {
      APIConstants.showSuccessToast("Rejected Update for mod: $name", context);
      return true;
    } else {
      APIConstants.showErrorToast(
          "Failed to reject update for mod: $name, ${response.body}", context);
      return false;
    }
  }

  static Future<NameResult> nameAvailable(String name) async {
    var response = await APISession.getWithParams(
        "/mod/checkAvailability", {"name": name});

    var jsonVal = jsonDecode(response.body);

    return NameResult(name: jsonVal["name"], available: jsonVal['available']);
  }

  void launchMod(BuildContext context) async {
    try {
      String executablePath =
          "${await DownloadUtil.getModloaderPath()}/${Platform.isWindows || Platform.isLinux ? windowsPath : macPath}"
              .replaceAll("/", "\\");

      if (Platform.isLinux) {
        executablePath = executablePath.replaceAll("\\", "/");

        var shell = Shell(
            workingDirectory:
                executablePath.substring(0, executablePath.lastIndexOf("/")));

        String path = windowsPath.replaceAll("\\", "/");
        path = path.substring(0, path.lastIndexOf("/")).splitMapJoin(
            RegExp(r'/'),
            onMatch: (e) => '${e[0]}',
            onNonMatch: (n) => '\'$n\'');

        await shell.run('''
        # Print working directory
        pwd

        ls

        wine ./${windowsPath.replaceAll("\\", "/").split("/").last}

        ''');
      } else {
        Process.run(executablePath, [' start ']).then((ProcessResult results) {
          stdout.writeln(results.stdout);
        });
      }
    } catch (e) {
      APIConstants.showErrorToast("Failed to launch mod: $name", context);
    }
  }
}

class NameResult {
  final String name;
  final bool available;

  NameResult({required this.name, required this.available});
}
