import 'package:flutter/material.dart';
import 'package:sigara_defteri/features/dashboard/dashboard_screen.dart';
import 'package:sigara_defteri/features/log/log_screen.dart';
import 'package:sigara_defteri/features/quit/quit_screen.dart';
import 'package:sigara_defteri/features/settings/paywall_screen.dart';
import 'package:sigara_defteri/features/settings/settings_screen.dart';
import 'package:sigara_defteri/features/splash/splash_screen.dart';
import 'package:sigara_defteri/features/stats/stats_screen.dart';

class AppRouter {
  static const String splash = '/splash';
  static const String dashboard = '/';
  static const String log = '/log';
  static const String stats = '/stats';
  static const String settings = '/settings';
  static const String paywall = '/paywall';
  static const String quit = '/quit';

  /// Sayfa geçişi: hafif fade + sağdan kayma.
  static PageRouteBuilder<T> _fadeSlideRoute<T>(Widget page, [String? name]) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = Curves.easeOutCubic;
        final opacity = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );
        final offset = Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve));
        return FadeTransition(
          opacity: opacity,
          child: SlideTransition(position: offset, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  /// Modal (log, paywall): alttan slide + fade.
  static PageRouteBuilder<T> _modalRoute<T>(Widget page, [String? name]) {
    return PageRouteBuilder<T>(
      fullscreenDialog: true,
      settings: RouteSettings(name: name),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = Curves.easeOutCubic;
        final opacity = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: animation, curve: curve),
        );
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve));
        return FadeTransition(
          opacity: opacity,
          child: SlideTransition(position: offset, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings_) {
    switch (settings_.name) {
      case splash:
        return _fadeSlideRoute(const SplashScreen(), splash);
      case dashboard:
        return _fadeSlideRoute(const DashboardScreen(), dashboard);
      case log:
        return _modalRoute(const LogScreen(), log);
      case stats:
        return _fadeSlideRoute(const StatsScreen(), stats);
      case settings:
        return _fadeSlideRoute(const SettingsScreen(), settings);
      case paywall:
        return _modalRoute(const PaywallScreen(), paywall);
      case quit:
        return _fadeSlideRoute(const QuitScreen(), quit);
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Sayfa bulunamadı')),
          ),
        );
    }
  }
}
