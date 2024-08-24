
import 'package:flutter/material.dart';
import 'package:mosim_modloader/account-widgets/forgot_password_age.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/user.dart';

typedef SetUserFunction = void Function(User user);

class SignInWidget extends StatefulWidget {
  final SetUserFunction setUser;
  final bool appbar;

  const SignInWidget({super.key, required this.setUser, this.appbar = false});

  @override
  State<SignInWidget> createState() => SignInState();
}

class SignInState extends State<SignInWidget> {
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController dupePasswordController = TextEditingController();

  bool passwordVisible = false;
  bool creatingAccount = false;
  bool verifying = false;

  @override
  void initState() {
    super.initState();

    passwordVisible = false;
    creatingAccount = false;
    verifying = false;
  }

  void authenticate(BuildContext context) async {

    if(context.mounted) {
      User? user = await User.authenticate(
        emailController.text, passwordController.text, context);

      if (user != null) {
        widget.setUser(user);
      } else {
        if(context.mounted) {
          APIConstants.showErrorToast("Invalid email or password!", context);
        }
      }
    }
    }



  void createUser() async {
    if (passwordController.text != dupePasswordController.text) {
      APIConstants.showErrorToast("Passwords do not match!", context);
      return;
    }

    if(context.mounted) {
      bool success = await User.create(emailController.text,
          // ignore: use_build_context_synchronously
          passwordController.text, nameController.text, context);

      if (success) {
        setState(() {
          creatingAccount = false;
          verifying = true;
        });
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: widget.appbar
            ? AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                title: const Text("Settings"))
            : null,
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    !creatingAccount ? "Sign In" : "Create Account",
                    style: StyleConstants.titleStyle,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    width: 500,
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), hintText: 'Email'),
                    ),
                  ),
                  creatingAccount
                      ? SizedBox(
                          width: 500,
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Username'),
                          ),
                        )
                      : Container(),
                  SizedBox(
                    width: 500,
                    child: TextField(
                      controller: passwordController,
                      obscureText: !passwordVisible,
                      onSubmitted: (value) => {
                        if (!creatingAccount) {authenticate(context)}
                      },
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: 'Password',
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  passwordVisible = !passwordVisible;
                                });
                              },
                              icon: Icon(
                                passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inverseSurface,
                              ))),
                    ),
                  ),
                  creatingAccount
                      ? SizedBox(
                          width: 500,
                          child: TextField(
                            controller: dupePasswordController,
                            obscureText: !passwordVisible,
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: 'Repeat Password',
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        passwordVisible = !passwordVisible;
                                      });
                                    },
                                    icon: Icon(
                                      passwordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inverseSurface,
                                    ))),
                          ),
                        )
                      : Container(),
                  !verifying
                      ? SizedBox(
                          width: 500,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary),
                            child: Text(
                              !creatingAccount ? "Sign In" : "Create Account",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface),
                            ),
                            onPressed: () {
                              if (!creatingAccount) {
                                authenticate(context);
                              } else {
                                createUser();
                              }
                            },
                          ),
                        )
                      : Container(),
                  verifying
                      ? SizedBox(
                          width: 500,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary),
                            child: Text(
                              "I verified my email!",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inverseSurface),
                            ),
                            onPressed: () {
                              setState(() {
                                verifying = false;
                              });
                              authenticate(context);
                            },
                          ),
                        )
                      : Container(),
                  TextButton(
                      onPressed: () {
                        setState(() {
                          creatingAccount = !creatingAccount;
                        });
                      },
                      child: Text(
                          !creatingAccount ? "Create Account" : "Sign in")),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordpage()),
                        );
                      }, child: const Text("Forgot Password?")),
                  TextButton(
                      onPressed: () {
                        deleteAccountInfoDialog(context);
                      },
                      child: const Text("Need To Delete an Account?")),
                ],
              ),
            ),
          ),
        ));
  }

  Future<dynamic> deleteAccountInfoDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text(
              "To delete your account, please log in first. If you need assistance, please contact mosimmodloader@gmail.com."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
