import '../../models/address_lookup_result.dart';
import '../../models/company_lookup_result.dart';
import '../data_sources/address_lookup_remote_data_source.dart';
import '../data_sources/company_lookup_remote_data_source.dart';

class ClientAutofillRepository {
  ClientAutofillRepository({
    required this.companyDataSource,
    required this.addressDataSource,
  });

  final CompanyLookupRemoteDataSource companyDataSource;
  final AddressLookupRemoteDataSource addressDataSource;

  Future<CompanyLookupResult> lookupCompany(String cnpj) {
    return companyDataSource.fetchByCnpj(cnpj);
  }

  Future<AddressLookupResult> lookupAddress(String zipCode) {
    return addressDataSource.fetchByZipCode(zipCode);
  }

  void dispose() {
    companyDataSource.dispose();
    addressDataSource.dispose();
  }
}
