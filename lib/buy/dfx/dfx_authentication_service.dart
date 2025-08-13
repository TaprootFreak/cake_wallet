import 'dart:convert';
import 'package:cake_wallet/buy/dfx/dfx_signature_validator.dart';
import 'package:cake_wallet/core/logger_service.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

class DfxAuthenticationService {
  static const _signaturePrefix = '\x18Bitcoin Signed Message:\n';

  Future<String> authenticate({
    required WalletBase wallet,
    required String walletAddress,
    required String message,
  }) async {
    final walletType = wallet.type;
    
    if (!_isWalletSupported(walletType)) {
      throw UnsupportedWalletException(walletType);
    }
    
    try {
      final signature = await _signMessage(wallet, message, walletAddress);
      final formattedSignature = _formatSignature(signature, walletType);
      
      // Validate the signature structure
      final validationResult = DfxSignatureValidator.validateStructure(
        signature: formattedSignature,
        walletType: walletType,
      );
      
      if (!validationResult.isValid) {
        LoggerService.error('Invalid signature structure: ${validationResult.error}', tag: 'DFX');
        throw AuthenticationException('Invalid signature: ${validationResult.error}');
      }
      
      // Signature validation successful
      return formattedSignature;
    } catch (e) {
      if (e is AuthenticationException) rethrow;
      LoggerService.error('DFX Authentication failed for ${walletType}', error: e, tag: 'DFX');
      throw AuthenticationException('Failed to authenticate: $e');
    }
  }
  
  bool _isWalletSupported(WalletType type) {
    return const [
      WalletType.ethereum,
      WalletType.polygon,
      WalletType.litecoin,
      WalletType.bitcoin,
      WalletType.bitcoinCash,
      WalletType.zano,
    ].contains(type);
  }
  
  Future<String> _signMessage(
    WalletBase wallet,
    String message,
    String walletAddress,
  ) async {
    // Some wallets don't need address parameter, others do
    switch (wallet.type) {
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.solana:
      case WalletType.tron:
        return await wallet.signMessage(message);
      case WalletType.litecoin:
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
      case WalletType.zano:
        return await wallet.signMessage(message, address: walletAddress);
      default:
        return await wallet.signMessage(message, address: walletAddress);
    }
  }
  
  String _formatSignature(String signature, WalletType walletType) {
    switch (walletType) {
      case WalletType.ethereum:
      case WalletType.polygon:
        return signature.startsWith('0x') ? signature : '0x$signature';
      case WalletType.litecoin:
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
        return _formatBitcoinSignature(signature);
      case WalletType.zano:
        return signature;
      default:
        return signature;
    }
  }
  
  String _formatBitcoinSignature(String signature) {
    try {
      final bytes = base64.decode(signature);
      final hexString = bytes.sublist(1).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
      return '$hexString${bytes[0].toRadixString(16).padLeft(2, '0')}';
    } catch (e) {
      LoggerService.warning('Failed to format Bitcoin signature', error: e, tag: 'DFX');
      return signature;
    }
  }
  
  String getBlockchainName(WalletType walletType) {
    switch (walletType) {
      case WalletType.ethereum:
        return 'Ethereum';
      case WalletType.polygon:
        return 'Polygon';
      case WalletType.bitcoinCash:
      case WalletType.litecoin:
      case WalletType.bitcoin:
        return 'Bitcoin';
      case WalletType.zano:
        return 'Zano';
      default:
        return walletTypeToString(walletType);
    }
  }
}

class UnsupportedWalletException implements Exception {
  final WalletType walletType;
  
  UnsupportedWalletException(this.walletType);
  
  @override
  String toString() => 'WalletType ${walletType} is not supported for DFX';
}

class AuthenticationException implements Exception {
  final String message;
  
  AuthenticationException(this.message);
  
  @override
  String toString() => message;
}

String walletTypeToString(WalletType type) {
  return type.toString().split('.').last;
}