import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:convert';

// Mock class for testing
class MockZanoWalletApi {
  int hWallet = 0;
  
  // Simulate the invokeMethod function
  Future<String> invokeMethod(String methodName, Object params) async {
    if (methodName == 'sign_message') {
      final paramsMap = params as Map<String, dynamic>;
      final buff = paramsMap['buff'] as String;
      
      // Simulate success response
      return jsonEncode({
        'result': {
          'sig': 'test_signature_${buff.substring(0, 10)}',
          'pkey': 'test_public_key'
        }
      });
    }
    throw Exception('Unknown method: $methodName');
  }
  
  // Simulate jsonDecode that handles both regular and bigint JSON
  Map<String, dynamic> jsonDecode(String json) {
    return convert.jsonDecode(json) as Map<String, dynamic>;
  }
  
  Future<String> signMessage(String message) async {
    try {
      final messageBase64 = base64.encode(utf8.encode(message));
      
      final response = await invokeMethod('sign_message', {
        'buff': messageBase64
      });
      
      final responseData = jsonDecode(response) as Map<String, dynamic>;
      
      // Check for top-level errors first
      if (responseData['error'] != null) {
        final error = responseData['error'];
        final code = error['code'] ?? '';
        final errorMessage = error['message'] ?? 'Unknown error';
        throw Exception('Sign message failed: $errorMessage ($code)');
      }
      
      final result = responseData['result'] as Map<String, dynamic>?;
      if (result == null) {
        throw Exception('Invalid response from sign_message: no result');
      }
      
      final signature = result['sig'] as String?;
      if (signature == null) {
        throw Exception('No signature in response');
      }
      
      return signature;
    } catch (e) {
      if (e.toString().contains('Sign message failed')) rethrow;
      throw Exception('Failed to sign message: $e');
    }
  }
}

void main() {
  group('Zano Wallet API - signMessage', () {
    late MockZanoWalletApi api;

    setUp(() {
      api = MockZanoWalletApi();
    });

    test('should successfully sign a message', () async {
      // Arrange
      const message = 'Hello, Zano!';
      
      // Act
      final signature = await api.signMessage(message);
      
      // Assert
      expect(signature, isNotEmpty);
      expect(signature, startsWith('test_signature_'));
    });

    test('should handle UTF-8 messages correctly', () async {
      // Arrange
      const message = 'Тест сообщения 测试消息 🚀';
      
      // Act
      final signature = await api.signMessage(message);
      
      // Assert
      expect(signature, isNotEmpty);
      expect(signature, startsWith('test_signature_'));
    });

    test('should handle empty message', () async {
      // Arrange
      const message = '';
      
      // Act
      final signature = await api.signMessage(message);
      
      // Assert
      expect(signature, isNotEmpty);
    });

    test('should handle very long messages', () async {
      // Arrange
      final message = 'A' * 10000; // 10K character message
      
      // Act
      final signature = await api.signMessage(message);
      
      // Assert
      expect(signature, isNotEmpty);
      expect(signature, startsWith('test_signature_'));
    });
  });

  group('Zano Wallet API - signMessage error handling', () {
    test('should handle error response correctly', () async {
      // Create a mock that returns an error
      final errorApi = MockZanoWalletApiWithError();
      
      // Act & Assert
      expect(
        () => errorApi.signMessage('test'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Sign message failed'),
          ),
        ),
      );
    });

    test('should handle missing signature in response', () async {
      // Create a mock that returns response without signature
      final noSigApi = MockZanoWalletApiNoSignature();
      
      // Act & Assert
      expect(
        () => noSigApi.signMessage('test'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No signature in response'),
          ),
        ),
      );
    });

    test('should handle invalid response format', () async {
      // Create a mock that returns invalid response
      final invalidApi = MockZanoWalletApiInvalidResponse();
      
      // Act & Assert
      expect(
        () => invalidApi.signMessage('test'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid response from sign_message'),
          ),
        ),
      );
    });
  });
}

// Mock classes for error scenarios
class MockZanoWalletApiWithError extends MockZanoWalletApi {
  @override
  Future<String> invokeMethod(String methodName, Object params) async {
    return jsonEncode({
      'error': {
        'code': 'SIGN_ERROR',
        'message': 'Failed to sign message'
      }
    });
  }
}

class MockZanoWalletApiNoSignature extends MockZanoWalletApi {
  @override
  Future<String> invokeMethod(String methodName, Object params) async {
    return jsonEncode({
      'result': {
        'pkey': 'test_public_key'
        // Missing 'sig' field
      }
    });
  }
}

class MockZanoWalletApiInvalidResponse extends MockZanoWalletApi {
  @override
  Future<String> invokeMethod(String methodName, Object params) async {
    return jsonEncode({
      // Missing 'result' field
      'status': 'ok'
    });
  }
}