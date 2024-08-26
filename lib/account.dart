import 'package:flutter/material.dart';
import 'package:mosim_modloader/account-widgets/sign_in.dart';
import 'package:mosim_modloader/mod_editor.dart';
import 'package:mosim_modloader/mod-displays/mod_list_view.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/api_session.dart';
import 'package:mosim_modloader/util/mod.dart';
import 'package:mosim_modloader/util/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Account extends StatefulWidget {
  final List<Mod> allMods;
  final List<Mod> installedMods;
  final Function onInstallsChanged;
  const Account(
      {super.key,
      required this.allMods,
      required this.installedMods,
      required this.onInstallsChanged});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  late User? user;

  bool changingName = false;

  TextEditingController nameController = TextEditingController();
  bool requestingNameCheck = false;
  bool nameTaken = false;

  bool changingEmail = false;

  TextEditingController emailController = TextEditingController();
  bool requestingEmailCheck = false;
  bool emailTaken = false;

  @override
  void initState() {
    super.initState();

    user = User.blank();

    changingName = false;

    loadUser();
  }

  void loadUser() async {
    User? newUser = await User.getUserFromPrefs();

    if (newUser != null) {
      setState(() {
        user = newUser;
        nameController.text = user?.name ?? "";
      });
    } else {
      setState(() {
        user = User.blank();
      });
    }
  }

  void changeName() async {
    if (user != null) {
      User newUser = await user!.changeName(nameController.text, context);

      setState(() {
        user = newUser;

        nameController.text = newUser.name;
        changingName = false;
      });
    }
  }

  Future<void> logOut() async {
    User.logOut();

    setState(() {
      user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Mod> userMods = widget.allMods
        .where((element) => element.author.id == user?.id)
        .toList();

    return user != null && user?.email != ""
        ? Scaffold(
            body: SingleChildScrollView(
            child: Column(
              children: [
                !changingName
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                              user!.name,
                              style: StyleConstants.titleStyle,
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  changingName = true;
                                });
                              },
                              icon: const Icon(Icons.edit),
                              tooltip: "Change Name",
                            )
                          ])
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            child: nameTaken
                                ? const Tooltip(
                                    message: "Name taken!",
                                    child: Icon(Icons.error_rounded,
                                        color: Colors.red))
                                : requestingNameCheck
                                    ? const Tooltip(
                                        message: "Checking Name Availability",
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        ))
                                    : const Tooltip(
                                        message: "Name Available!",
                                        child: Icon(Icons.check_circle,
                                            color: Colors.green)),
                          ),
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: nameController,
                              onChanged: (value) async {
                                setState(() {
                                  requestingNameCheck = true;
                                });

                                NameResult result =
                                    await User.nameAvailable(value);

                                if (result.name == nameController.text) {
                                  setState(() {
                                    nameTaken = !result.available &&
                                        result.name != user?.name;
                                    requestingNameCheck = false;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'New Name'),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              if(!nameTaken) {
                                changeName();
                              } else {
                                APIConstants.showErrorToast("Username already taken!", context);
                              }
                            },
                            icon: const Icon(Icons.save, color: Colors.green),
                            tooltip: "Save",
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                changingName = false;
                              });
                            },
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                            tooltip: "Cancel",
                          )
                        ],
                      ),
                Text(
                  user!.email,
                  style: StyleConstants.h3Style,
                ),
                ElevatedButton(
                  onPressed: () async {
                    await logOut();
                  },
                  child: Text(
                    "Logout",
                    style: StyleConstants.subtitleStyle,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Your Mods (${userMods.length})",
                        style: StyleConstants.subtitleStyle,
                      ),
                      ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.inversePrimary,
                              foregroundColor: Colors.white),
                          onPressed: () async {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    ModEditorPage(user: user)));
                          },
                          icon: const Icon(Icons.add),
                          label: Text(
                            "Create Mod",
                            style: StyleConstants.subtitleStyle,
                          )),
                    ],
                  ),
                ),
                Column(
                  children: userMods
                      .map((e) => ModListView(
                          mod: e,
                          installed: widget.installedMods.contains(e),
                          onInstallsChanged: widget.onInstallsChanged,
                          canEdit: true,
                          user: user))
                      .toList(),
                )
              ],
            ),
          ))
        : SignInWidget(setUser: (User newUser) async {
            SharedPreferences prefs = await SharedPreferences.getInstance();

            if (newUser.randomToken.isNotEmpty) {
              prefs.setString(APIConstants().userToken, newUser.randomToken);

              setState(() {
                user = newUser;
              });

              // widget.loadUser();

              APISession.updateKeys();
            } else {
              if (context.mounted) {
                APIConstants.showErrorToast("Missing Account Token!", context);
              }
            }
          });
  }
}
