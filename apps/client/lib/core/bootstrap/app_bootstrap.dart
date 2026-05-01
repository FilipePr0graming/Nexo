import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/clients/data/data_sources/clients_local_data_source.dart';
import '../../features/clients/data/data_sources/clients_remote_data_source.dart';
import '../../features/clients/data/data_sources/address_lookup_remote_data_source.dart';
import '../../features/clients/data/data_sources/company_lookup_remote_data_source.dart';
import '../../features/clients/data/repositories/client_autofill_repository.dart';
import '../../features/clients/data/repositories/clients_repository.dart';
import '../../features/clients/services/client_autofill_service.dart';
import '../../features/clients/services/clients_service.dart';
import '../../features/finance/data/data_sources/expenses_local_data_source.dart';
import '../../features/finance/data/data_sources/expenses_remote_data_source.dart';
import '../../features/finance/data/data_sources/sales_local_data_source.dart';
import '../../features/finance/data/data_sources/sales_remote_data_source.dart';
import '../../features/finance/data/repositories/expenses_repository.dart';
import '../../features/finance/data/repositories/sales_repository.dart';
import '../../features/finance/services/expenses_service.dart';
import '../../features/finance/services/sales_service.dart';
import '../app/app_services.dart';
import '../config/app_environment.dart';
import '../services/supabase_service.dart';
import '../storage/local_json_store.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<AppServices> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb || const bool.fromEnvironment('ENABLE_FLUTTER_SEMANTICS')) {
      SemanticsBinding.instance.ensureSemantics();
    }

    SupabaseClient? supabaseClient;
    if (AppEnvironment.hasSupabase) {
      await Supabase.initialize(
        url: AppEnvironment.supabaseUrl,
        anonKey: AppEnvironment.supabaseAnonKey,
      );
      supabaseClient = Supabase.instance.client;
    }

    final supabaseService = SupabaseService(supabaseClient);
    final localStore = LocalJsonStore();

    final clientsRepository = ClientsRepository(
      localDataSource: ClientsLocalDataSource(localStore),
      remoteDataSource: ClientsRemoteDataSource(supabaseClient),
    );

    final clientAutofillRepository = ClientAutofillRepository(
      companyDataSource: CompanyLookupRemoteDataSource(),
      addressDataSource: AddressLookupRemoteDataSource(),
    );

    final salesRepository = SalesRepository(
      localDataSource: SalesLocalDataSource(localStore),
      remoteDataSource: SalesRemoteDataSource(supabaseClient),
    );

    final expensesRepository = ExpensesRepository(
      localDataSource: ExpensesLocalDataSource(localStore),
      remoteDataSource: ExpensesRemoteDataSource(supabaseClient),
    );

    final services = AppServices(
      clients: ClientsService(clientsRepository),
      supabase: supabaseService,
      clientAutofill: ClientAutofillService(clientAutofillRepository),
      sales: SalesService(salesRepository),
      expenses: ExpensesService(expensesRepository),
      supabaseEnabled: AppEnvironment.hasSupabase,
    );

    await services.initialize();
    return services;
  }
}
