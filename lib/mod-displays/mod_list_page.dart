import 'package:flutter/material.dart';
import 'package:mosim_modloader/mod-displays/mod_list_view.dart';
import 'package:mosim_modloader/util/mod.dart';

class ModListPage extends StatefulWidget {
  final List<Mod> allMods;
  final List<Mod> installedMods;

  const ModListPage({super.key, required this.allMods, required this.installedMods});

  @override
  State<ModListPage> createState() => _ModListPageState();
}

class _ModListPageState extends State<ModListPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: widget.allMods.map((e) => ModListView(mod: e, installed: widget.installedMods.contains(e))).toList(),
            ),
          )
        ],
      ),
    );
  }
}
