

import 'package:intl/intl.dart';

class ModUpdate {
  int id;
  String? name;
  String? description;
  List<String>? robots;
  String? version;
  String? baseSimVersion;
  String? link;
  String? thumbnail;
  String? sourceCode;
  String? windowsPath;
  String? linuxPath;
  String? macPath;
  DateTime created;

  late String readableCreated;

  ModUpdate({
    required this.id,
    required this.name,
    required this.description,
    required this.robots,
    required this.version,
    required this.baseSimVersion,
    required this.link,
    required this.thumbnail,
    required this.sourceCode,
    required this.windowsPath,
    required this.linuxPath,
    required this.macPath,
    required this.created,
  }) {
  
    final formatter = DateFormat('MM-dd-yyyy');
    readableCreated = formatter.format(created);
  }


  factory ModUpdate.fromJson(Map<String, dynamic> json) {
    return ModUpdate(
      id: json['id'] as int,
      name: json['name'] as String?,
        description: json['description'] as String?,
        robots: (json['robots'] as List<dynamic>?)?.map((e) => e as String).toList(),
        version: json['version'] as String?,
        baseSimVersion: json['baseSimVersion'] as String?,
        link: json['link'] as String?,
        thumbnail: json['thumbnail'] as String?,
        sourceCode: json['sourceCode'] as String?,
        windowsPath: json['windowsPath'] as String?,
        linuxPath: json['linuxPath'] as String?,
        macPath: json['macPath'] as String?,    created: DateTime.parse(json['created'] as String),
    );
  }
}