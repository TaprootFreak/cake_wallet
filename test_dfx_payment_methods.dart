import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== TESTING ZANO PAYMENT METHODS ===\n');
  
  final walletAddress = 'ZxCxPx6fSq384BG5tQddaR1HvU9UibzZX1ea8HDsdCdXg9f94AkuP2BfTffVgtvU4tPUUkfkGTUjw4dgMfFZyN8H1imyw9eh1';
  final signature = 'c249daf41f9271feb7262680424f33abdcacbc76f51dfe19762c957e30a92a0920e12d8a4805888ee728cbe3ead0425079bbccc29791feab5b0a1c9af6b5b108';
  
  // Authenticate first
  final authUrl = Uri.https('api.dfx.swiss', '/v1/auth');
  final authBody = json.encode({
    'wallet': 'CakeWallet',
    'address': walletAddress,
    'signature': signature,
  });
  
  final authResponse = await http.post(
    authUrl, 
    headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
    body: authBody
  );
  
  if (authResponse.statusCode \!= 201) {
    print('Auth failed');
    return;
  }
  
  final authData = json.decode(authResponse.body);
  final token = authData['accessToken'];
  print('Authenticated successfully\n');
  
  // Test different payment methods
  final paymentMethods = ['Bank', 'Card', 'Instant'];
  
  for (final method in paymentMethods) {
    print('Testing payment method: $method');
    
    final quoteUrl = Uri.https('api.dfx.swiss', '/v1/buy/quote');
    final quoteBody = json.encode({
      'currency': {'id': 1}, // EUR
      'asset': {'id': 389}, // Zano
      'amount': 100,
      'targetAmount': 0,
      'paymentMethod': method,
      'discountCode': ''
    });
    
    final quoteResponse = await http.put(
      quoteUrl,
      headers: {'Content-Type': 'application/json', 'accept': 'application/json'},
      body: quoteBody
    );
    
    if (quoteResponse.statusCode == 200) {
      print('  ✅ SUCCESS with $method');
      final data = json.decode(quoteResponse.body);
      print('  Exchange rate: ${data['exchangeRate']}');
      print('  Target amount: ${data['targetAmount']} ZANO\n');
    } else {
      final error = json.decode(quoteResponse.body);
      print('  ❌ FAILED: ${error['message']}\n');
    }
  }
}
