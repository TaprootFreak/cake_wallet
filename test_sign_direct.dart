import 'dart:convert';
import 'dart:math';
import 'package:cw_zano/zano_wallet.dart';
import 'package:cw_zano/zano_wallet_api.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() async {
  print('=== Zano SignMessage Direct Test ===\n');
  
  // Initialize Hive
  final appDir = Directory('/tmp/zano_test');
  if (!appDir.existsSync()) {
    appDir.createSync(recursive: true);
  }
  Hive.init(appDir.path);
  
  try {
    // Generate random test data
    final random = Random();
    final testMessage = 'Test_Message_${random.nextInt(1000000)}';
    print('Test message: $testMessage');
    
    // Try to open existing wallet or create new one
    final walletName = 'test_zano_wallet';
    final password = 'test123456';
    
    print('\nAttempting to open/create wallet...');
    
    final walletInfo = WalletInfo(
      id: walletName,
      name: walletName,
      type: WalletType.zano,
      isRecovery: false,
      restoreHeight: 0,
      timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      dirPath: appDir.path,
      path: '${appDir.path}/$walletName',
      address: '',
      showIntroCakePayCard: false,
    );
    
    ZanoWallet? wallet;
    
    try {
      // Try to open existing wallet
      print('Trying to open existing wallet...');
      final walletPath = await pathForWallet(name: walletName, type: WalletType.zano);
      wallet = await ZanoWallet.open(
        name: walletName,
        password: password,
        walletInfo: walletInfo,
      );
      print('✓ Wallet opened successfully');
    } catch (e) {
      print('Wallet not found, creating new one...');
      // Create new wallet if not exists
      try {
        final credentials = ZanoNewWalletCredentials(
          name: walletName,
          password: password,
          walletInfo: walletInfo,
        );
        wallet = await ZanoWallet.create(credentials: credentials);
        print('✓ New wallet created successfully');
      } catch (createError) {
        print('ERROR creating wallet: $createError');
      }
    }
    
    if (wallet == null) {
      print('Failed to open or create wallet');
      exit(1);
    }
    
    print('Wallet address: ${wallet.walletAddresses.address}');
    print('Wallet hWallet ID: ${wallet.hWallet}');
    
    // Test 1: Sign a simple message
    print('\n--- Test 1: Simple Message ---');
    try {
      final signature = await wallet.signMessage(testMessage);
      print('✓ SUCCESS! Message signed');
      print('  Signature: ${signature.substring(0, min(50, signature.length))}...');
      print('  Signature length: ${signature.length}');
    } catch (e) {
      print('✗ ERROR: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    
    // Test 2: Sign DFX-style message
    print('\n--- Test 2: DFX-style Message ---');
    final dfxMessage = 'By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_${wallet.walletAddresses.address}';
    try {
      final signature = await wallet.signMessage(dfxMessage);
      print('✓ SUCCESS! DFX message signed');
      print('  Signature: ${signature.substring(0, min(50, signature.length))}...');
      print('  Signature length: ${signature.length}');
    } catch (e) {
      print('✗ ERROR: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    
    // Test 3: Test with address parameter
    print('\n--- Test 3: With Address Parameter ---');
    try {
      final signature = await wallet.signMessage(
        testMessage, 
        address: wallet.walletAddresses.address
      );
      print('✓ SUCCESS! Message signed with address');
      print('  Signature: ${signature.substring(0, min(50, signature.length))}...');
    } catch (e) {
      print('✗ ERROR: $e');
    }
    
    // Test 4: Test raw RPC call
    print('\n--- Test 4: Raw RPC Call ---');
    try {
      final messageBase64 = base64.encode(utf8.encode(testMessage));
      print('  Base64 message: $messageBase64');
      
      final response = await wallet.invokeMethod('sign_message', {
        'buff': messageBase64
      });
      
      print('  Raw response: $response');
      
      final responseData = json.decode(response) as Map<String, dynamic>;
      if (responseData['result'] != null) {
        final result = responseData['result'] as Map<String, dynamic>;
        print('✓ Raw RPC call successful');
        print('  Signature: ${result['sig']}');
        print('  Public key: ${result['pkey']}');
      } else if (responseData['error'] != null) {
        print('✗ RPC Error: ${responseData['error']}');
      }
    } catch (e) {
      print('✗ ERROR in raw RPC: $e');
    }
    
    await wallet.close();
    print('\n=== Test Complete ===');
    
  } catch (e) {
    print('FATAL ERROR: $e');
    print('Stack trace: ${StackTrace.current}');
    exit(1);
  }
  
  exit(0);
}

class ZanoNewWalletCredentials {
  final String name;
  final String? password;
  final WalletInfo? walletInfo;
  final String? passphrase;

  ZanoNewWalletCredentials({
    required this.name,
    this.password,
    this.walletInfo,
    this.passphrase,
  });
}