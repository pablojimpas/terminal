/*
Copyright 2020 The dahliaOS Authors
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:terminal/rgb.dart';

class TerminalApp extends StatelessWidget {
  const TerminalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terminal',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const Terminal(),
    );
  }
}

class Terminal extends StatefulWidget {
  const Terminal({Key? key}) : super(key: key);

  @override
  _TerminalState createState() => _TerminalState();
}

class _TerminalState extends State<Terminal> {
  final myController = TextEditingController();

  String output = "";
  bool yourmotherisbadstreamstate = false;

  final Future<Process> _process = Process.start('bash', []);

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  void pressEnter() {
    setState(() {
      output += "\$ ${myController.text}\n";
    });
  }

  void updateOutput(String data) {
    setState(() {
      if (kDebugMode) {
        print(data);
      }
      output += data;
    });
  }

  Widget _myWidget(BuildContext context, String myString) {
    final spans = _getSpans(myString);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15.0,
          color: Color(0xFFf2f2f2),
          fontFamily: "Cousine",
        ),
        //Theme.of(context).textTheme.body1.copyWith(fontSize: 10),
        children: spans,
      ),
    );
  }

  Color getANSI(String number, int currentShade) {
    switch (number) {
      case '30':
        return Colors.black;
      case '31':
        return Colors.red[currentShade]!;
      case '32':
        return Colors.green[currentShade]!;
      case '33':
        return Colors.yellow[currentShade]!;
      case '34':
        return Colors.blue[currentShade]!;
      case '35':
        return Colors.pink[currentShade]!;
      case '36':
        return Colors.cyan[currentShade]!;
      case '37':
        return Colors.white;
      case '40':
        return Colors.black;
      case '41':
        return Colors.red[currentShade]!;
      case '42':
        return Colors.green[currentShade]!;
      case '43':
        return Colors.yellow[currentShade]!;
      case '44':
        return Colors.blue[currentShade]!;
      case '45':
        return Colors.pink[currentShade]!;
      case '46':
        return Colors.cyan[currentShade]!;
      case '47':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  List<TextSpan> _getSpans(String text) {
    final List<TextSpan> spans = [];
    final RegExp re = RegExp(r'.\[(\?)*(\d*|\d+;\d+;\d+)([a-zA-Z])');
    int spanBoundary = 0;
    int startIndex = 0;
    int currentShade = 500;
    String currentColorCode = '37';
    String currentBackgroundColorCode = '40';
    Color currentColor = const Color(0xFFf2f2f2);
    Color? currentBackgroundColor;
    while (true) {
      startIndex = text.indexOf(re, spanBoundary);
      if (startIndex > spanBoundary) {
        spans.add(
          TextSpan(
            text: text.substring(spanBoundary, startIndex),
            style: TextStyle(
              color: currentColor,
              backgroundColor: currentBackgroundColor,
            ),
          ),
        );
      }
      if (startIndex == -1) {
        spans.add(
          TextSpan(
            text: text.substring(spanBoundary),
            style: TextStyle(
              color: currentColor,
              backgroundColor: currentBackgroundColor,
            ),
          ),
        );
        return spans;
      }
      final Match reMatch = re.firstMatch(text.substring(spanBoundary))!;
      final String match = re.stringMatch(text.substring(spanBoundary))!;
      if (reMatch.group(1) == null && reMatch.group(3) == 'm') {
        String colorCode = reMatch.group(2)!;
        switch (colorCode) {
          case '0':
          case '':
            currentShade = 500;
            currentColor = const Color(0xFFf2f2f2);
            currentBackgroundColor = null;
            break;
          case '1':
            currentShade = 300;
            currentColor = getANSI(currentColorCode, currentShade);
            break;
          default:
            if (colorCode.contains(';')) {
              final args = colorCode.split(';');
              colorCode = args[2];
              if (args[0] == '38') {
                currentColor = Color.fromRGBO(
                  rgb[int.parse(colorCode)]![0],
                  rgb[int.parse(colorCode)]![1],
                  rgb[int.parse(colorCode)]![2],
                  1.0,
                );
              } else if (args[0] == '48') {
                currentBackgroundColor = Color.fromRGBO(
                  rgb[int.parse(colorCode)]![0],
                  rgb[int.parse(colorCode)]![1],
                  rgb[int.parse(colorCode)]![2],
                  1.0,
                );
              }
            } else if (int.parse(colorCode) >= 30 &&
                int.parse(colorCode) < 38) {
              currentColorCode = colorCode;
              currentColor = getANSI(currentColorCode, currentShade);
            } else if (int.parse(colorCode) >= 40 &&
                int.parse(colorCode) < 48) {
              currentBackgroundColorCode = colorCode;
              currentBackgroundColor =
                  getANSI(currentBackgroundColorCode, currentShade);
            }
            break;
        }
      }
      final int endIndex = startIndex + match.length;
      spanBoundary = endIndex;
    }
  }

  String ps1() {
    String home = "";
    final Map<String, String> envVars = Platform.environment;
    if (Platform.isMacOS) {
      home = envVars['HOME']!;
    } else if (Platform.isLinux) {
      home = envVars['HOME']!;
    } else if (Platform.isWindows) {
      home = envVars['UserProfile']!;
    }
    final ProcessResult result = Process.runSync('uname', ['-n']);
    final hostName = result.stdout;
    final shell = "$home@$hostName:~\$";
    final multiline = shell;
    final singleline = multiline.replaceAll("\n", "");

    return singleline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222222),
      body: FutureBuilder<Process>(
        future: _process,
        builder: (BuildContext context, AsyncSnapshot<Process> snapshot) {
          List<Widget> children;
          if (snapshot.hasData) {
            final process = snapshot.data;
            if (!yourmotherisbadstreamstate) {
              process?.stdout.transform(utf8.decoder).listen((data) {
                if (kDebugMode) {
                  print(data);
                }
                updateOutput(data);
              });
              process?.stderr.transform(utf8.decoder).listen((data) {
                if (kDebugMode) {
                  print(data);
                }
                updateOutput(data);
              });
              yourmotherisbadstreamstate = true;
            }
            children = <Widget>[
              Container(
                height: 0,
                color: const Color(0xff292929),
                child: Row(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(2.0, 2.0, 2.0, 2.0),
                  child: Container(
                    alignment: Alignment.topLeft,
                    child: _myWidget(context, output),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2.0, 2.0, 2.0, 2.0),
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if (event.runtimeType.toString() == 'RawKeyDownEvent' &&
                        event.logicalKey.keyId == 4295426088) {
                      process?.stdin.writeln(myController.text);
                      pressEnter();
                      myController.clear();
                    }
                  },
                  child: TextFormField(
                    controller: myController,
                    style: const TextStyle(
                      fontSize: 15.0,
                      color: Color(0xFFf2f2f2),
                      fontFamily: "Cousine",
                    ),
                    decoration: InputDecoration.collapsed(
                      hintText: ps1(),
                      hintStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFf2f2f2),
                      ),
                    ),
                    autocorrect: false,
                    autofocus: true,
                    maxLines: null,

                    //initialValue: "debug_shell \$",
                    cursorColor: const Color(0xFFf2f2f2),
                    cursorRadius: Radius.zero,
                    cursorWidth: 10.0,
                  ),
                ),
              ),
            ];
          } else if (snapshot.hasError) {
            children = <Widget>[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ];
          } else {
            children = <Widget>[
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Loading...'),
              )
            ];
          }
          return Column(
            children: children,
          );
        },
      ),
    );
  }
}
