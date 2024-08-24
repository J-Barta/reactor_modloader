import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/mod.dart';

class ModListView extends StatefulWidget {
  final Mod mod;
  final bool installed;
  const ModListView({super.key, required this.mod, required this.installed});

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
      decoration: StyleConstants.shadedDecoration(context),
      margin: StyleConstants.margin,
      padding: StyleConstants.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                  Text(
                    widget.mod.name,
                    style: StyleConstants.titleStyle,
                  ),
                  Text(
                    widget.mod.description,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    maxLines: 5,
                  ),
                ],
              ),
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
                                    await widget.mod.downloadMod(context,
                                        (progress) {
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
                                      });
                                    }, () {
                                      if (!mounted) return;
                                      setState(() {
                                        unzipping = false;
                                        failedUnzip = true;
                                      });
                                    });
                                  } catch (e) {}
                                },
                              ),
                              Text(widget.mod.downloads.toString())
                            ],
                          )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(onPressed: () {
                                widget.mod.launchMod();
                              }, icon: const Icon(Icons.play_arrow, color: Colors.blue,)),
                              const Tooltip( message: "Installed", child: Icon(Icons.check, color: Colors.green)),
                              IconButton(tooltip: "Remove Mod", onPressed: () {

                              }, icon: const Icon(Icons.delete, color: Colors.red)),
                              Container(width: 10,),
                              const Icon(Icons.download),
                              Tooltip( message: "Downloads", child: Text(widget.mod.downloads.toString()))
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
              ],
            ),
          )
        ],
      ),
    );
  }
}
