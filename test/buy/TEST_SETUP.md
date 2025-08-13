# Test Setup Instructions

## Current Issues

1. **Dependency Conflict**: The project has a version conflict with `intl` package:
   - Flutter SDK requires `intl 0.20.2`
   - Project specifies `intl ^0.19.0`
   
   **Fix**: Update `pubspec_base.yaml` to use `intl: ^0.20.0`

2. **Mocking Library**: Project uses `mocktail` instead of `mockito`
   - All tests have been updated to use `mocktail`
   - No code generation needed (mocktail doesn't require it)

## Running Tests

### Prerequisites
1. Fix the intl dependency conflict:
   ```bash
   # Edit pubspec_base.yaml and change:
   # intl: ^0.19.0
   # to:
   # intl: ^0.20.0
   ```

2. Configure the project:
   ```bash
   ./configure_cake_wallet.sh macos  # or android/ios/linux
   ```

3. Get dependencies:
   ```bash
   flutter pub get
   ```

### Run Tests

Individual test files:
```bash
flutter test test/buy/dfx_authentication_service_test.dart
flutter test test/buy/currency_fallback_handler_test.dart
flutter test test/buy/provider_wallet_address_manager_test.dart
flutter test test/cw_zano/zano_wallet_api_test.dart
```

All buy feature tests:
```bash
flutter test test/buy/
```

With coverage:
```bash
flutter test --coverage test/buy/
```

## Test Coverage

The tests cover:
- ✅ DFX Authentication Service (all wallet types)
- ✅ Currency Fallback Handler (USD→EUR fallback logic)
- ✅ Provider Wallet Address Manager (DFX address requirements)
- ✅ Zano Wallet API (signMessage implementation)

## Known Limitations

1. Tests use mocks and don't require actual wallet instances
2. Network calls are mocked - no real API calls
3. Signature validation tests structural validity, not cryptographic correctness

## Next Steps

1. Fix the dependency conflict
2. Run the tests to ensure they pass
3. Check coverage report
4. Integration testing with real wallets (manual)