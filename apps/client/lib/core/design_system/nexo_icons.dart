import 'package:flutter/material.dart';

/// Centraliza os icones do produto usando glifos Material estaveis
/// para reduzir inconsistencias de renderizacao entre web e Windows.
abstract final class NexoIcons {
  static const IconData dashboard = Icons.grid_view_rounded;
  static const IconData clients = Icons.group_rounded;
  static const IconData finance = Icons.account_balance_wallet_rounded;
  static const IconData reports = Icons.insert_chart_outlined_rounded;

  static const IconData add = Icons.add_rounded;
  static const IconData refresh = Icons.autorenew_rounded;

  static const IconData newSale = Icons.credit_card_rounded;
  static const IconData newExpense = Icons.description_rounded;
  static const IconData newClient = Icons.group_add_rounded;

  static const IconData income = Icons.call_received_rounded;
  static const IconData expense = Icons.call_made_rounded;
}
