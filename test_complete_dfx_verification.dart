import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== VOLLSTÄNDIGE DFX SIGNATUR-VERIFIKATION ===\n');
  
  // Aus dem Test-Button Output:
  final address = 'ZxCxPx6fSq384BG5tQddaR1HvU9UibzZX1ea8HDsdCdXg9f94AkuP2BfTffVgtvU4tPUUkfkGTUjw4dgMfFZyN8H1imyw9eh1';
  final message = 'By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_ZxCxPx6fSq384BG5tQddaR1HvU9UibzZX1ea8HDsdCdXg9f94AkuP2BfTffVgtvU4tPUUkfkGTUjw4dgMfFZyN8H1imyw9eh1';
  final signature = 'c249daf41f9271feb7262680424f33abdcacbc76f51dfe19762c957e30a92a0920e12d8a4805888ee728cbe3ead0425079bbccc29791feab5b0a1c9af6b5b108';
  
  print('1. ADDRESS (vollständig):');
  print(address);
  print('Länge: ${address.length} Zeichen\n');
  
  print('2. MESSAGE (vollständig):');
  print(message);
  print('Länge: ${message.length} Zeichen\n');
  
  print('3. SIGNATURE (vollständig):');
  print(signature);
  print('Länge: ${signature.length} Zeichen\n');
  
  // DFX API Verifikation
  final url = Uri.parse('https://api.dfx.swiss/v1/auth/verifySignature').replace(
    queryParameters: {
      'address': address,
      'message': message,
      'signature': signature,
    }
  );
  
  print('4. API AUFRUF:');
  print('URL: ${url.toString()}\n');
  
  try {
    final response = await http.get(url);
    final responseJson = json.decode(response.body);
    
    print('5. ERGEBNIS:');
    print('Status Code: ${response.statusCode}');
    print('Response: ${response.body}');
    
    if (responseJson['isValid'] == true) {
      print('\n✅ ERFOLG! Die Signatur ist GÜLTIG!');
    } else {
      print('\n❌ FEHLER! Die Signatur ist UNGÜLTIG!');
    }
    
  } catch (e) {
    print('API Fehler: $e');
  }
}