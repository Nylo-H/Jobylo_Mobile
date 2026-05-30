import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/payment.dart';
import '../datasource/payments_remote_datasource.dart';

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(PaymentsRemoteDatasource(ref.read(dioProvider)));
});

class PaymentsRepository {
  final PaymentsRemoteDatasource _ds;
  PaymentsRepository(this._ds);

  Future<Payment> initiatePayment(String jobId) async {
    final data = await _ds.initiatePayment(jobId);
    return Payment.fromJson(data);
  }

  Future<Payment> confirmPayment(String transactionId) async {
    final data = await _ds.confirmPayment(transactionId);
    return Payment.fromJson(data);
  }

  Future<List<Payment>> getMyPayments() async {
    final data = await _ds.getMyPayments();
    return data.map(Payment.fromJson).toList();
  }
}
