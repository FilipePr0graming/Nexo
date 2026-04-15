import '../../features/clients/services/clients_service.dart';
import '../../features/clients/services/client_autofill_service.dart';
import '../../features/finance/services/expenses_service.dart';
import '../../features/finance/services/sales_service.dart';

class AppServices {
  AppServices({
    required this.clients,
    required this.clientAutofill,
    required this.sales,
    required this.expenses,
    required this.supabaseEnabled,
  });

  final ClientsService clients;
  final ClientAutofillService clientAutofill;
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
    clientAutofill.dispose();
    sales.dispose();
    expenses.dispose();
  }
}
