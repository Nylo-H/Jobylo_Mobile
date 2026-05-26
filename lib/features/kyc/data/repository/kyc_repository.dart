import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../datasource/kyc_remote_datasource.dart';
import '../../domain/entities/kyc_document.dart';

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepository(KycRemoteDatasource(ref.read(dioProvider)));
});

class KycRepository {
  final KycRemoteDatasource _datasource;
  KycRepository(this._datasource);

  Future<KycDocument> uploadDocument({
    required String filePath,
    required String documentType,
  }) async {
    final data = await _datasource.uploadDocument(
      filePath: filePath,
      documentType: documentType,
    );
    return KycDocument.fromJson(data);
  }

  Future<KycDocument?> getStatus() async {
    try {
      final data = await _datasource.getStatus();
      return KycDocument.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
