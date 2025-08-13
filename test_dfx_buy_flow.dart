import 'dart:convert';
import 'package:http/http.dart' as http;

// Test the complete DFX buy flow for Zano
void main() async {
  print('=== TESTING COMPLETE DFX BUY FLOW FOR ZANO ===\n');
  
  // Wallet data from our test
  final walletAddress = 'ZxCxPx6fSq384BG5tQddaR1HvU9UibzZX1ea8HDsdCdXg9f94AkuP2BfTffVgtvU4tPUUkfkGTUjw4dgMfFZyN8H1imyw9eh1';
  final blockchain = 'Zano';
  
  print('1. CHECK ZANO ASSET AVAILABILITY');
  print('----------------------------------------');
  
  // Check if Zano is available on DFX
  final assetUrl = Uri.https('api.dfx.swiss', '/v1/asset', {'blockchains': blockchain});
  print('Asset URL: $assetUrl');
  
  try {
    final assetResponse = await http.get(assetUrl, headers: {'accept': 'application/json'});
    print('Status: ${assetResponse.statusCode}');
    
    if (assetResponse.statusCode == 200) {
      final assets = json.decode(assetResponse.body);
      print('Available assets on $blockchain:');
      
      if (assets is List) {
        for (final asset in assets) {
          if (asset['dexName'].toString().toLowerCase() == 'zano') {
            print('\nZANO Asset found:');
            print('  ID: ${asset['id']}');
            print('  Name: ${asset['dexName']}');
            print('  Buyable: ${asset['buyable']}');
            print('  Sellable: ${asset['sellable']}');
            print('  Type: ${asset['type']}');
          }
        }
      }
    } else {
      print('Error: ${assetResponse.body}');
    }
  } catch (e) {
    print('Error fetching assets: $e');
  }
  
  print('\n2. TEST AUTHENTICATION');
  print('----------------------------------------');
  
  // Generate signature message
  final message = 'By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_$walletAddress';
  
  // This would be the actual signature from Zano wallet
  final signature = 'c249daf41f9271feb7262680424f33abdcacbc76f51dfe19762c957e30a92a0920e12d8a4805888ee728cbe3ead0425079bbccc29791feab5b0a1c9af6b5b108';
  
  print('Message: ${message.substring(0, 50)}...');
  print('Signature: ${signature.substring(0, 50)}...');
  
  // Authenticate with DFX
  final authUrl = Uri.https('api.dfx.swiss', '/v1/auth');
  final authBody = json.encode({
    'wallet': 'CakeWallet',
    'address': walletAddress,
    'signature': signature,
  });
  
  print('\nAuthenticating with DFX...');
  try {
    final authResponse = await http.post(
      authUrl, 
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json'
      },
      body: authBody
    );
    
    print('Auth Status: ${authResponse.statusCode}');
    
    if (authResponse.statusCode == 201) {
      final authData = json.decode(authResponse.body);
      print('✅ Authentication successful!');
      print('Access Token: ${authData['accessToken']?.substring(0, 50)}...');
      
      // Test buy quote
      print('\n3. TEST BUY QUOTE');
      print('----------------------------------------');
      
      final quoteUrl = Uri.https('api.dfx.swiss', '/v1/buy/quote');
      final quoteBody = json.encode({
        'currency': {'id': 1}, // EUR
        'asset': {'id': 38}, // Zano (if available)
        'amount': 100,
        'targetAmount': 0,
        'paymentMethod': 'Bank',
        'discountCode': ''
      });
      
      print('Requesting buy quote for 100 EUR -> ZANO...');
      final quoteResponse = await http.put(
        quoteUrl,
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json'
        },
        body: quoteBody
      );
      
      print('Quote Status: ${quoteResponse.statusCode}');
      if (quoteResponse.statusCode == 200) {
        final quoteData = json.decode(quoteResponse.body);
        print('✅ Quote received:');
        print('  Amount: ${quoteData['amount']} ${quoteData['currency']['name']}');
        print('  Target Amount: ${quoteData['targetAmount']} ${quoteData['asset']['name']}');
        print('  Exchange Rate: ${quoteData['exchangeRate']}');
        print('  Fees: ${quoteData['fees']}');
      } else {
        print('Quote Error: ${quoteResponse.body}');
      }
      
    } else if (authResponse.statusCode == 403) {
      print('❌ Authentication failed: Service unavailable in your region');
      print('Response: ${authResponse.body}');
    } else {
      print('❌ Authentication failed: ${authResponse.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
  
  print('\n=== TEST COMPLETE ===');
}