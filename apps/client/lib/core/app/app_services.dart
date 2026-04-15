import '../../features/clients/services/clients_service.dart';
import '../../features/finance/services/expenses_service.dart';
import '../../features/finance/services/sales_service.dart';

class AppServices {
  AppServices({
    required this.clients,
    required this.sales,
    required this.expenses,
    required this.supabaseEnabled,
  });

  final ClientsService clients;
  final SalesService sales;
  final ExpensesService expenses;
  final bool supabaseEnabled;

  Future<void> initialize() async {
    await Future.wait<void>([
      clients.initialize(),
      sales.initialize(),
      expenses.initialize(),
    ]);
  }

  void dispose() {
    clients.dispose();
    sales.dispose();
    expenses.dispose();
  }
}
