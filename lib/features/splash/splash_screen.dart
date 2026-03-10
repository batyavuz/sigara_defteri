import 'package:flutter/material.dart';
import 'package:sigara_defteri/app/router.dart';
import 'package:sigara_defteri/shared/theme/app_theme.dart';

/// Uygulama açılışında gösterilen splash ekranı.
/// Logo, başlık ve "Uygulamaya devam et" butonu ile ana ekrana geçiş.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _titleController;
  late AnimationController _buttonController;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutCubic,
    ));
    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _titleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _titleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _goToApp() {
    Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  );
                },
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 140,
                  width: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.smoking_rooms_rounded,
                    size: 100,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _titleController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _titleOpacity.value,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: child,
                    ),
                  );
                },
                child: const Text(
                  'Sigara Defteri',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _titleController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _titleOpacity.value,
                    child: child,
                  );
                },
                child: Text(
                  'Yargılamadan takip et.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _buttonController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _buttonOpacity.value,
                    child: child,
                  );
                },
                child: FilledButton(
                  onPressed: _goToApp,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Uygulamaya devam et'),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
