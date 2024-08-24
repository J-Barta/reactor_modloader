import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:mosim_modloader/util/constants.dart';
import 'package:mosim_modloader/util/api_session.dart';

class ForgotPasswordpage extends StatefulWidget {
  const ForgotPasswordpage({super.key});

  @override
  State<ForgotPasswordpage> createState() => _ForgotPasswordpageState();
}

class _ForgotPasswordpageState extends State<ForgotPasswordpage> {
  TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                width: 400,
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    hintText: "Enter your email",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Response response = await APISession.post(
                        "/user/resetPasswordEmail", jsonEncode({"email": emailController.text}));

                    if (response.statusCode == 200) {
                      if (context.mounted) {
                        APIConstants.showSuccessToast(
                            "Reset email success",
                            context);
                      }
                    } else {
                      if (context.mounted) {
                        APIConstants.showErrorToast(
                            "Reset email failed: ${response.statusCode} - ${response.body}",
                            context);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.inversePrimary),
                  child: Text(
                    "Send Reset Email",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.inverseSurface),
                  ),
                ),
              ),
              const Text(
                  "If you have an account with us, we will send you an email with instructions on how to reset your password."),
              const Text(
                  "If you forgot your email, contact shamparts5907@gmail.com for help."),
            ],
          ),
        ),
      ),
    );
  }
}
