import 'package:flutter_test/flutter_test.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:cw_zano/zano_wallet_service.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  group('Zano SignMessage Tests', () {
    test('Test signMessage with current wallet', () async {
      print('\n=== Testing Zano signMessage ===\n');
      
      // Generate test message
      final random = Random();
      final testMessage = 'Test_Message_${random.nextInt(1000000)}';
      print('Test message: $testMessage');
      
      try {
        // Create wallet service
        final walletService = ZanoWalletService();
        
        // Try to open existing wallet
        final walletName = 'test_zano_wallet';
        final password = 'test123456';
        
        ZanoWallet? wallet;
        
        try {
          // Check if wallet exists
          final exists = await walletService.isWalletExist(walletName);
          
          if (exists) {
            print('Opening existing wallet...');
            wallet = await walletService.openWallet(walletName, password) as ZanoWallet;
            print('✓ Wallet opened');
          } else {
            print('Creating new wallet...');
            final credentials = ZanoNewWalletCredentials(
              name: walletName,
              password: password,
            );
            wallet = await walletService.create(credentials) as ZanoWallet;
            print('✓ Wallet created');
          }
        } catch (e) {
          print('Error with wallet: $e');
          return;
        }
        
        if (wallet == null) {
          print('Failed to get wallet');
          return;
        }
        
        print('Wallet address: ${wallet.walletAddresses.address}');
        print('Wallet hWallet: ${wallet.hWallet}');
        
        // Test 1: Direct invokeMethod test
        print('\n--- Test 1: Direct RPC Call ---');
        try {
          final messageBase64 = base64.encode(utf8.encode(testMessage));
          print('Base64 encoded: $messageBase64');
          
          final response = await wallet.invokeMethod('sign_message', {
            'buff': messageBase64
          });
          
          print('Raw response: $response');
          
          final responseData = json.decode(response);
          if (responseData['result'] != null) {
            print('✓ RPC call successful');
            print('  Signature: ${responseData['result']['sig']}');
            print('  Public key: ${responseData['result']['pkey']}');
          } else {
            print('✗ RPC Error: ${responseData['error']}');
          }
        } catch (e) {
          print('✗ Error in RPC: $e');
        }
        
        // Test 2: signMessage method
        print('\n--- Test 2: signMessage Method ---');
        try {
          final signature = await wallet.signMessage(testMessage);
          print('✓ Message signed successfully');
          print('  Signature: ${signature.substring(0, 50)}...');
          print('  Length: ${signature.length}');
        } catch (e) {
          print('✗ Error: $e');
        }
        
        // Test 3: DFX-style message
        print('\n--- Test 3: DFX Message ---');
        final dfxMessage = 'By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_${wallet.walletAddresses.address}';
        try {
          final signature = await wallet.signMessage(dfxMessage, address: wallet.walletAddresses.address);
          print('✓ DFX message signed');
          print('  Signature: ${signature.substring(0, 50)}...');
        } catch (e) {
          print('✗ Error: $e');
        }
        
        await wallet.close();
        
      } catch (e) {
        print('Test error: $e');
        print('Stack: ${StackTrace.current}');
      }
      
      print('\n=== Test Complete ===');
    });
  });
}