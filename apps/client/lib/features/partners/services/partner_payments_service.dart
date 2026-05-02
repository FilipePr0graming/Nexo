import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/nexo_table_service.dart';
import '../../../core/storage/local_json_store.dart';
import '../models/partner_model.dart';
import '../models/partner_payment_model.dart';

class PartnerPaymentsService extends ChangeNotifier {
  PartnerPaymentsService({
    required SupabaseClient? client,
    required LocalJsonStore localStore,
  })  : _partners = NexoTableService<PartnerModel>(
          client: client,
          localStore: localStore,
          table: 'partners',
          storageKey: 'nexo.cache.partners',
          fromJson: PartnerModel.fromJson,
          toJson: (partner) => partner.toJson(),
          idOf: (partner) => partner.id,
          orderBy: 'name',
          ascending: true,
          syncErrorMessage: 'Nao foi possivel sincronizar parceiros agora.',
          sort: (left, right) => left.name.compareTo(right.name),
        ),
        _payments = NexoTableService<PartnerPaymentModel>(
          client: client,
          localStore: localStore,
          table: 'partner_payments',
          storageKey: 'nexo.cache.partner_payments',
          fromJson: PartnerPaymentModel.fromJson,
          toJson: (payment) => payment.toJson(),
          idOf: (payment) => payment.id,
          orderBy: 'due_date',
          ascending: true,
          syncErrorMessage:
              'Nao foi possivel sincronizar pagamentos de parceiros agora.',
          sort: (left, right) => left.dueDate.compareTo(right.dueDate),
        ) {
    _partners.addListener(notifyListeners);
    _payments.addListener(notifyListeners);
  }

  final NexoTableService<PartnerModel> _partners;
  final NexoTableService<PartnerPaymentModel> _payments;

  List<PartnerModel> get partners => _partners.items;
  List<PartnerPaymentModel> get payments => _payments.items;
  bool get isLoading => _partners.isLoading || _payments.isLoading;
  bool get isSyncing => _partners.isSyncing || _payments.isSyncing;
  String? get errorMessage => _partners.errorMessage ?? _payments.errorMessage;

  PartnerModel? get daniel {
    return partners.cast<PartnerModel?>().firstWhere(
          (partner) => partner?.name.trim().toLowerCase() == 'daniel',
          orElse: () => null,
        );
  }

  List<PartnerPaymentModel> get openDanielPayments {
    final partner = daniel;
    if (partner == null) {
      return const [];
    }
    return payments
        .where(
          (payment) =>
              payment.partnerId == partner.id &&
              payment.status == PartnerPaymentStatus.open,
        )
        .toList(growable: false);
  }

  Future<void> initialize() async {
    await Future.wait<void>([
      _partners.initialize(),
      _payments.initialize(),
    ]);
  }

  Future<void> refresh() async {
    await Future.wait<void>([
      _partners.refresh(),
      _payments.refresh(),
    ]);
  }

  Future<void> markAsPaid(PartnerPaymentModel payment) {
    return _payments.upsertItem(
      payment.copyWith(
        status: PartnerPaymentStatus.paid,
        paidAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> deletePayment(String id) => _payments.deleteById(id);

  @override
  void dispose() {
    _partners
      ..removeListener(notifyListeners)
      ..dispose();
    _payments
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
