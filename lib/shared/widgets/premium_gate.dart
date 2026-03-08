import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sigara_defteri/services/premium_service.dart';

/// Premium gerektiren içeriği sarar.
/// isPremium → child gösterilir.
/// free → fallback gösterilir (null ise SizedBox.shrink).
class PremiumGate extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const PremiumGate({required this.child, this.fallback, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumProvider).isPremium;
    if (isPremium) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
