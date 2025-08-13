import 'dart:io';
import 'package:cw_zano/zano_wallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

void main() async {
  print('Testing Zano signMessage implementation...');
  
  // Create a test wallet info
  final walletInfo = WalletInfo(
    id: 'test_wallet',
    name: 'Test Wallet',
    type: WalletType.zano,
    isRecovery: false,
    restoreHeight: 0,
    timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    dirPath: '/tmp/test_wallet',
    path: '/tmp/test_wallet/test',
    address: 'ZxCxPx6fSq384BG5tQddaR1HvU9UibzZX1ea8HDsdCdXg9f94AkuP2BfTffVgtvU4tPUUkfkGTUjw4dgMfFZyN8H1imyw9eh1',
    showIntroCakePayCard: false,
  );
  
  try {
    // Open existing wallet or create test wallet
    final wallet = await ZanoWallet.open(
      name: 'test_wallet',
      password: 'test_password',
      walletInfo: walletInfo,
    );
    
    print('Wallet opened successfully');
    print('Wallet address: ${wallet.walletAddresses.address}');
    
    // Test message (similar to what DFX would send)
    final testMessage = 'By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_${wallet.walletAddresses.address}';
    
    print('\nTesting signMessage...');
    print('Message: $testMessage');
    
    try {
      final signature = await wallet.signMessage(testMessage, address: wallet.walletAddresses.address);
      print('SUCCESS! Signature generated: $signature');
      
      // Check if signature looks valid
      if (signature.isNotEmpty && signature.length > 20) {
        print('✓ Signature appears valid (length: ${signature.length})');
      } else {
        print('✗ Signature might be invalid (too short)');
      }
    } catch (e) {
      print('ERROR signing message: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    
    await wallet.close();
    print('\nTest completed');
    
  } catch (e) {
    print('ERROR: $e');
    exit(1);
  }
  
  exit(0);
}