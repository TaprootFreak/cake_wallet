import 'dart:convert';
import 'dart:math';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/utils/print_verbose.dart';

class DashboardTestSign {
  static Future<void> testSignMessage(AppStore appStore) async {
    printV('=== ZANO SIGN MESSAGE TEST ===');
    
    final wallet = appStore.wallet;
    if (wallet == null) {
      printV('ERROR: No wallet loaded');
      return;
    }
    
    printV('Wallet type: ${wallet.type}');
    printV('Wallet address: ${wallet.walletAddresses.address}');
    
    if (wallet.type.toString() != 'WalletType.zano') {
      printV('ERROR: Not a Zano wallet');
      return;
    }
    
    // Generate random test message
    final random = Random();
    final testMessage = 'Test_Message_${random.nextInt(1000000)}';
    printV('Test message: $testMessage');
    
    try {
      printV('\n--- Testing signMessage ---');
      final signature = await wallet.signMessage(testMessage);
      printV('✓ SUCCESS! Signature generated');
      printV('  Signature: ${signature.substring(0, min(50, signature.length))}...');
      printV('  Signature length: ${signature.length}');
      
      // Test DFX-style message
      printV('\n--- Testing DFX Message ---');
      final dfxMessage = 'By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_${wallet.walletAddresses.address}';
      final dfxSignature = await wallet.signMessage(dfxMessage, address: wallet.walletAddresses.address);
      printV('✓ DFX message signed');
      printV('  DFX Signature: ${dfxSignature.substring(0, min(50, dfxSignature.length))}...');
      
    } catch (e) {
      printV('✗ ERROR signing message: $e');
      printV('Stack trace: ${StackTrace.current}');
    }
    
    printV('\n=== TEST COMPLETE ===');
  }
}