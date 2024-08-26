import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/mod.dart';
import 'package:mosim_modloader/util/user.dart';

class ModUpdatePage extends StatefulWidget {
  final Mod mod;
  final User user;
  const ModUpdatePage({super.key, required this.mod, required this.user});

  @override
  State<ModUpdatePage> createState() => _ModUpdatePageState();
}

class _ModUpdatePageState extends State<ModUpdatePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Request for ${widget.mod.name}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(children: [
        Center(
            child: Text(
          "Submitted: ${widget.mod.update?.readableCreated}",
          style: StyleConstants.subtitleStyle,
        )),
        UpdateField(
            label: "Name",
            original: widget.mod.name,
            updated: widget.mod.update?.name),
        UpdateField(
            label: "Description",
            original: widget.mod.description,
            updated: widget.mod.update?.description),
        UpdateField(
          label: "robots",
          original: "[${widget.mod.robots.join(", ")}]",
          updated: widget.mod.update?.robots != null
              ? "[${widget.mod.update?.robots?.join(", ")}]"
              : null,
        ),
        UpdateField(
            label: "Version",
            original: widget.mod.version,
            updated: widget.mod.update?.version),
        UpdateField(
            label: "Base Sim Version",
            original: widget.mod.baseSimVersion,
            updated: widget.mod.update?.baseSimVersion),
        UpdateField(
            label: "Download Link",
            original: widget.mod.link,
            updated: widget.mod.update?.link),
        UpdateField(
            label: "Windows Path",
            original: widget.mod.windowsPath,
            updated: widget.mod.update?.windowsPath),
        UpdateField(
            label: "Mac Path",
            original: widget.mod.macPath,
            updated: widget.mod.update?.macPath),
        UpdateField(
            label: "Linux Path",
            original: widget.mod.linuxPath,
            updated: widget.mod.update?.linuxPath),

        //Thumbnail stuff
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              
              child: Image.memory(
                base64Decode(widget.mod.thumbnail),
              ),
            ),
          ),
          if (widget.mod.update?.thumbnail != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                
                child: Image.memory(
                  base64Decode(widget.mod.update!.thumbnail!),
                ),
              ),
            )

        ],),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement discard logic
                },
                icon: const Icon(Icons.close),
                label: Text('Discard', style: StyleConstants.subtitleStyle),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await widget.mod.approveModUpdate(context);

                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check),
                label: Text('Approve', style: StyleConstants.subtitleStyle),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class UpdateField extends StatelessWidget {
  final String label;

  final String original;
  final String? updated;

  const UpdateField(
      {super.key, required this.label, required this.original, this.updated});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              child: Tooltip(
                  message: original,
                  waitDuration: const Duration(milliseconds: 500),
                  child: Text(
                    "$label: $original",
                    style: updated != null
                        ? StyleConstants.subtitleStyle
                        : StyleConstants.graySubtitle,
                    overflow: TextOverflow.ellipsis,
                  ))),
          if (updated != null)
            Flexible(
                child: Tooltip(
              message: updated!,
              waitDuration: const Duration(milliseconds: 500),
              child: Text(
                "$updated",
                style: StyleConstants.subtitleStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ))
          else
            Flexible(
                child: Text("(Unchanged)", style: StyleConstants.graySubtitle))
        ],
      ),
    );
  }
}
