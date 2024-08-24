import 'package:flutter/material.dart';
import 'package:mosim_modloader/mod-displays/mod_list_view.dart';
import 'package:mosim_modloader/util/mod.dart';

class Home extends StatefulWidget {
  final List<Mod> installedMods;

  const Home({super.key, required this.installedMods});

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
            child: ListView(
              children: widget.installedMods.map((e) => ModListView(mod: e, installed: true)).toList(),
            ),
          )
        ],
      ),
    );
  }
}