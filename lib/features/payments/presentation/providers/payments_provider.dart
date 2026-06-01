import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/payments_repository.dart';
import '../../domain/entities/payment.dart';

// ── All my transactions (loaded once, cached 30s) ─────────────────────────
final myPaymentsProvider =
    AsyncNotifierProvider<MyPaymentsNotifier, List<Payment>>(
  MyPaymentsNotifier.new,
);

class MyPaymentsNotifier extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() =>
      ref.read(paymentsRepositoryProvider).getMyPayments();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(paymentsRepositoryProvider).getMyPayments());
  }

  // Ajoute un paiement directement sans re-fetch réseau
  void addPayment(Payment payment) {
    final current = state.valueOrNull ?? [];
    if (current.any((p) => p.id == payment.id)) return;
    state = AsyncData([...current, payment]);
  }

  // Met à jour un paiement existant directement
  void updatePayment(Payment payment) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((p) => p.id == payment.id ? payment : p).toList(),
    );
  }
}

// ── Payment status for a specific job ─────────────────────────────────────
/// Returns the transaction for [jobId], or null if none exists.
final jobPaymentProvider = Provider.family<Payment?, String>((ref, jobId) {
  final payments = ref.watch(myPaymentsProvider).valueOrNull ?? [];
  try {
    return payments.firstWhere((p) => p.jobId == jobId);
  } catch (_) {
    return null;
  }
});
