import 'package:flutter/material.dart';
import 'data/local_store.dart';
import 'pages/login_page.dart';
import 'theme/app_theme.dart';

Future<void> bootstrap() async {
  await LocalStore.instance.init();
}

class MarketPlaceRuralApp extends StatelessWidget {
  const MarketPlaceRuralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: bootstrap(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MarketPlace Rural',
          theme: AppTheme.light(),
          home: const LoginPage(),
        );
      },
    );
  }
}