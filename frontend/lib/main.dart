import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/profile_screen.dart';

// ── OLED Dark color tokens ──
const _black = Color(0xFF000000);
const _surface1 = Color(0xFF0C0C0C);
const _surface2 = Color(0xFF1A1A1A);
const _surface3 = Color(0xFF262626);
const _violet500 = Color(0xFF8B5CF6);
const _textMuted = Color(0xFF71717A);

final _darkScheme = ColorScheme.dark(
  surface: _surface1,
  primary: _violet500,
  onSurface: Colors.white,
  outline: _surface3,
  surfaceContainerHighest: _surface2,
);

void main() {
  final apiService = ApiService();
  final baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  apiService.init(baseUrl: baseUrl);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: '短视频',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: _darkScheme,
          scaffoldBackgroundColor: _black,
          brightness: Brightness.dark,
          useMaterial3: true,
          fontFamily: 'sans-serif',
          appBarTheme: const AppBarTheme(
            backgroundColor: _black,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: _black,
            selectedItemColor: Colors.white,
            unselectedItemColor: _textMuted,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: _violet500,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(44, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: _surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _violet500, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/upload': (context) => const UploadScreen(),
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [FeedScreen(), SizedBox(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _surface3, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            if (i == 1) {
              Navigator.of(context).pushNamed('/upload').then((_) {});
              return;
            }
            setState(() => _currentIndex = i);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 22), label: '首页'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined, size: 22), label: '上传'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 22), label: '我的'),
          ],
        ),
      ),
    );
  }
}
