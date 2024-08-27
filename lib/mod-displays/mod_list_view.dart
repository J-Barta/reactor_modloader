import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mosim_modloader/mod-displays/mod_update_page.dart';
import 'package:mosim_modloader/mod_editor.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/mod.dart';
import 'package:mosim_modloader/util/user.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class ModListView extends StatefulWidget {
  final Mod mod;
  final bool installed;
  final Function onInstallsChanged;
  final Function? reloadModList;

  final bool canEdit;
  final User? user;

  const ModListView(
      {super.key,
      required this.mod,
      required this.installed,
      required this.onInstallsChanged,
      this.canEdit = false,
      this.user,
      this.reloadModList});

  @override
  State<ModListView> createState() => _ModListViewState();
}

class _ModListViewState extends State<ModListView> {
  Image? image;
  bool hasThumbnail = false;

  double downloadProgress = 0;
  bool downloading = false;
  bool unzipping = false;

  bool failedUnzip = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadThumbnail();
    });
  }

  @override
  void didUpdateWidget(ModListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mod != widget.mod) {
      loadThumbnail();
    }
  }

  void loadThumbnail() async {
    if (widget.mod.thumbnail != "") {
      try {
        Image newImage = Image.memory(base64Decode(widget.mod.thumbnail));

        setState(() {
          image = newImage;
          hasThumbnail = true;
        });
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.mod.verified
          ? StyleConstants.shadedDecoration(context)
          : StyleConstants.warningShadedDecoration(context),
      margin: StyleConstants.margin,
      padding: StyleConstants.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.canEdit
              ? IconButton(
                  tooltip: "Edit Mod",
                  icon: const Icon(
                    Icons.edit,
                    size: 48,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ModEditorPage(
                                user: widget.user, mod: widget.mod)));
                  },
                )
              : Container(),
          widget.mod.localVersion != widget.mod.version
              ? Tooltip(
                  message: "Update Available",
                  child: IconButton(
                    icon: const Icon(
                      Icons.update,
                      color: Colors.blue,
                      size: 48,
                    ),
                    onPressed: () async {
                      setState(() {
                        downloading = true;
                      });

                      try {
                        await download(context);
                      } catch (e) {}
                    },
                  ),
                )
              : Container(),
          hasThumbnail
              ? Flexible(
                  flex: 1,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image: image!.image,
                        width: 400,
                      )),
                )
              : Container(),
          Flexible(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.mod.name,
                        style: StyleConstants.titleStyle,
                      ),
                      widget.mod.verified
                          ? Container()
                          : const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Tooltip(
                                message: "Unverified",
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: Colors.yellow,
                                  size: 48,
                                ),
                              ),
                            ),
                      widget.user != null &&
                              widget.user!.isAdmin() &&
                              !widget.mod.verified
                          ? IconButton(
                              tooltip: "Verify Mod",
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 48,
                              ),
                              onPressed: () async {
                                await widget.mod.verifyMod(context);

                                if (widget.reloadModList != null) {
                                  widget.reloadModList!();
                                }
                              },
                            )
                          : Container(),
                      widget.mod.update != null &&
                              widget.user != null &&
                              widget.user!.isAdmin()
                          ? IconButton(
                              tooltip: "Update Requested",
                              icon: const Icon(
                                Icons.update,
                                color: Colors.blue,
                                size: 48,
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ModUpdatePage(
                                            user: widget.user!,
                                            mod: widget.mod)));
                              },
                            )
                          : Container()
                    ],
                  ),
                  Tooltip(
                    message: widget.mod.description,
                    triggerMode: TooltipTriggerMode.tap,
                    waitDuration: const Duration(milliseconds: 500),
                    child: Text(
                      widget.mod.description,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      maxLines: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Column(
              children: [
                Text("Robots", style: StyleConstants.subtitleStyle),
                Column(
                  children: widget.mod.robots.map((e) => Text(e)).toList(),
                )
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: Column(
              children: [
                !downloading
                    ? !widget.installed
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                tooltip: "Download Mod",
                                icon: const Icon(Icons.download),
                                onPressed: () async {
                                  setState(() {
                                    downloading = true;
                                  });

                                  try {
                                    await download(context);
                                  } catch (e) {}
                                },
                              ),
                              Text(widget.mod.downloads.toString())
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    widget.mod.launchMod(context);
                                  },
                                  icon: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.blue,
                                  )),
                              const Tooltip(
                                  message: "Installed",
                                  child:
                                      Icon(Icons.check, color: Colors.green)),
                              IconButton(
                                  tooltip: "Uninstall",
                                  onPressed: () async {
                                    await widget.mod.deleteMod(context);

                                    widget.onInstallsChanged();
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red)),
                              Container(
                                width: 10,
                              ),
                              const Icon(Icons.download),
                              Tooltip(
                                  message: "Downloads",
                                  child: Text(widget.mod.downloads.toString()))
                            ],
                          )
                    :
                    // Container()
                    Row(
                        // mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: downloadProgress,
                              backgroundColor:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "${(downloadProgress * 100).toStringAsFixed(0)}%",
                            ),
                          )
                        ],
                      ),
                Text("Mod by: ${widget.mod.author.name}"),
                Text("Last Updated: ${widget.mod.readableUploadDate}"),
                Text("Version: ${widget.mod.version}"),
                Text("Base MoSim Version: ${widget.mod.baseSimVersion}"),
                widget.mod.sourceCode != ""
                    ? IconButton(
                        tooltip: "View Source Code",
                        icon: Icon(widget.mod.sourceCode.contains("github")
                            ? SimpleIcons.github
                            : Icons.code),
                        onPressed: () async {
                          await launchUrl(Uri.parse(widget.mod.sourceCode));
                        },
                      )
                    : Container(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> download(BuildContext context) async {
    await widget.mod.downloadMod(context, (progress) {
      if (!mounted) return;
      setState(() {
        downloadProgress = progress;
      });
    }, () {
      if (!mounted) return;
      setState(() {
        unzipping = true;
        downloading = false;
      });
    }, () {
      if (!mounted) return;
      setState(() {
        unzipping = false;

        widget.onInstallsChanged();
      });
    }, () {
      if (!mounted) return;
      setState(() {
        unzipping = false;
        failedUnzip = true;
      });
    });
  }
}
