import 'package:flutter/foundation.dart';

import '../../../core/services/finance_calculator.dart';
import '../../../core/utils/id_generator.dart';
import '../data/repositories/sales_repository.dart';
import '../models/sale_model.dart';

class SalesService extends ChangeNotifier {
  SalesService(this._repository);

  final SalesRepository _repository;

  List<SaleModel> _sales = const [];
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _initialized = false;
  String? _errorMessage;

  List<SaleModel> get sales => _sales;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _isLoading = true;
    notifyListeners();

    _sales = await _repository.loadLocal();
    _isLoading = false;
    notifyListeners();

    await refresh();
  }

  Future<void> refresh() async {
    if (_isSyncing || !_repository.isRemoteEnabled) {
      return;
    }

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sales = await _repository.refreshFromRemote();
    } catch (_) {
      _errorMessage = 'Nao foi possivel atualizar vendas agora.';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> createSale({
    String? clientId,
    required String clientName,
    required String serviceName,
    String? projectGroup,
    String? serviceStage,
    required double grossAmount,
    required String platform,
    required String paymentMethod,
    required int installments,
    required DateTime saleDate,
    required DateTime expectedDate,
    DateTime? receivedDate,
    required SaleStatus status,
    String? notes,
    String? origin,
    required double platformFee,
    required double paymentFee,
    required bool hasDanielParticipation,
    required double danielPercent,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final summary = FinanceCalculator.summarize(
      grossAmount: grossAmount,
      platformFee: platformFee,
      paymentMethod: paymentMethod,
      manualPaymentFee: paymentFee,
      hasDanielParticipation: hasDanielParticipation,
      danielPercent: danielPercent,
    );

    final sale = SaleModel(
      id: IdGenerator.next('sale'),
      clientId: clientId,
      clientName: clientName.trim(),
      serviceName: serviceName.trim(),
      projectGroup: _emptyToNull(projectGroup),
      serviceStage: _emptyToNull(serviceStage),
      grossAmount: grossAmount,
      platform: platform,
      paymentMethod: paymentMethod,
      installments: installments,
      saleDate: saleDate,
      expectedDate: expectedDate,
      receivedDate: receivedDate,
      status: status,
      notes: _emptyToNull(notes),
      origin: _emptyToNull(origin),
      platformFee: platformFee,
      paymentFee: summary.paymentFee,
      netAmount: summary.netAmount,
      hasDanielParticipation: hasDanielParticipation,
      danielPercent: hasDanielParticipation
          ? (danielPercent <= 0
              ? FinanceCalculator.danielDefaultPercent
              : danielPercent)
          : 0,
      danielValue: summary.partnerCommitment,
      ownerAmount: summary.ownerAmount,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    _sales = [sale, ..._sales]..sort(_sortByMovementDate);
    await _repository.cacheAll(_sales);
    notifyListeners();

    try {
      final saved = await _repository.upsert(sale);
      _replace(saved);
      await _repository.cacheAll(_sales);
      _errorMessage = null;
    } catch (_) {
      _errorMessage =
          'Venda salva localmente. A sincronizacao com Supabase falhou.';
    } finally {
      notifyListeners();
    }
  }

  int _sortByMovementDate(SaleModel left, SaleModel right) {
    return right.movementDate.compareTo(left.movementDate);
  }

  void _replace(SaleModel updated) {
    _sales = _sales
        .map((sale) => sale.id == updated.id ? updated : sale)
        .toList(growable: false)
      ..sort(_sortByMovementDate);
  }

  static String? _emptyToNull(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
