import 'package:cake_wallet/main.dart' as app;
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test signMessage
  print('Testing Zano signMessage...');
  
  try {
    // This will trigger the signMessage in the context of the app
    await testSignMessage();
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testSignMessage() async {
  // Get the current wallet from the app
  final appState = await app.getIt.allReady();
  final wallet = app.getIt.get<app.AppStore>().wallet;
  
  if (wallet == null) {
    print('No wallet loaded');
    return;
  }
  
  print('Wallet type: ${wallet.type}');
  print('Wallet address: ${wallet.walletAddresses.address}');
  
  if (wallet.type.toString() == 'zano') {
    final testMessage = 'Test_message_for_signature';
    print('Testing signMessage with: $testMessage');
    
    try {
      final signature = await wallet.signMessage(testMessage);
      print('SUCCESS! Signature: $signature');
    } catch (e) {
      print('ERROR: $e');
    }
  } else {
    print('Not a Zano wallet');
  }
}