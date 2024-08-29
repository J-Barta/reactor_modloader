import 'package:flutter/material.dart';
import 'package:mosim_modloader/mod-displays/mod_list_view.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/mod.dart';

class Home extends StatefulWidget {
  final List<Mod> installedMods;
  final Function onInstallsChanged;

  const Home(
      {super.key,
      required this.installedMods,
      required this.onInstallsChanged});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: widget.installedMods.isNotEmpty
                ? ListView(
                    children: widget.installedMods
                        .map((e) => ModListView(
                              mod: e,
                              installed: true,
                              onInstallsChanged: widget.onInstallsChanged,
                            ))
                        .toList(),
                  )
                : Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: Text(
                          "Thanks for installing Reactor! It looks like you have no mods installed yet. Navigate to the Mods tab in the hamburger menu to get playing!",
                          style: StyleConstants.h3Style,
                          textAlign: TextAlign.center,
                          ),
                    ),
                  ),
          )
        ],
      ),
    );
  }
}
