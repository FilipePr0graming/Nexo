import 'package:flutter/foundation.dart';

import '../../../core/services/finance_calculator.dart';
import '../../../core/utils/id_generator.dart';
import '../../clients/models/client_model.dart';
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
    String? projectId,
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
      projectId: projectId,
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

  Future<int> createMissingRecurringChargesForClients({
    required List<ClientModel> clients,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final weekLimit = today.add(const Duration(days: 7));
    var created = 0;

    for (final client in clients) {
      if (!_isRecurringClient(client)) {
        continue;
      }

      final relatedSales = _sales
          .where((sale) => _belongsToClient(sale, client))
          .where((sale) =>
              sale.status != SaleStatus.canceled &&
              sale.status != SaleStatus.refunded)
          .toList(growable: false)
        ..sort(
            (left, right) => right.expectedDate.compareTo(left.expectedDate));

      if (relatedSales.isEmpty) {
        continue;
      }

      final baseSale = relatedSales.first;
      final nextDueDate = _nextDueDate(
        baseSale.expectedDate.toLocal(),
        client.billingType,
      );

      if (nextDueDate.isAfter(weekLimit) ||
          _hasChargeForDay(client, baseSale, nextDueDate)) {
        continue;
      }

      await createSale(
        clientId: client.id,
        clientName: client.name,
        serviceName: baseSale.serviceName,
        projectGroup: baseSale.projectGroup,
        serviceStage: baseSale.serviceStage,
        grossAmount: baseSale.grossAmount,
        platform: baseSale.platform,
        paymentMethod: baseSale.paymentMethod,
        installments: baseSale.installments,
        saleDate: nextDueDate.toUtc(),
        expectedDate: nextDueDate.toUtc(),
        status: _isBeforeDay(nextDueDate, today)
            ? SaleStatus.late
            : SaleStatus.pending,
        notes: 'Cobranca gerada automaticamente pela recorrencia do cliente.',
        origin: 'recorrencia',
        platformFee: baseSale.platformFee,
        paymentFee: baseSale.paymentFee,
        hasDanielParticipation: baseSale.hasDanielParticipation,
        danielPercent: baseSale.danielPercent,
      );
      created += 1;
    }

    return created;
  }

  Future<void> markAsReceived(String saleId, {DateTime? receivedDate}) async {
    final sale = _sales.cast<SaleModel?>().firstWhere(
          (item) => item?.id == saleId,
          orElse: () => null,
        );

    if (sale == null) {
      return;
    }

    final updated = sale.copyWith(
      status: SaleStatus.received,
      receivedDate: (receivedDate ?? DateTime.now()).toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    _replace(updated);
    await _repository.cacheAll(_sales);
    notifyListeners();

    try {
      final saved = await _repository.upsert(updated);
      _replace(saved);
      await _repository.cacheAll(_sales);
      _errorMessage = null;
    } catch (_) {
      _errorMessage =
          'Recebimento marcado localmente. A sincronizacao com Supabase falhou.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateSale(SaleModel sale) async {
    final summary = FinanceCalculator.summarize(
      grossAmount: sale.grossAmount,
      platformFee: sale.platformFee,
      paymentMethod: sale.paymentMethod,
      manualPaymentFee: sale.paymentFee,
      hasDanielParticipation: sale.hasDanielParticipation,
      danielPercent: sale.danielPercent,
    );
    final updated = sale.copyWith(
      paymentFee: summary.paymentFee,
      netAmount: summary.netAmount,
      danielPercent: sale.hasDanielParticipation ? sale.danielPercent : 0,
      danielValue: summary.partnerCommitment,
      ownerAmount: summary.ownerAmount,
      updatedAt: DateTime.now().toUtc(),
    );

    _replace(updated);
    await _repository.cacheAll(_sales);
    notifyListeners();

    try {
      final saved = await _repository.upsert(updated);
      _replace(saved);
      await _repository.cacheAll(_sales);
      _errorMessage = null;
    } catch (_) {
      _errorMessage =
          'Venda atualizada localmente. A sincronizacao com Supabase falhou.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteSale(String id) async {
    final previous = _sales;
    _sales = _sales.where((sale) => sale.id != id).toList(growable: false);
    await _repository.cacheAll(_sales);
    notifyListeners();

    try {
      await _repository.deleteById(id);
      _errorMessage = null;
    } catch (_) {
      _sales = previous;
      await _repository.cacheAll(_sales);
      _errorMessage = 'Nao foi possivel excluir venda agora.';
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

  static bool _isRecurringClient(ClientModel client) {
    return (client.status == ClientStatus.active ||
            client.status == ClientStatus.inProgress) &&
        client.billingType != ClientBillingType.oneOff;
  }

  static bool _belongsToClient(SaleModel sale, ClientModel client) {
    if (sale.clientId != null && sale.clientId == client.id) {
      return true;
    }

    return sale.clientName.trim().toLowerCase() ==
        client.name.trim().toLowerCase();
  }

  bool _hasChargeForDay(
    ClientModel client,
    SaleModel baseSale,
    DateTime dueDate,
  ) {
    return _sales.any((sale) {
      return _belongsToClient(sale, client) &&
          sale.serviceName.trim().toLowerCase() ==
              baseSale.serviceName.trim().toLowerCase() &&
          _sameDay(sale.expectedDate.toLocal(), dueDate);
    });
  }

  static DateTime _nextDueDate(
    DateTime date,
    ClientBillingType billingType,
  ) {
    return switch (billingType) {
      ClientBillingType.monthly => _addMonths(date, 1),
      ClientBillingType.annual => _addMonths(date, 12),
      ClientBillingType.oneOff => date,
    };
  }

  static DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month + months;
    final targetYear = date.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final maxDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
    final targetDay = date.day > maxDay ? maxDay : date.day;

    return DateTime(
      targetYear,
      normalizedMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static bool _sameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static bool _isBeforeDay(DateTime value, DateTime day) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    final dayOnly = DateTime(day.year, day.month, day.day);
    return dateOnly.isBefore(dayOnly);
  }
}
