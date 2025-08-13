import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('=== ZANO SIGNATURE VERIFICATION WITH DFX API ===\n');
  
  // First, let's simulate getting a signature from Zano
  // In real app, this comes from wallet.signMessage()
  
  // Example Zano wallet data (from test wallet)
  final address = 'ZxDSTiyFb3VDKW9gogQw29TUi8brUvJYvAtFMVLvJcCCfzBmPARwVkufL5Efgb8ouwBFhowVWJ4ThrFc3GCKtmy81Nmo1tJ9V';
  final message = 'Test_Message_${DateTime.now().millisecondsSinceEpoch}';
  
  print('Step 1: Generate Zano signature');
  print('Address: $address');
  print('Message: $message');
  
  // We need to get an actual signature from the running app
  // Let's use the test button to generate one
  print('\nNote: To get a real signature, press the red test button in the running app');
  print('Then check the console output for the signature\n');
  
  // For testing, let's use a sample signature format
  // Real Zano signatures are 128 hex characters (64 bytes)
  // This is just a placeholder - replace with actual signature from app
  final signature = 'INSERT_ACTUAL_SIGNATURE_HERE';
  
  if (signature == 'INSERT_ACTUAL_SIGNATURE_HERE') {
    print('Please replace the signature placeholder with an actual signature from the app');
    print('\nTo get a signature:');
    print('1. Press the red bug button in the running app');
    print('2. Look for "ZANO signature generated" in the console');
    print('3. Copy the signature and replace the placeholder above');
    return;
  }
  
  print('Signature: ${signature.substring(0, 32)}...');
  print('Signature length: ${signature.length} characters');
  
  // Step 2: Verify with DFX API
  print('\nStep 2: Verify with DFX API');
  
  final url = Uri.parse('https://api.dfx.swiss/v1/auth/verifySignature').replace(
    queryParameters: {
      'address': address,
      'message': message,
      'signature': signature,
    }
  );
  
  print('API URL: ${url.toString().substring(0, 80)}...');
  
  try {
    print('\nSending request to DFX...');
    final response = await http.get(url);
    final responseJson = json.decode(response.body);
    
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (responseJson['isValid'] == true) {
      print('\n✅ SUCCESS! The signature is VALID according to DFX API');
    } else {
      print('\n❌ FAILED! The signature is INVALID according to DFX API');
    }
    
  } catch (e) {
    print('\n❌ Error calling DFX API: $e');
  }
  
  print('\n=== TEST COMPLETE ===');
}