import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';

/// Manages wallet address requirements for different buy/sell providers
class ProviderWalletAddressManager {
  final WalletBase wallet;
  final CryptoCurrency cryptoCurrency;
  final BuyProvider? provider;
  
  ProviderWalletAddressManager({
    required this.wallet,
    required this.cryptoCurrency,
    this.provider,
  });
  
  /// Returns the appropriate wallet address based on provider requirements
  String getWalletAddress() {
    // DFX always needs wallet address for authentication
    if (_isDfxProvider()) {
      return wallet.walletAddresses.address;
    }
    
    // For other providers, only provide address when buying the wallet's native currency
    if (cryptoCurrency == wallet.currency) {
      return wallet.walletAddresses.address;
    }
    
    // Return empty for cross-currency purchases on non-DFX providers
    return '';
  }
  
  bool _isDfxProvider() {
    // Check by type name for more reliable detection
    final currentProvider = provider;
    if (currentProvider == null) return false;
    final providerType = currentProvider.runtimeType.toString().toLowerCase();
    return providerType.contains('dfx') || (currentProvider.title?.toLowerCase().contains('dfx') ?? false);
  }
  
  /// Checks if wallet address is required for the current transaction
  bool isWalletAddressRequired() {
    return _isDfxProvider() || cryptoCurrency == wallet.currency;
  }
}