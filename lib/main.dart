import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mosim_modloader/account.dart';
import 'package:mosim_modloader/home.dart';
import 'package:mosim_modloader/mod-displays/mod_list_page.dart';
import 'package:mosim_modloader/util/api_session.dart';
import 'package:mosim_modloader/util/download_util.dart';
import 'package:mosim_modloader/util/mod.dart';
import 'package:mosim_modloader/util/user.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:updat/updat.dart';
import 'package:http/http.dart' as http;
import 'package:updat/updat_window_manager.dart';
import 'package:updat/theme/chips/floating_with_silent_download.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  APISession.updateKeys();

  DownloadUtil.ensureModloaderDirectoryExists();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String version = "";

  @override
  void initState() {
    super.initState();
    initVersion();
  }

  void initVersion() async {
    PackageInfo info = await PackageInfo.fromPlatform();

    setState(() {
      version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Reactor Modloader v$version",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Theme.of(context).colorScheme.surface,
      ),
      darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue, brightness: Brightness.dark),
          brightness: Brightness.dark),
      home: const BottomNavigation(),
    );
  }
}

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  final pageViewController = PageController(initialPage: 0);

  String version = "0.0.0";
  int selectedIndex = 0;
  static List<Widget> widgetOptions = <Widget>[];

  List<Mod> allMods = [];
  List<Mod> installedMods = [];

  User? user;

  Widget? updatWidget;

  @override
  void initState() {
    super.initState();
    initVersion();

    loadMods();

    reloadInstalledMods();

    loadUser();

    regenWidgetOptions();
  }

  Future<void> loadUser() async {
    User? newUser = await User.getUserFromPrefs();

    if (newUser != null) {
      setState(() {
        user = newUser;
      });
    }

    regenWidgetOptions();
  }

  void loadMods() async {
    List<Mod> all = await Mod.getMods();

    List<Mod> installed = await Mod.loadInstalledMods(all);

    setState(() {
      allMods = all;
      installedMods = installed;
    });

    regenWidgetOptions();
  }

  void reloadInstalledMods() async {

    List<Mod> installed = [];

    try { 
      installed = await Mod.loadInstalledMods(allMods);

    }  catch (e) {}

    //Installs will be empty if there are either no mods installed or no connection, so try to load local mods instead
    if(installed.isEmpty) {
      installed = await Mod.loadLocalMods();
    }

    setState(() {
      installedMods = installed;
    });

    regenWidgetOptions();
  }

  void initVersion() async {
    PackageInfo info = await PackageInfo.fromPlatform();

    setState(() {
      version = info.version;

      updatWidget = UpdatWidget(
          currentVersion: version,
          getLatestVersion: () async {
            // Github gives us a super useful latest endpoint, and we can use it to get the latest stable release
            final data = await http.get(Uri.parse(
              "https://api.github.com/repos/J-Barta/reactor_modloader/releases/latest",
            ));
    
            // Return the tag name, which is always a semantically versioned string.
            return jsonDecode(data.body)["tag_name"];
          },
          getBinaryUrl: (version) async {
            return "https://github.com/J-Barta/reactor_modloader/releases/download/$version/reactor-${Platform.operatingSystem}-$version.$platformExt";
          },
          appName: "Reactor Modloader",
          getChangelog: (_, __) async {
            final data = await http.get(Uri.parse(
              "https://api.github.com/repos/J-Barta/reactor_modloader/releases/latest",
            ));
            return jsonDecode(data.body)["body"];
          },
        );
    });
  }

  void onItemTapped(int index) {
    pageViewController.animateToPage(index,
        duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
  }

  void regenWidgetOptions() {
    widgetOptions = [
      Home(
        installedMods: installedMods,
        onInstallsChanged: reloadInstalledMods,
      ),
      ModListPage(
        allMods: allMods,
        installedMods: installedMods,
        onInstallsChanged: reloadInstalledMods,
        user: user,
        reloadModList: loadMods,
      ),
      Account(
          allMods: allMods,
          installedMods: installedMods,
          onInstallsChanged: reloadInstalledMods)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: updatWidget,
        appBar: AppBar(
          title: const Text('Reactor'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.folder),
              tooltip: "Open Mod Directory",
              onPressed: () async {
                String path = await DownloadUtil.getModloaderPath();
                path = path.replaceAll("/", "\\");
                Process.run(
                  "explorer",
                  [path],
                  workingDirectory:path 
                );
              }
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                loadMods();
              },
            ),
          ],
        ),
        body: PageView(
          controller: pageViewController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          children: widgetOptions,
        ),
        drawer: Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.inversePrimary),
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Reactor v$version',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        )
                      ])),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  onItemTapped(0);
                  reloadInstalledMods();
                },
              ),
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('Mods'),
                onTap: () {
                  onItemTapped(1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Account'),
                onTap: () {
                  onItemTapped(2);
                },
              )
            ],
          ),
        ));
  }

  String get platformExt {
    switch (Platform.operatingSystem) {
      case 'windows':
        {
          return 'exe';
        }

      case 'macos':
        {
          return 'dmg';
        }

      case 'linux':
        {
          return 'AppImage';
        }
      default:
        {
          return 'zip';
        }
    }
  }
}
