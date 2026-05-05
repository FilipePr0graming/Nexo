import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/clients/services/clients_service.dart';
import '../../features/clients/services/client_autofill_service.dart';
import '../../features/finance/services/expenses_service.dart';
import '../../features/finance/services/sales_service.dart';
import '../../features/goals/services/goals_service.dart';
import '../../features/notes/services/notes_service.dart';
import '../../features/partners/services/partner_payments_service.dart';
import '../../features/projects/services/projects_service.dart';
import '../../features/reminders/services/reminders_service.dart';
import '../services/supabase_service.dart';
import '../services/nexo_intelligence_service.dart';

class AppServices {
  AppServices({
    required this.supabase,
    required this.clients,
    required this.clientAutofill,
    required this.sales,
    required this.expenses,
    required this.projects,
    required this.goals,
    required this.reminders,
    required this.notes,
    required this.partnerPayments,
    required this.intelligence,
    required this.supabaseEnabled,
  });

  final SupabaseService supabase;
  final ClientsService clients;
  final ClientAutofillService clientAutofill;
  final SalesService sales;
  final ExpensesService expenses;
  final ProjectsService projects;
  final GoalsService goals;
  final RemindersService reminders;
  final NotesService notes;
  final PartnerPaymentsService partnerPayments;
  final NexoIntelligenceService intelligence;
  final bool supabaseEnabled;

  final List<RealtimeChannel> _channels = <RealtimeChannel>[];
  final Map<String, Timer> _refreshTimers = <String, Timer>{};
  bool _realtimeStarted = false;

  Future<void> initialize() async {
    await clients.initialize();
    await Future.wait<void>([
      sales.initialize(),
      expenses.initialize(),
      projects.initialize(),
      goals.initialize(),
      reminders.initialize(),
      notes.initialize(),
      partnerPayments.initialize(),
    ]);
    await sales.createMissingRecurringChargesForClients(
      clients: clients.clients,
    );
    _startRealtimeIfPossible();
  }

  Future<void> refreshRemoteData() async {
    await clients.refresh();
    await Future.wait<void>([
      sales.refresh(),
      expenses.refresh(),
      projects.refresh(),
      goals.refresh(),
      reminders.refresh(),
      notes.refresh(),
      partnerPayments.refresh(),
    ]);
    await sales.createMissingRecurringChargesForClients(
      clients: clients.clients,
    );
    _startRealtimeIfPossible();
  }

  void _startRealtimeIfPossible() {
    final client = supabase.client;
    if (!supabaseEnabled ||
        client == null ||
        supabase.currentUser == null ||
        _realtimeStarted) {
      return;
    }

    _realtimeStarted = true;
    for (final table in const [
      'clients',
      'projects',
      'payments',
      'expenses',
      'goals',
      'reminders',
      'notes',
      'partners',
      'partner_payments',
    ]) {
      final channel = client.channel('nexo-public-$table').onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (_) => _scheduleRefresh(table),
          );
      channel.subscribe();
      _channels.add(channel);
    }
  }

  void _scheduleRefresh(String table) {
    _refreshTimers[table]?.cancel();
    _refreshTimers[table] = Timer(
      const Duration(milliseconds: 450),
      () => _refreshTable(table),
    );
  }

  Future<void> _refreshTable(String table) async {
    switch (table) {
      case 'clients':
        await clients.refresh();
        await sales.createMissingRecurringChargesForClients(
          clients: clients.clients,
        );
        break;
      case 'projects':
        await projects.refresh();
        break;
      case 'payments':
        await Future.wait<void>([
          sales.refresh(),
          partnerPayments.refresh(),
        ]);
        break;
      case 'expenses':
        await expenses.refresh();
        break;
      case 'goals':
        await goals.refresh();
        break;
      case 'reminders':
        await reminders.refresh();
        break;
      case 'notes':
        await notes.refresh();
        break;
      case 'partners':
      case 'partner_payments':
        await partnerPayments.refresh();
        break;
    }
  }

  void dispose() {
    for (final timer in _refreshTimers.values) {
      timer.cancel();
    }
    final client = supabase.client;
    if (client != null) {
      for (final channel in _channels) {
        client.removeChannel(channel);
      }
    }
    clients.dispose();
    clientAutofill.dispose();
    sales.dispose();
    expenses.dispose();
    projects.dispose();
    goals.dispose();
    reminders.dispose();
    notes.dispose();
    partnerPayments.dispose();
  }
}
