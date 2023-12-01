// ignore_for_file: prefer_const_constructors, sort_child_properties_last

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

  @override
  void initState() {
    // #docregion webview_controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    FocusManager.instance.primaryFocus?.unfocus();
                    urlString = textController.text;
                    if (!urlString.startsWith('http://') &&
                        !urlString.startsWith('https://')) {
                      urlString =
                          'http://$urlString'; // Add a default scheme if missing
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

                        Future<Object> text =
                            controller.runJavaScriptReturningResult(
                                'document.body.textContent');

                        text.then((value) {
                          emailAddresses =
                              extractEmailAddresses(value.toString());
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
                  },
                  child: Text("Submit",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
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
            height: 30,
          ),
          Container(
              height: 500,
              width: double.infinity,
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black)),
              child: WebViewWidget(
                controller: controller,
                gestureRecognizers: Set()
                  ..add(Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer())),
              )),
          SizedBox(
            height: 40,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'List of available emails',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext ctx, index) {
                    return OutlinedButton(
                      onPressed: () {},
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
            height: 40,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'List of available phone numbers',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
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
          SizedBox(
            height: 80,
          ),
        ],
      ),
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
}
