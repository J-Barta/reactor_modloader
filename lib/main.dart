
import 'package:flutter/material.dart';
import 'package:mosim_modloader/account.dart';
import 'package:mosim_modloader/home.dart';
import 'package:mosim_modloader/mod-displays/mod_list_page.dart';
import 'package:mosim_modloader/util/api_session.dart';
import 'package:mosim_modloader/util/mod.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  APISession.updateKeys();


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

  String version = "";
  int selectedIndex = 0;
  static List<Widget> widgetOptions = <Widget>[];

  List<Mod> allMods = [];
  List<Mod> installedMods = [];

  @override
  void initState() {
    super.initState();
    initVersion();

    loadMods();

    reloadInstalledMods();

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
    List<Mod> installed = await Mod.loadInstalledMods(allMods);

    setState(() {
      installedMods = installed;
    });

    regenWidgetOptions();
  }

  void initVersion() async {
    PackageInfo info = await PackageInfo.fromPlatform();

    setState(() {
      version = info.version;
    });
  }

  void onItemTapped(int index) {
    pageViewController.animateToPage(index,
        duration: const Duration(milliseconds: 100), curve: Curves.easeInOut);
  }

  void regenWidgetOptions() {
    widgetOptions = [
      Home(installedMods: installedMods),
      ModListPage(allMods: allMods, installedMods: installedMods),
      Account()
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reactor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
            )
    );
  }
}
