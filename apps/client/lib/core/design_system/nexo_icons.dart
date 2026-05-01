import 'package:flutter/material.dart';

/// Centraliza os icones do produto usando glifos Material estaveis
/// para reduzir inconsistencias de renderizacao entre web e Windows.
abstract final class NexoIcons {
  static const IconData dashboard = Icons.grid_view_rounded;
  static const IconData home = Icons.home_rounded;
  static const IconData company = Icons.business_center_rounded;
  static const IconData clients = Icons.group_rounded;
  static const IconData projects = Icons.account_tree_rounded;
  static const IconData finance = Icons.account_balance_wallet_rounded;
  static const IconData receipts = Icons.payments_rounded;
  static const IconData expenses = Icons.receipt_long_rounded;
  static const IconData partners = Icons.handshake_rounded;
  static const IconData subscriptions = Icons.event_repeat_rounded;
  static const IconData planning = Icons.event_note_rounded;
  static const IconData goals = Icons.ads_click_rounded;
  static const IconData intelligence = Icons.psychology_rounded;
  static const IconData notes = Icons.edit_note_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData reports = Icons.insert_chart_outlined_rounded;

  static const IconData add = Icons.add_rounded;
  static const IconData refresh = Icons.autorenew_rounded;

  static const IconData newSale = Icons.credit_card_rounded;
  static const IconData newExpense = Icons.description_rounded;
  static const IconData newClient = Icons.group_add_rounded;

  static const IconData income = Icons.call_received_rounded;
  static const IconData expense = Icons.call_made_rounded;
}
