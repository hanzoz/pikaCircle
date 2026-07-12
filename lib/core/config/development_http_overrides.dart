import 'dart:io';

import 'package:flutter/foundation.dart';

class DevelopmentHttpOverrides extends HttpOverrides {
  DevelopmentHttpOverrides({required this.allowedHost});

  final String allowedHost;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (certificate, host, port) {
      final isAllowedDevelopmentHost = host == allowedHost;
      if (isAllowedDevelopmentHost) {
        debugPrint(
          'Allowing development TLS certificate for $host. '
          'Fix the server certificate before release.',
        );
      }
      return isAllowedDevelopmentHost;
    };
    return client;
  }
}

void installDevelopmentHttpOverrides({required Uri endpoint}) {
  if (kReleaseMode || kIsWeb) {
    return;
  }

  HttpOverrides.global = DevelopmentHttpOverrides(allowedHost: endpoint.host);
}
