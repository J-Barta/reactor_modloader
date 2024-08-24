import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mosim_modloader/util/api_session.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/download_util.dart';
import 'package:mosim_modloader/util/mod.dart';
import 'package:mosim_modloader/util/user.dart';
import 'package:path_provider/path_provider.dart';

class CreateModPage extends StatefulWidget {
  final User? user;

  const CreateModPage({super.key, required this.user});

  @override
  State<CreateModPage> createState() => _CreateModPageState();
}

class _CreateModPageState extends State<CreateModPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController downloadURLController = TextEditingController();

  TextEditingController descriptionController = TextEditingController();
  TextEditingController versionController = TextEditingController();
  TextEditingController baseSimVersionController = TextEditingController();
  TextEditingController sourceCodeController = TextEditingController();

  Image? thumbnail;
  bool hasThumbnail = false;
  File? thumbnailFile;

  List<String> robots = [];

  bool downloading = false;
  double amountDownloaded = 0;
  bool downloadComplete = false;
  bool downloadFailed = false;

  bool unzipping = false;
  bool unzipSuccess = false;

  String baseFolderPath = "";
  List<String> foldersDisplayed = [];

  String windowsPath = "";
  String macPath = "";

  bool nameTaken = false;

  bool _showDeleteIcon = false;

  void downloadAndUnzipFile(BuildContext context) async {
    setState(() {
      amountDownloaded = 0;
      downloading = true;
    });

    bool downloadSuccess = await DownloadUtil.downloadModFile(
        nameController.text, downloadURLController.text, context, (value) {
      setState(() {
        amountDownloaded = value;
      });
    });

    if(downloadSuccess) {
       setState(() {
          downloading = false;
          downloadComplete = true;
        });

        bool unzipSuccess = await DownloadUtil.unzipFile(nameController.text, true, context);

        if(unzipSuccess) {
          setState(() {
            unzipping = false;
            unzipSuccess = true;
          });
        } else {
          setState(() {
            unzipping = false;
            unzipSuccess = false;
          });
        }
    } else {
       setState(() {
          downloading = false;
          downloadFailed = true;
        });
    }
  }

  Widget getFolderDisplay() {
    List<Widget> displays = [];
    for (int i = 0; i < foldersDisplayed.length; i++) {
      displays.add(FolderListDisplay(
        path: foldersDisplayed[i],
        onFolderSelected: (String newPath) {
          foldersDisplayed.removeRange(i + 1, foldersDisplayed.length);

          setState(() {
            foldersDisplayed.add(newPath);
          });
        },
        onFileSelected: (String path, String type) {
          if (type == "windows") {
            setState(() {
              windowsPath = path.split("mosim_modloader/").last;
            });
          } else if (type == "mac") {
            setState(() {
              macPath = path.split("mosim_modloader/").last;
            });
          }
        },
        windowsPath: windowsPath,
        macPath: macPath,
      ));
    }

    return Row(
      children: displays,
    );
  }

  @override
  Widget build(BuildContext context) {
    //TODO: Check if the mod's name has already been used
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Mod'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: nameController,
                readOnly: downloading || downloadComplete,
                decoration: InputDecoration(
                  labelText: 'Mod Name',
                  border: const OutlineInputBorder(),
                  errorText: nameTaken ? "Name taken!" : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: downloadURLController,
                readOnly: downloading || downloadComplete,
                decoration: const InputDecoration(
                    labelText: 'Download URL', border: OutlineInputBorder()),
              ),
            ),
            !downloading && !downloadComplete
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          downloadAndUnzipFile(context);
                        });
                      },
                      child: const Text('Download Mod Files'),
                    ))
                : Container(),
            !downloadComplete
                ? downloading
                    ? Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: LinearProgressIndicator(
                              value: amountDownloaded,
                              backgroundColor:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          Text(
                            "Downloading... ${(amountDownloaded * 100).toStringAsFixed(0)}%",
                            style: StyleConstants.subtitleStyle,
                          ),
                        ],
                      )
                    : Container()
                : unzipping
                    ? Column(
                        children: [
                          const CircularProgressIndicator(),
                          Text(
                            "File Downloaded! Unzipping...",
                            style: StyleConstants.subtitleStyle,
                          ),
                        ],
                      )
                    : unzipSuccess
                        ? Column(
                            children: [
                              Text(
                                "File Unzipped!",
                                style: StyleConstants.subtitleStyle,
                              ),
                              Text(
                                "Select Game Executables.",
                                style: StyleConstants.subtitleStyle,
                              ),
                              getFolderDisplay(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Windows Path: ${windowsPath != "" ? windowsPath : "(None)"}",
                                    style: StyleConstants.h3Style,
                                  ),
                                  windowsPath != ""
                                      ? IconButton(
                                          tooltip: "Remove",
                                          onPressed: () {
                                            setState(() {
                                              windowsPath = "";
                                            });
                                          },
                                          icon: const Icon(Icons.cancel,
                                              color: Colors.red))
                                      : Container()
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Mac Path: ${macPath != "" ? macPath : "(None)"}",
                                    style: StyleConstants.h3Style,
                                  ),
                                  macPath != ""
                                      ? IconButton(
                                          tooltip: "Remove",
                                          onPressed: () {
                                            setState(() {
                                              macPath = "";
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                          ))
                                      : Container()
                                ],
                              ),
                              Text(
                                "Game Details",
                                style: StyleConstants.subtitleStyle,
                              ),
                              Row(
                                children: [
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        controller: versionController,
                                        onChanged: (value) => setState(() {}),
                                        decoration: InputDecoration(
                                            labelText: 'Mod Version',
                                            border: const OutlineInputBorder(),
                                            errorText:
                                                versionController.text == ""
                                                    ? "Required!"
                                                    : null),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        controller: baseSimVersionController,
                                        onChanged: (value) => setState(() {}),
                                        decoration: InputDecoration(
                                            labelText: 'Base MoSim Version',
                                            border: const OutlineInputBorder(),
                                            errorText:
                                                baseSimVersionController.text ==
                                                        ""
                                                    ? "Required!"
                                                    : null),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextField(
                                        controller: sourceCodeController,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Source Code Link (Optional)',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  controller: descriptionController,
                                  decoration: const InputDecoration(
                                      labelText: 'Mod Description',
                                      border: OutlineInputBorder()),
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minWidth:
                                          MediaQuery.of(context).size.width),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        RobotSelector(
                                            robots: robots,
                                            setRobots: (List<String> robots) {
                                              setState(() {
                                                this.robots = robots;
                                              });
                                            }),
                                        hasThumbnail
                                            ? MouseRegion(
                                                onEnter: (_) {
                                                  setState(() {
                                                    _showDeleteIcon = true;
                                                  });
                                                },
                                                onExit: (_) {
                                                  setState(() {
                                                    _showDeleteIcon = false;
                                                  });
                                                },
                                                child: Stack(children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        hasThumbnail = false;
                                                        thumbnail = null;
                                                      });
                                                    },
                                                    child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: Image(
                                                          image:
                                                              thumbnail!.image,
                                                          width: 600,
                                                        )),
                                                  ),
                                                  SizedBox(
                                                    width: 600,
                                                    height: thumbnail!.height
                                                            ?.toDouble() ??
                                                        300,
                                                    child: AnimatedOpacity(
                                                      opacity: _showDeleteIcon
                                                          ? 1.0
                                                          : 0.0,
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: IconButton(
                                                          tooltip:
                                                              "Remove icon",
                                                          icon: const Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                            size: 48,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              hasThumbnail =
                                                                  false;
                                                              thumbnail = null;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ]),
                                              )
                                            : ElevatedButton.icon(
                                                onPressed: () async {
                                                  FilePickerResult? result =
                                                      await FilePicker.platform
                                                          .pickFiles(
                                                              allowedExtensions: [
                                                        'jpg',
                                                        'jpeg',
                                                        'png',
                                                        'bmp'
                                                      ]);

                                                  if (result != null) {
                                                    File file = File(result
                                                        .files.single.path!);

                                                    setState(() {
                                                      thumbnail =
                                                          Image.file(file);
                                                      thumbnailFile = file;
                                                      hasThumbnail = true;
                                                    });
                                                  } else {
                                                    // User canceled the picker
                                                  }
                                                },
                                                icon: const Icon(Icons.upload),
                                                label: const Text(
                                                    "Upload thumbnail"),
                                              ),
                                        ElevatedButton.icon(
                                            onPressed: () {
                                              APISession.updateKeys();

                                              if (widget.user != null &&
                                                  hasThumbnail &&
                                                  robots.isNotEmpty &&
                                                  nameController
                                                      .text.isNotEmpty &&
                                                  descriptionController
                                                      .text.isNotEmpty &&
                                                  versionController
                                                      .text.isNotEmpty &&
                                                  baseSimVersionController
                                                      .text.isNotEmpty &&
                                                  (windowsPath.isNotEmpty ||
                                                      macPath.isNotEmpty)) {
                                                Mod.postMod(
                                                    nameController.text,
                                                    downloadURLController.text,
                                                    descriptionController.text,
                                                    versionController.text,
                                                    baseSimVersionController
                                                        .text,
                                                    sourceCodeController.text,
                                                    robots,
                                                    base64Encode(thumbnailFile!
                                                        .readAsBytesSync()),
                                                    windowsPath,
                                                    macPath,
                                                    "",
                                                    widget.user!,
                                                    context);
                                              } else {
                                                APIConstants.showErrorToast(
                                                    "Please fill out all fields!",
                                                    context);
                                              }
                                            },
                                            icon: const Icon(Icons.save),
                                            label: const Text("Post Mod"))
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        : Column(
                            children: [
                              Text(
                                "Failed to Unzip File!",
                                style: StyleConstants.subtitleStyle,
                              ),
                            ],
                          ),
          ],
        ),
      ),
    );
  }
}

class RobotSelector extends StatefulWidget {
  final List<String> robots;
  final Function(List<String>) setRobots;

  const RobotSelector(
      {super.key, required this.robots, required this.setRobots});

  @override
  State<RobotSelector> createState() => _RobotSelectorState();
}

class _RobotSelectorState extends State<RobotSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: StyleConstants.shadedDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Text("Robots", style: StyleConstants.h3Style),
          ...widget.robots.map((e) {
            return SizedBox(
                width: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: e,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Robot Name",
                        ),
                        onChanged: (value) {
                          setState(() {
                            widget.robots[widget.robots.indexOf(e)] = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                        tooltip: "Remove Robot",
                        onPressed: () {
                          setState(() {
                            widget.robots.remove(e);
                          });
                        },
                        icon: const Icon(
                          Icons.remove,
                          color: Colors.red,
                        ))
                  ],
                ));
          }),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.robots.add("");
                  });
                },
                child: const Text("Add Robot")),
          )
        ]),
      ),
    );
  }
}

class FolderListDisplay extends StatefulWidget {
  final String path;
  final Function(String) onFolderSelected;
  final Function(String, String) onFileSelected;
  final String windowsPath;
  final String macPath;

  const FolderListDisplay(
      {super.key,
      required this.path,
      required this.onFolderSelected,
      required this.onFileSelected,
      required this.windowsPath,
      required this.macPath});

  @override
  State<FolderListDisplay> createState() => _FolderListDisplayState();
}

class _FolderListDisplayState extends State<FolderListDisplay> {
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();

    files = Directory(widget.path).listSync();
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: StyleConstants.shadedDecoration(context),
          child: MouseRegion(
            onEnter: (_) {},
            onExit: (_) {},
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: files.map((e) {
                  if (FileSystemEntity.isFileSync(e.path)) {
                    return ListTile(
                        leading: const Icon(Icons.file_copy),
                        title: Text(e.path.split("/").last),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.window,
                                color: widget.windowsPath ==
                                        e.path.split("mosim_modloader/").last
                                    ? Colors.green
                                    : null,
                              ),
                              onPressed: () {
                                widget.onFileSelected(e.path, "windows");
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.apple,
                                  color: widget.macPath ==
                                          e.path.split("mosim_modloader/").last
                                      ? Colors.green
                                      : null),
                              onPressed: () {
                                widget.onFileSelected(e.path, "mac");
                              },
                            ),
                          ],
                        ));
                  } else {
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(e.path.split("/").last),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        widget.onFolderSelected(e.path);
                      },
                    );
                  }
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
