import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:chatapp/Screens/chat_screen.dart';
import 'package:chatapp/Screens/network_services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;

class LoginScreen extends StatefulWidget {
  final NetworkService? networkService;
  const LoginScreen({
    Key? key,
    required this.networkService,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  ScreenshotController screenshotController = ScreenshotController();
  // final controller = StreamController();
  // ScreenShot screenShot

  final formKey = GlobalKey<FormState>();
  Uint8List? imageFile;

  shareImage() async {
    // print('object');
    setState(() {
      isLoading = true;
    });
    screenshotController.capture().then((Uint8List? image) {
      setState(() {
        imageFile = image;
      });
    }).then((value) async {
      // setState(() {
      //   isLoading = true;
      // });
      img.Image image = img.decodeImage(imageFile!)!;

      // Save the Image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/temp_image.png').create();
      await file.writeAsBytes(img.encodePng(image));

      // Convert the temporary file to XFile
      // XFile xFile = XFile(file.path);

      // print(file.path);
      // setState(() {
      //   isLoading = false;
      // });

      await Share.shareFiles([file.path]);
      // print('done');
    }).catchError((onError) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(onError)));
      // print(onError);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: shareImage,
          child: Text(isLoading ? 'L' : 'D'),
        ),
        body: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Username'),
              TextFormField(
                controller: usernameController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Enter a value';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Enter a value';
                  }
                  return null;
                },
              ),
              MaterialButton(
                height: 300,
                child: const Text('Login'),
                onPressed: () async {
                  print('object');
                  if (formKey.currentState!.validate()) {
                    // print('object');
                    final user = await widget.networkService!.login(
                        usernameController.text,
                        passwordController.text,
                        context);

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                              networkService: widget.networkService!,
                              user: user),
                        ),
                      );
                    }
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
