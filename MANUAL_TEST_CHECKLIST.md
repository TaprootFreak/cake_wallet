# Manual Testing Checklist for Zano DFX Integration

## Prerequisites
- [ ] Cake Wallet app builds successfully
- [ ] Zano wallet created/restored
- [ ] Test device/emulator ready
- [ ] Internet connection available

## Test Scenarios

### 1. Zano DFX Buy Flow
- [ ] Open Cake Wallet with Zano wallet
- [ ] Navigate to Buy/Sell screen
- [ ] Select "Buy" action
- [ ] Select Zano as cryptocurrency
- [ ] Select USD as fiat currency
- [ ] Enter amount (e.g., $100)
- [ ] Check if DFX appears as provider
- [ ] Select DFX provider
- [ ] Verify authentication process starts
- [ ] Check if signMessage is called
- [ ] Verify signature is generated
- [ ] Confirm DFX website opens with correct parameters

### 2. EUR Fallback Test
- [ ] Select a cryptocurrency with no USD providers
- [ ] Enter amount in USD
- [ ] Observe automatic fallback to EUR
- [ ] Check for notification message: "Automatically switched from USD to EUR"
- [ ] Verify EUR quotes are displayed
- [ ] Confirm transaction can proceed with EUR

### 3. DFX Authentication Test
- [ ] Use Zano wallet
- [ ] Initiate DFX buy flow
- [ ] Monitor logs for:
  - `ZANO signMessage called`
  - `Sign message response`
  - `Signature validated successfully`
- [ ] Verify no authentication errors
- [ ] Check DFX accepts the signature

### 4. Error Handling
- [ ] Test with no internet connection
- [ ] Test with invalid amounts
- [ ] Test timeout scenarios (wait >10 seconds)
- [ ] Verify error messages are user-friendly

### 5. Cross-Currency Purchase
- [ ] Use Bitcoin wallet
- [ ] Try to buy Ethereum via DFX
- [ ] Verify wallet address is still provided for auth
- [ ] Confirm authentication succeeds

## Expected Behaviors

### Successful Flow
1. **Zano Wallet + DFX:**
   - signMessage executes without errors
   - Signature is 128 hex characters
   - DFX authentication succeeds
   - User redirected to DFX website

2. **EUR Fallback:**
   - Automatic switch from USD to EUR
   - User notification displayed
   - Quotes fetched successfully
   - No infinite loops

3. **Logging:**
   - All operations logged with appropriate levels
   - No sensitive data in logs
   - Clear error messages

## Debug Commands

### Check Logs
```bash
# For iOS
xcrun simctl spawn booted log stream --level debug | grep -E "DFX|Zano|Currency"

# For Android
adb logcat | grep -E "DFX|Zano|Currency"
```

### Verify Signature Format
- Zano: 128 hex characters
- Bitcoin: Base64 or hex format
- Ethereum: 0x + 130 hex characters

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "This currency pair isn't supported" | EUR fallback should trigger automatically |
| DFX authentication fails | Check signature format and wallet address |
| Timeout errors | Increase timeout in BuyProviderConfig |
| No providers available | Check internet and provider status |

## Sign-off

- [ ] All test scenarios completed
- [ ] No critical bugs found
- [ ] Performance acceptable
- [ ] Error handling works correctly
- [ ] Ready for production

## Notes
- Test on both iOS and Android if possible
- Test with different network speeds
- Document any unexpected behaviors
- Save logs for debugging