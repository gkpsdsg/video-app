import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/profile_screen.dart';

// ── Douyin color tokens ──
const _red = Color(0xFFFE2C55);

// Dark surface tokens
const _dkBg = Color(0xFF000000);
const _dkS1 = Color(0xFF111111);
const _dkS2 = Color(0xFF161616);
const _dkBorder = Color(0xFF2A2A2A);

// Light surface tokens
const _ltBg = Color(0xFFFFFFFF);
const _ltS1 = Color(0xFFF8F8F8);
const _ltS2 = Color(0xFFF0F0F0);
const _ltBorder = Color(0xFFE0E0E0);

// Shared text/muted
const _textMutedDark = Color(0xFF8A8A8A);
const _textMutedLight = Color(0xFF999999);

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  ThemeNotifier() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? true;
    _mode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _mode == ThemeMode.dark);
    notifyListeners();
  }

  void setMode(ThemeMode m) {
    if (_mode != m) {
      _mode = m;
      notifyListeners();
    }
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final bg = isDark ? _dkBg : _ltBg;
  final s1 = isDark ? _dkS1 : _ltS1;
  final s2 = isDark ? _dkS2 : _ltS2;
  final border = isDark ? _dkBorder : _ltBorder;
  final muted = isDark ? _textMutedDark : _textMutedLight;
  final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

  final scheme = ColorScheme.fromSeed(
    seedColor: _red,
    brightness: brightness,
    primary: _red,
    surface: s1,
    outline: border,
    surfaceContainerHighest: s2,
  );

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    brightness: brightness,
    useMaterial3: true,
    fontFamily: 'sans-serif',
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: textColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isDark ? _dkBg : _ltBg,
      selectedItemColor: textColor,
      unselectedItemColor: muted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(44, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: s2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: TextStyle(color: muted, fontSize: 15),
    ),
    iconTheme: IconThemeData(color: textColor),
    dividerColor: border,
    cardColor: s1,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _red),
    ),
  );
}

final _navTabs = const [
  _NavTab(Icons.home_filled, Icons.home_outlined, '首页'),
  _NavTab(Icons.people, Icons.people_outline, '朋友'),
  _NavTab(Icons.add_box, Icons.add_box_outlined, ''),
  _NavTab(Icons.mail, Icons.mail_outline, '消息'),
  _NavTab(Icons.person, Icons.person_outlined, '我'),
];

class _NavTab {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavTab(this.activeIcon, this.icon, this.label);
}

void main() {
  final apiService = ApiService();
  final baseUrl = kIsWeb ? 'http://localhost:3000' : 'http://172.28.29.201:3000';
  apiService.init(baseUrl: baseUrl);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            title: '抖音',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.dark),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: themeNotifier.mode,
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/upload': (context) => const UploadScreen(),
            },
          );
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
  final _feedKey = GlobalKey<FeedScreenState>();
  final _profileKey = GlobalKey<ProfileScreenState>();

  late final _pages = [
    FeedScreen(key: _feedKey),
    const FriendsScreen(),
    const SizedBox(),
    const MessagesScreen(),
    ProfileScreen(key: _profileKey),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _dkBg : _ltBg;
    final border = isDark ? _dkBorder : _ltBorder;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            if (i == 2) {
              Navigator.of(context).pushNamed('/upload').then((_) {});
              return;
            }
            setState(() => _currentIndex = i);
            if (i == 0) {
              _feedKey.currentState?.refreshBatchStatus();
            }
            if (i == 4) {
              _profileKey.currentState?.refreshCurrentTab();
            }
          },
          items: List.generate(5, (i) {
            final tab = _navTabs[i];

            return BottomNavigationBarItem(
              icon: Icon(tab.icon, size: 24),
              activeIcon: Icon(tab.activeIcon, size: 24),
              label: tab.label,
            );
          }),
        ),
      ),
    );
  }
}
