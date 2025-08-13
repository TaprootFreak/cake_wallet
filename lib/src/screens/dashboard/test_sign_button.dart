import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'dart:convert';

class TestSignButton extends StatelessWidget {
  final DashboardViewModel dashboardViewModel;
  
  TestSignButton({required this.dashboardViewModel});
  
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        print('\n=== ZANO SIGN MESSAGE TEST ===');
        
        try {
          final wallet = dashboardViewModel.wallet;
          print('Wallet type: ${wallet.type}');
          print('Wallet address: ${wallet.walletAddresses.address}');
          
          if (wallet.type.toString() != 'WalletType.zano') {
            print('Not a Zano wallet');
            return;
          }
          
          // Test 1: Simple message
          print('\nTest 1: Simple message');
          final testMessage = 'Hello_Zano_123';
          print('Message: $testMessage');
          
          try {
            final signature = await wallet.signMessage(testMessage);
            print('✓ Signature received: ${signature.substring(0, 20)}...');
            print('  Full length: ${signature.length} chars');
            
            // Verify it's base64
            try {
              final decoded = base64.decode(signature);
              print('  ✓ Valid base64, decoded length: ${decoded.length} bytes');
            } catch (e) {
              print('  ✗ NOT valid base64!');
            }
          } catch (e) {
            print('✗ ERROR: $e');
          }
          
          // Test 2: DFX-style message
          print('\nTest 2: DFX-style message');
          final dfxMessage = 'By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_${wallet.walletAddresses.address}';
          print('Message: ${dfxMessage.substring(0, 50)}...');
          
          try {
            final signature = await wallet.signMessage(dfxMessage);
            print('✓ DFX Signature: ${signature.substring(0, 20)}...');
            print('  Length: ${signature.length}');
            
            // Check if signature changes with different messages
            final sig2 = await wallet.signMessage('Different_message');
            if (signature != sig2) {
              print('  ✓ Signatures are different for different messages');
            } else {
              print('  ✗ WARNING: Same signature for different messages!');
            }
          } catch (e) {
            print('✗ ERROR: $e');
          }
          
          print('\n=== TEST COMPLETE ===\n');
          
        } catch (e) {
          print('FATAL ERROR: $e');
        }
      },
      child: Icon(Icons.bug_report),
      backgroundColor: Colors.red,
    );
  }
}