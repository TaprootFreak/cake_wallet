import 'dart:convert';
import 'package:cake_wallet/core/logger_service.dart';
import 'package:cw_core/wallet_type.dart';

/// Validates signatures for DFX authentication
class DfxSignatureValidator {
  /// Validates that a signature is properly formatted and non-empty
  static bool validateSignature({
    required String signature,
    required WalletType walletType,
    required String originalMessage,
  }) {
    try {
      // Basic validation - signature should not be empty
      if (signature.isEmpty) {
        LoggerService.warning('Empty signature received', tag: 'DFX');
        return false;
      }
      
      // Wallet-specific validation
      switch (walletType) {
        case WalletType.ethereum:
        case WalletType.polygon:
          return _validateEthereumSignature(signature);
        
        case WalletType.bitcoin:
        case WalletType.litecoin:
        case WalletType.bitcoinCash:
          return _validateBitcoinSignature(signature);
        
        case WalletType.zano:
          return _validateZanoSignature(signature);
        
        default:
          LoggerService.debug('No specific validation for ${walletType}', tag: 'DFX');
          return signature.length > 10; // Basic length check
      }
    } catch (e) {
      LoggerService.error('Signature validation failed', error: e, tag: 'DFX');
      return false;
    }
  }
  
  static bool _validateEthereumSignature(String signature) {
    // Ethereum signatures should be hex strings (with or without 0x prefix)
    // Standard length is 132 characters (0x + 130 hex chars)
    final cleanSig = signature.startsWith('0x') ? signature.substring(2) : signature;
    
    // Check if it's a valid hex string
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleanSig)) {
      LoggerService.warning('Invalid hex format in Ethereum signature', tag: 'DFX');
      return false;
    }
    
    // Standard Ethereum signature is 65 bytes = 130 hex characters
    if (cleanSig.length != 130) {
      LoggerService.warning('Invalid Ethereum signature length: ${cleanSig.length}', tag: 'DFX');
      return false;
    }
    
    return true;
  }
  
  static bool _validateBitcoinSignature(String signature) {
    // Bitcoin signatures can be in different formats
    // Base64 format check
    if (_isBase64(signature)) {
      // Typical Bitcoin signature in base64 is around 88-90 characters
      if (signature.length < 85 || signature.length > 95) {
        LoggerService.warning('Unusual Bitcoin base64 signature length: ${signature.length}', tag: 'DFX');
        // Still allow it, but log warning
      }
      return true;
    }
    
    // Hex format check (after our conversion)
    if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(signature)) {
      // Bitcoin signatures are typically 64-72 bytes = 128-144 hex characters
      if (signature.length < 128 || signature.length > 146) {
        LoggerService.warning('Invalid Bitcoin hex signature length: ${signature.length}', tag: 'DFX');
        return false;
      }
      return true;
    }
    
    LoggerService.warning('Bitcoin signature format not recognized', tag: 'DFX');
    return false;
  }
  
  static bool _validateZanoSignature(String signature) {
    // Zano signatures are typically hex strings
    // Check if it's a valid hex string
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(signature)) {
      LoggerService.warning('Invalid hex format in Zano signature', tag: 'DFX');
      return false;
    }
    
    // Zano signatures should be 64 bytes = 128 hex characters
    if (signature.length != 128) {
      LoggerService.warning('Invalid Zano signature length: ${signature.length}', tag: 'DFX');
      return false;
    }
    
    return true;
  }
  
  static bool _isBase64(String str) {
    try {
      base64.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Validates signature structure without cryptographic verification
  /// Returns detailed validation result
  static SignatureValidationResult validateStructure({
    required String signature,
    required WalletType walletType,
  }) {
    if (signature.isEmpty) {
      return SignatureValidationResult(
        isValid: false,
        error: 'Signature is empty',
      );
    }
    
    try {
      final isValid = validateSignature(
        signature: signature,
        walletType: walletType,
        originalMessage: '', // Not needed for structure validation
      );
      
      return SignatureValidationResult(
        isValid: isValid,
        walletType: walletType,
        signatureLength: signature.length,
      );
    } catch (e) {
      return SignatureValidationResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }
}

class SignatureValidationResult {
  final bool isValid;
  final String? error;
  final WalletType? walletType;
  final int? signatureLength;
  
  SignatureValidationResult({
    required this.isValid,
    this.error,
    this.walletType,
    this.signatureLength,
  });
  
  @override
  String toString() {
    if (isValid) {
      return 'Valid signature for $walletType (length: $signatureLength)';
    } else {
      return 'Invalid signature: $error';
    }
  }
}