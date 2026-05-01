class FinancialSummary {
  const FinancialSummary({
    required this.grossAmount,
    required this.platformFee,
    required this.paymentFee,
    required this.netAmount,
    required this.partnerCommitment,
    required this.ownerAmount,
  });

  final double grossAmount;
  final double platformFee;
  final double paymentFee;
  final double netAmount;
  final double partnerCommitment;
  final double ownerAmount;
}
