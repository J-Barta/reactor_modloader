import 'package:flutter/material.dart';
import 'package:mosim_modloader/mod-displays/mod_list_view.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/mod.dart';
import 'package:mosim_modloader/util/user.dart';

class ModListPage extends StatefulWidget {
  final List<Mod> allMods;
  final List<Mod> installedMods;
  final Function onInstallsChanged;
  final Function? reloadModList;

  final User? user;

  const ModListPage(
      {super.key,
      required this.allMods,
      required this.installedMods,
      required this.onInstallsChanged,
      required this.user,
      this.reloadModList});

  @override
  State<ModListPage> createState() => _ModListPageState();
}

class _ModListPageState extends State<ModListPage> {
  TextEditingController searchController = TextEditingController();

  bool showUnverified = false;

  String sortCondition = "downloads";
  bool sortOrder = false;

  @override
  void initState() {
    super.initState();
  }

  List<Mod> applySearch(List<Mod> mods) {
    if (searchController.text == "") {
      return mods;
    }

    return mods.where((element) {
      String concatenatedInfo = element.name +
          element.description +
          element.author.name +
          element.robots.join(" ");

      return concatenatedInfo
          .toLowerCase()
          .trim()
          .contains(searchController.text.toLowerCase().trim());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Mod> modsToDisplay = widget.allMods;

    if (!showUnverified) {
      modsToDisplay =
          modsToDisplay.where((element) => element.verified).toList();
    }

    modsToDisplay = applySearch(modsToDisplay);

    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("${modsToDisplay.length} Shown",
                    style: StyleConstants.h3Style),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                        hintText: "Search", border: OutlineInputBorder()),
                  ),
                ),
              ),
              Checkbox(
                  value: showUnverified,
                  onChanged: (value) {
                    setState(() {
                      showUnverified = value!;
                    });
                  }),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Show Unverified"),
              ),
              const Text("Sort By:"),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: sortCondition,
                  onChanged: (String? newValue) {
                    setState(() {
                      sortCondition = newValue!;
                    });
                  },
                  items: <String>['downloads', 'name', 'lastUpdated']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                          "${value[0].toUpperCase()}${value.substring(1).replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')}"),
                    );
                  }).toList(),
                ),
              ),
              const Text("Order:"),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Icon(
                      sortOrder ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                    onPressed: () {
                      setState(() {
                        sortOrder = !sortOrder;
                      });
                    },
                  )),
            ],
          ),
          Expanded(
            child: ListView(
              children: modsToDisplay
                  .map((e) => ModListView(
                      user: widget.user,
                      mod: e,
                      installed: widget.installedMods.contains(e),
                      onInstallsChanged: widget.onInstallsChanged,
                      reloadModList: widget.reloadModList))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }
}
