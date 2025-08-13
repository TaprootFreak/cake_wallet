# Buy Feature Tests

This directory contains unit tests for the buy/sell feature components.

## Test Files

### dfx_authentication_service_test.dart
Tests for the DFX authentication service including:
- Wallet type specific authentication (Zano, Bitcoin, Ethereum, etc.)
- Signature formatting for different blockchain types
- Error handling for unsupported wallets
- Authentication failure scenarios

### currency_fallback_handler_test.dart
Tests for the currency fallback mechanism including:
- EUR fallback when USD quotes are unavailable
- Provider eligibility checking
- Quote fetching with timeout handling
- Buy and sell action handling
- Edge cases when no providers are available

### provider_wallet_address_manager_test.dart
Tests for wallet address management across different providers:
- DFX provider address requirements
- Native currency address handling
- Provider detection by name and type
- Address requirement validation

### zano_wallet_api_test.dart
Tests for the Zano wallet signMessage implementation:
- Message signing with base64 encoding
- UTF-8 message handling
- Error response handling
- Edge cases (empty messages, long messages)

## Running Tests

To run all buy feature tests:
```bash
flutter test test/buy/buy_test_suite.dart
```

To run individual test files:
```bash
flutter test test/buy/dfx_authentication_service_test.dart
flutter test test/buy/currency_fallback_handler_test.dart
flutter test test/buy/provider_wallet_address_manager_test.dart
flutter test test/cw_zano/zano_wallet_api_test.dart
```

To run with coverage:
```bash
flutter test --coverage test/buy/
```

## Generating Mocks

Some tests use Mockito for mocking dependencies. To regenerate mocks after changes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Test Coverage Areas

- ✅ Authentication logic for multiple wallet types
- ✅ Currency fallback mechanisms
- ✅ Provider-specific address requirements
- ✅ Zano wallet signing implementation
- ✅ Error handling and edge cases
- ✅ Timeout and async operation handling

## Future Improvements

- Add integration tests for end-to-end buy flow
- Add performance tests for quote fetching
- Add tests for specific provider implementations
- Add tests for the Logger Service