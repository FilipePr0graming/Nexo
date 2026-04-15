abstract final class PublicLookupEndpoints {
  static Uri companyByCnpj(String cnpj) {
    return Uri.https('brasilapi.com.br', '/api/cnpj/v1/$cnpj');
  }

  static Uri addressByZipCode(String zipCode) {
    return Uri.https('viacep.com.br', '/ws/$zipCode/json/');
  }
}
