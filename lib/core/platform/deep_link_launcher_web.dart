// ignore_for_file: avoid_web_libraries_in_flutter
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<void> tryLaunchDeepLinkImpl(String url) async {
  final iframe =
      html.IFrameElement()
        ..style.display = 'none'
        ..src = url;

  html.document.body?.append(iframe);

  await Future<void>.delayed(const Duration(milliseconds: 1200));
  iframe.remove();
}
