// ignore_for_file: prefer_const_constructors, sort_child_properties_last

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(child: WebViewExample()),
      ),
    );
  }
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WebViewExampleState createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  final textController = TextEditingController();
  String urlString = "";

  late final WebViewController controller;
  List<String> emailAddresses = [];
  List<String> phoneNumbers = [];
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    // #docregion webview_controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));

    shareFromOtherApp();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: TextFormField(
                        controller: textController,
                        style: TextStyle(color: Colors.black),
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                            suffixIcon: InkWell(
                                onTap: () {
                                  textController.text = "";
                                },
                                child: Icon(Icons.close)),
                            constraints: BoxConstraints.expand(height: 50),
                            label: Text("insert the url of webpage",
                                style: TextStyle()),
                            labelStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey)),
                            floatingLabelBehavior: FloatingLabelBehavior.never),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        submitData();
                      },
                      child: Text("Submit",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(Colors.blue),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'List of available emails',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              emailAddresses.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "No email addresses found on this page.",
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (BuildContext ctx, index) {
                              return OutlinedButton(
                                onPressed: () {
                                  showEmailAlertDialog(
                                      emailAddresses[index], context);
                                },
                                child: Text(
                                  emailAddresses[index],
                                  style: TextStyle(color: Colors.green),
                                ),
                              );
                            },
                            separatorBuilder: (BuildContext ctx, index) {
                              return SizedBox(
                                width: 10,
                              );
                            },
                            itemCount: emailAddresses.length),
                      ),
                    ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'List of available phone numbers',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              phoneNumbers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "No phone numbers found on this page.",
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (BuildContext ctx, index) {
                              return OutlinedButton(
                                onPressed: () {},
                                child: Text(
                                  phoneNumbers[index],
                                  style: TextStyle(color: Colors.green),
                                ),
                              );
                            },
                            separatorBuilder: (BuildContext ctx, index) {
                              return SizedBox(
                                width: 10,
                              );
                            },
                            itemCount: phoneNumbers.length),
                      ),
                    ),
            ],
          ),
        ),
        Expanded(
          child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black)),
              child: WebViewWidget(
                controller: controller,
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<VerticalDragGestureRecognizer>(
                    () => VerticalDragGestureRecognizer(),
                  ),
                  Factory<HorizontalDragGestureRecognizer>(
                      () => HorizontalDragGestureRecognizer())
                },
              )),
        ),
      ],
    );
  }

  List<String> extractEmailAddresses(String input) {
    RegExp emailRegExp =
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    Iterable<RegExpMatch> matches = emailRegExp.allMatches(input);

    List<String> emailAddresses = [];

    for (RegExpMatch match in matches) {
      emailAddresses.add(match.group(0)!);
    }

    return emailAddresses;
  }

  List<String> extractPhoneNumbers(String input) {
    // Regular expression to match phone numbers
    RegExp phoneRegExp =
        RegExp(r'(\+?\d{1,2}\s?)?(\(\d{3}\)|\d{3})[-.\s]?\d{3}[-.\s]?\d{4}');

    // Find all matches in the input string
    Iterable<RegExpMatch> matches = phoneRegExp.allMatches(input);

    // Extract matched phone numbers
    List<String> phoneNumbers =
        matches.map((match) => match.group(0)!).toList();

    return phoneNumbers;
  }

  // Add this function to show a Cupertino Alert Dialog
  void showEmailAlertDialog(String email, BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Open Email App'),
          content: Text(
              'On clicking OK you will be redirected to default email application'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                openEmailApp(email);
              },
              child: Text('OK'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Add this function to open the email app
  void openEmailApp(String email) async {
    final Uri _emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(Uri.parse(_emailLaunchUri.toString()))) {
      await launchUrl(Uri.parse(_emailLaunchUri.toString()));
    } else {
      throw 'Could not launch $_emailLaunchUri';
    }
  }

  void shareFromOtherApp() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      setState(() {
        urlString = value;
        textController.text = urlString;
        submitData();
        print("Shared inside app: $urlString");
      });
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (value != null) {
        setState(() {
          urlString = value.toString();
          textController.text = urlString;
          submitData();
          print("Shared outside app: $urlString");
        });
      }
    });
  }

  void submitData() {
    FocusManager.instance.primaryFocus?.unfocus();
    urlString = textController.text;
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'http://$urlString'; // Add a default scheme if missing
    }

    controller.loadRequest(Uri.parse(urlString));
    controller.setNavigationDelegate(NavigationDelegate(
      onProgress: (int progress) {
        // Update loading bar.
        CircularProgressIndicator();
      },
      onPageStarted: (String url) {},
      onPageFinished: (String url) {
        // Once the web page is finished loading,
        // execute JavaScript to get the text content.

        Future<Object> text = controller
            .runJavaScriptReturningResult('document.body.textContent');

        text.then((value) {
          emailAddresses = extractEmailAddresses(value.toString());
          print('Email Addresses: $emailAddresses');
          phoneNumbers = extractPhoneNumbers(value.toString());
          print('Phone Numbers: $phoneNumbers');

          setState(() {});
        });
        setState(() {});
      },
      onWebResourceError: (WebResourceError error) {
        print("error while loading $error");
      },
    ));
  }
}
