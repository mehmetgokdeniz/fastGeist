import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'core/navigation/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'di/injection_container.dart' as di;
import 'presentation/providers/message_provider.dart';
import 'presentation/providers/qr_provider.dart';
import 'presentation/providers/qr_scanner_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/user_profile_provider.dart';
import 'presentation/providers/scan_history_provider.dart';
import 'presentation/providers/authentication_provider.dart';
import 'data/services/hive_service.dart';
import 'view/screens/splash_screen.dart';
import 'view/screens/profile_creation_screen.dart';
import 'view/screens/profile_detail_screen.dart';
import 'view/screens/home_screen.dart';
import 'view/screens/message_screen.dart';
import 'view/screens/qr_screen.dart';
import 'view/screens/search_history_screen.dart';
import 'view/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Web'de Hive desteği farklı
    if (!kIsWeb) {
      await HiveService.initialize();
    } else {
      debugPrint(
        'Web platformu: Hive geçici almıyor (SharedPreferences kullanılıyor)',
      );
    }
    await di.setupDependencies();
  } catch (e) {
    debugPrint('Initialization error: $e');
    // Hata olsa bile devam et
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _routeWidget(String? name) {
    switch (name) {
      case '/splash':
        return const SplashScreen();
      case '/profile':
        return const ProfileCreationScreen();
      case '/profile-detail':
        return const ProfileDetailScreen();
      case '/':
        return const HomeScreen();
      case '/message':
        return const MessageScreen();
      case '/qr':
        return const QRScreen();
      case '/history':
        return const SearchHistoryScreen();
      case '/settings':
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  Route<dynamic> _buildRoute(RouteSettings settings, {required bool fast}) {
    final page = _routeWidget(settings.name);

    if (!fast) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => page,
      );
    }

    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 170),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => di.getIt<MessageProvider>()),
        ChangeNotifierProvider(create: (_) => di.getIt<QRProvider>()),
        ChangeNotifierProvider(create: (_) => di.getIt<QRScannerProvider>()),
        ChangeNotifierProvider(create: (_) => di.getIt<UserProfileProvider>()),
        ChangeNotifierProvider(create: (_) => di.getIt<ScanHistoryProvider>()),
        ChangeNotifierProvider(
          create: (_) => di.getIt<AuthenticationProvider>(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // ThemeProvider initialize olmadan bekle
          if (!themeProvider.isInitialized) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp(
            title: 'FastGokdeniz',
            theme: themeProvider.isGlassMode
                ? AppTheme.glassTheme
                : AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              if (!themeProvider.isGlassMode || child == null) {
                return child ?? const SizedBox.shrink();
              }
              return _GlassBackgroundShell(child: child);
            },
            navigatorKey: NavigationService.navigatorKey,
            initialRoute: '/splash',
            onGenerateRoute: (settings) => _buildRoute(
              settings,
              fast: themeProvider.isGlassMode,
            ),
            onUnknownRoute: (settings) => _buildRoute(
              const RouteSettings(name: '/'),
              fast: themeProvider.isGlassMode,
            ),
          );
        },
      ),
    );
  }
}

class _GlassBackgroundShell extends StatelessWidget {
  const _GlassBackgroundShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: _GlassBackdrop()),
        child,
      ],
    );
  }
}

class _GlassBackdrop extends StatelessWidget {
  const _GlassBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF87D6E8), Color(0xFFA2C8F7), Color(0xFF9EDCF4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const Positioned(
            top: -40,
            right: -30,
            child: _GlassBlob(
              size: 220,
              color: Color(0x574F8EEB),
            ),
          ),
          const Positioned(
            bottom: -50,
            left: -30,
            child: _GlassBlob(
              size: 260,
              color: Color(0x4DA7F0FF),
            ),
          ),
          const Positioned(
            top: 180,
            left: 30,
            child: _GlassBlob(
              size: 130,
              color: Color(0x40FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBlob extends StatelessWidget {
  const _GlassBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.30),
            color,
            color.withValues(alpha: 0.06),
          ],
          stops: const [0.0, 0.62, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 26,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
