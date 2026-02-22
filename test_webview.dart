import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_win_floating/webview_win_floating.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  WebViewPlatform.instance = WebviewWinFloatingPlatform();
  runApp(MaterialApp(
    home: Scaffold(
      body: WebViewWidget(controller: WebViewController()..loadRequest(Uri.parse("https://flutter.dev"))),
    )
  ));
}
