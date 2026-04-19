import 'deep_link_launcher_stub.dart'
    if (dart.library.html) 'deep_link_launcher_web.dart';

Future<void> tryLaunchDeepLink(String url) => tryLaunchDeepLinkImpl(url);
