import 'package:flutter/material.dart';
import 'package:sigara_defteri/features/dashboard/dashboard_screen.dart';
import 'package:sigara_defteri/features/log/log_screen.dart';
import 'package:sigara_defteri/features/quit/quit_screen.dart';
import 'package:sigara_defteri/features/settings/paywall_screen.dart';
import 'package:sigara_defteri/features/settings/settings_screen.dart';
import 'package:sigara_defteri/features/stats/stats_screen.dart';

class AppRouter {
  static const String dashboard = '/';
  static const String log = '/log';
  static const String stats = '/stats';
  static const String settings = '/settings';
  static const String paywall = '/paywall';
  static const String quit = '/quit';

  static Route<dynamic> onGenerateRoute(RouteSettings settings_) {
    switch (settings_.name) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case log:
        return MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const LogScreen(),
        );
      case stats:
        return MaterialPageRoute(builder: (_) => const StatsScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case paywall:
        return MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PaywallScreen(),
        );
      case quit:
        return MaterialPageRoute(builder: (_) => const QuitScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Sayfa bulunamadı')),
          ),
        );
    }
  }
}
