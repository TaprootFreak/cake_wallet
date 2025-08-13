import 'package:flutter_test/flutter_test.dart';

// Import all buy-related tests
import 'dfx_authentication_service_test.dart' as dfx_auth_test;
import 'currency_fallback_handler_test.dart' as fallback_test;
import 'provider_wallet_address_manager_test.dart' as address_manager_test;
import '../cw_zano/zano_wallet_api_test.dart' as zano_api_test;

void main() {
  group('Buy Feature Test Suite', () {
    group('DFX Authentication Service', () {
      dfx_auth_test.main();
    });

    group('Currency Fallback Handler', () {
      fallback_test.main();
    });

    group('Provider Wallet Address Manager', () {
      address_manager_test.main();
    });

    group('Zano Wallet API', () {
      zano_api_test.main();
    });
  });
}