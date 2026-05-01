import '../models/financial_summary.dart';

class FinanceCalculator {
  const FinanceCalculator._();

  static const double cardFeeRate = 0.07;
  static const double danielDefaultPercent = 30;
  static const double danielBaseGrossAmount = 5500;
  static const double danielBaseTotal = 1650;
  static const double danielInitialPayment = 800;
  static const double danielFinalPayment = 850;

  static double paymentFee({
    required double grossAmount,
    required String paymentMethod,
    double manualFee = 0,
  }) {
    final normalized = _normalize(paymentMethod);
    if (normalized.contains('pix')) {
      return 0;
    }

    if (normalized.contains('cartao') ||
        normalized.contains('cart') ||
        normalized.contains('card')) {
      return _money(grossAmount * cardFeeRate);
    }

    return _money(manualFee);
  }

  static FinancialSummary summarize({
    required double grossAmount,
    required double platformFee,
    required String paymentMethod,
    required bool hasDanielParticipation,
    double manualPaymentFee = 0,
    double danielPercent = danielDefaultPercent,
  }) {
    final safeGross = grossAmount.clamp(0, double.infinity).toDouble();
    final safePlatformFee = platformFee.clamp(0, double.infinity).toDouble();
    final effectivePaymentFee = paymentFee(
      grossAmount: safeGross,
      paymentMethod: paymentMethod,
      manualFee: manualPaymentFee,
    );
    final netAmount = _money(safeGross - safePlatformFee - effectivePaymentFee)
        .clamp(0, double.infinity)
        .toDouble();
    final partnerCommitment = hasDanielParticipation
        ? _money(netAmount *
            ((danielPercent <= 0 ? danielDefaultPercent : danielPercent) / 100))
        : 0.0;

    return FinancialSummary(
      grossAmount: safeGross,
      platformFee: safePlatformFee,
      paymentFee: effectivePaymentFee,
      netAmount: netAmount,
      partnerCommitment: partnerCommitment,
      ownerAmount: _money(netAmount - partnerCommitment),
    );
  }

  static double realCash({
    required Iterable<double> receivedEntries,
    required Iterable<double> expenses,
    required Iterable<double> commitments,
  }) {
    final totalEntries =
        receivedEntries.fold<double>(0, (total, value) => total + value);
    final totalExpenses =
        expenses.fold<double>(0, (total, value) => total + value);
    final totalCommitments =
        commitments.fold<double>(0, (total, value) => total + value);

    return _money(totalEntries - totalExpenses - totalCommitments);
  }

  static List<double> splitDanielDebt(double amount) {
    final initial =
        amount >= danielInitialPayment ? danielInitialPayment : _money(amount);
    final finalPayment = _money(amount - initial);
    return [
      if (initial > 0) initial,
      if (finalPayment > 0) finalPayment,
    ];
  }

  static bool get validatesDanielBaseContract {
    return _money(danielBaseGrossAmount * (danielDefaultPercent / 100)) ==
            danielBaseTotal &&
        danielInitialPayment + danielFinalPayment == danielBaseTotal;
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ã', 'a')
        .replaceAll('á', 'a')
        .replaceAll('â', 'a')
        .replaceAll('à', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  static double _money(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
