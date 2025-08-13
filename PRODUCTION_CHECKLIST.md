# Production Readiness Checklist

## Code Quality
- [ ] All feedback requirements implemented
  - [x] Zano signMessage in zano_wallet_api.dart
  - [x] Modular architecture
  - [x] Better abstraction
  - [x] Maintainable code
- [ ] No test code in production files
- [ ] No debugging/console logs in production
- [ ] All TODOs resolved or documented

## Security
- [ ] No sensitive data in logs
  - [ ] Remove response logging in signMessage
  - [ ] Remove detailed error logging
- [ ] Input validation present
- [ ] No hardcoded secrets/keys

## Error Handling
- [ ] User-friendly error messages
- [ ] Proper exception handling
- [ ] Fallback mechanisms tested

## Configuration
- [ ] All magic numbers as constants
- [ ] Timeouts configurable
- [ ] Currency fallbacks configurable

## Documentation
- [ ] Code comments where needed
- [ ] Public API documented
- [ ] Breaking changes documented

## Testing
- [ ] Manual testing completed
- [ ] All scenarios from MANUAL_TEST_CHECKLIST.md tested
- [ ] Edge cases handled

## Files to Include in PR

### Core Implementation
✅ cw_zano/lib/zano_wallet_api.dart - signMessage implementation
✅ cw_zano/lib/zano_wallet.dart - delegation to API
✅ lib/buy/dfx/dfx_authentication_service.dart
✅ lib/buy/dfx/dfx_signature_validator.dart
✅ lib/buy/dfx/dfx_buy_provider.dart - updated to use services
✅ lib/buy/currency_fallback_handler.dart
✅ lib/buy/provider_wallet_address_manager.dart
✅ lib/buy/buy_provider_config.dart
✅ lib/core/logger_service.dart
✅ lib/core/resource_manager.dart
✅ lib/view_model/buy/buy_sell_view_model.dart - updated logic

### DO NOT Include
❌ Test files (test/buy/*.dart)
❌ Test documentation (TEST_SETUP.md)
❌ Development notes

## Final Checks
- [ ] Code compiles without warnings
- [ ] No merge conflicts
- [ ] PR description updated
- [ ] Reviewer requirements met

## Recommended Changes Before PR

1. **Remove verbose logging:**
   - Line 267 in zano_wallet_api.dart
   - Line 36 in dfx_authentication_service.dart

2. **Add constants for magic numbers:**
   ```dart
   // In zano_wallet_api.dart
   static const int ZANO_SIGNATURE_LENGTH = 128;
   ```

3. **Improve error messages:**
   - Make them user-friendly
   - Remove technical details

4. **Remove test artifacts:**
   - Ensure no test-only code in production files