import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Test data - these would come from actual Zano wallet
  final address = 'ZxDSTiyFb3VDKW9gogQw29TUi8brUvJYvAtFMVLvJcCCfzBmPARwVkufL5Efgb8ouwBFhowVWJ4ThrFc3GCKtmy81Nmo1tJ9V';
  final message = 'Test_Message_ABC123';
  
  // This is a placeholder - you'd get the actual signature from Zano wallet
  // The actual signature would be 128 hex characters from sign_message RPC
  final signature = 'a1b2c3d4e5f6'; // Example placeholder
  
  // Call DFX verification endpoint
  final url = Uri.parse('https://api.dfx.swiss/v1/auth/verifySignature').replace(
    queryParameters: {
      'address': address,
      'message': message,
      'signature': signature,
    }
  );
  
  print('Testing DFX signature verification:');
  print('Address: $address');
  print('Message: $message');
  print('Signature: $signature');
  print('URL: $url');
  
  try {
    final response = await http.get(url);
    final responseJson = json.decode(response.body);
    
    print('\nResponse: ${response.statusCode}');
    print('Body: ${response.body}');
    print('Is Valid: ${responseJson['isValid']}');
    
  } catch (e) {
    print('Error: $e');
  }
}