import 'package:flutter/material.dart';
import 'package:mosim_modloader/account-widgets/sign_in.dart';
import 'package:mosim_modloader/create_mod.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/api_session.dart';
import 'package:mosim_modloader/util/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  late User? user;

  bool changingName = false;
  TextEditingController nameController = TextEditingController();

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
                            width: 300,
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'New Name'),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              changeName();
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
                ElevatedButton(onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateModPage(user: user)));
                }, child: Text(
                  "Create Mod",
                  style: StyleConstants.subtitleStyle,
                ))
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
