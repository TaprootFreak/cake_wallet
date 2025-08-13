// Test trigger for DFX signMessage
import 'package:cake_wallet/buy/dfx/dfx_buy_provider.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';

class DfxTestTrigger {
  static Future<void> testSignMessage(WalletBase wallet) async {
    print('DFX Test: Starting signMessage test');
    
    if (wallet.type.toString() != 'zano') {
      print('DFX Test: Not a Zano wallet');
      return;
    }
    
    try {
      // Create a DFX provider instance
      final dfxProvider = DfxBuyProvider(wallet: wallet, isBuyAction: true);
      
      // Test getting signature (this should trigger signMessage)
      final address = wallet.walletAddresses.address;
      print('DFX Test: Testing with address: $address');
      
      final signature = await dfxProvider.getSignature(
        'test_message_for_dfx',
        address,
        CryptoCurrency.zano,
      );
      
      print('DFX Test: SUCCESS! Signature generated: $signature');
      
    } catch (e) {
      print('DFX Test: ERROR - $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
}