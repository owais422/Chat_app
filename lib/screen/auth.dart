import 'dart:io';

import 'package:chat_app/screen/phone_auth.dart';
import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formkey = GlobalKey<FormState>();
  String enteredEmail = '';
  String enteredUserName = '';

  String enteredPassword = '';
  File? _selectedImage;
  bool _islogin = true;
  bool isAuthentication = false;
  void _submit() async {
    final isValid = _formkey.currentState!.validate();

    if (!isValid) {
      return;
    }
    if (!_islogin && _selectedImage == null) {
      return;
    }
    _formkey.currentState!.save();

    if (_islogin) {
      try {
        setState(() {
          isAuthentication = !isAuthentication;
        });
        final userCredential = await _firebase.signInWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );
        print(userCredential);
      } on FirebaseAuthException catch (error) {
        if (error.code != "user-not-found") {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).clearSnackBars();
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message ?? "Email Already use"),
            ),
          );
          setState(() {
            isAuthentication = !isAuthentication;
          });
        }
      }
    } else {
      try {
        setState(() {
          isAuthentication = !isAuthentication;
        });
        final userCredential = await _firebase.createUserWithEmailAndPassword(
            email: enteredEmail, password: enteredPassword);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child("user_images")
            .child("${userCredential.user!.uid}.jpg");
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          "username": enteredUserName,
          'email': enteredEmail,
          'image_url': imageUrl
        });
      } on FirebaseAuthException catch (error) {
        if (error.code == "email-already-in-use") {
          ///..///
        }
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).clearSnackBars();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? "Authentication failed"),
          ),
        );
        setState(() {
          isAuthentication = !isAuthentication;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                width: 200,
                child: Image.asset(
                  'assets/images/chat.png',
                ),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    child: Form(
                      key: _formkey,
                      child: Column(
                        children: [
                          if (!_islogin)
                            UserImagePicker(
                              onPickedImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Email Address",
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains("@")) {
                                return "Please enter valid email address";
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              enteredEmail = newValue!;
                            },
                          ),
                          if (!_islogin)
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "User Name",
                              ),
                              enableSuggestions: false,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    value.length < 4) {
                                  return "Please enter atleast 4 character";
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                enteredUserName = newValue!;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 8) {
                                return "Password must have atleast 8 character";
                              }
                              return null;
                            },
                            onSaved: (newValue) {
                              enteredPassword = newValue!;
                            },
                            obscureText: true,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          if (isAuthentication)
                            const CircularProgressIndicator(),
                          if (!isAuthentication)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer),
                              onPressed: _submit,
                              child: Text(_islogin ? "Login" : "Signup"),
                            ),
                          if (!isAuthentication)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _islogin = !_islogin;
                                });
                              },
                              child: _islogin
                                  ? const Text("Create a new account")
                                  : const Text("I already have an account"),
                            ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PhoneAuth(),
                                  ));
                            },
                            child: const Text("SignIn Using Phone Number"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
