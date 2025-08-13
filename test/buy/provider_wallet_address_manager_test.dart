import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cake_wallet/buy/provider_wallet_address_manager.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_addresses.dart';

// Mock classes
class MockWalletBase extends Mock implements WalletBase {}
class MockWalletAddresses extends Mock implements WalletAddresses {}
class MockBuyProvider extends Mock implements BuyProvider {}

void main() {
  group('ProviderWalletAddressManager', () {
    late MockWalletBase mockWallet;
    late MockWalletAddresses mockWalletAddresses;
    late MockBuyProvider mockProvider;
    const testAddress = 'test_wallet_address_123';

    setUp(() {
      mockWallet = MockWalletBase();
      mockWalletAddresses = MockWalletAddresses();
      mockProvider = MockBuyProvider();
      
      when(mockWallet.walletAddresses).thenReturn(mockWalletAddresses);
      when(mockWalletAddresses.address).thenReturn(testAddress);
    });

    group('getWalletAddress', () {
      test('should return wallet address for DFX provider regardless of currency', () {
        // Arrange
        when(mockProvider.title).thenReturn('DFX');
        when(mockWallet.currency).thenReturn(CryptoCurrency.btc);
        
        final manager = ProviderWalletAddressManager(
          wallet: mockWallet,
          cryptoCurrency: CryptoCurrency.eth, // Different from wallet currency
          provider: mockProvider,
        );

        // Act
        final result = manager.getWalletAddress();

        // Assert
        expect(result, equals(testAddress));
      });

      test('should detect DFX provider by runtime type', () {
        // Arrange
        when(mockProvider.title).thenReturn('Some Other Name');
        when(mockProvider.runtimeType.toString()).thenReturn('DFXBuyProvider');
        when(mockWallet.currency).thenReturn(CryptoCurrency.btc);
        
        final manager = ProviderWalletAddressManager(
          wallet: mockWallet,
          cryptoCurrency: CryptoCurrency.eth,
          provider: mockProvider,
        );

        // Act
        final result = manager.getWalletAddress();

        // Assert
        expect(result, equals(testAddress));
      });

      test('should return wallet address when buying native currency', () {
        // Arrange
        when(mockProvider.title).thenReturn('OnRamper');
        when(mockWallet.currency).thenReturn(CryptoCurrency.btc);
        
        final manager = ProviderWalletAddressManager(
          wallet: mockWallet,
          cryptoCurrency: CryptoCurrency.btc, // Same as wallet currency
          provider: mockProvider,
        );

        // Act
        final result = manager.getWalletAddress();

        // Assert
        expect(result, equals(testAddress));
      });

      test('should return empty string for non-DFX provider with different currency', () {
        // Arrange
        when(mockProvider.title).thenReturn('OnRamper');
        when(mockWallet.currency).thenReturn(CryptoCurrency.btc);
        
        final manager = ProviderWalletAddressManager(
          wallet: mockWallet,
          cryptoCurrency: CryptoCurrency.eth, // Different from wallet currency
          provider: mockProvider,
        );

        // Act
        final result = manager.getWalletAddress();

        // Assert
        expect(result, equals(''));
      });

      test('should handle null provider correctly', () {
        // Arrange
        when(mockWallet.currency).thenReturn(CryptoCurrency.btc);
        
        final manager = ProviderWalletAddressManager(
          wallet: mockWallet,
          cryptoCurrency: CryptoCurrency.eth,
          provider: null,
        );

        // Act
        final result = manager.getWalletAddress();

        // Assert
        expect(result, equals(''));
      });
    });

    group('isWalletAddressRequired', () {
      test('should return true for DFX provider', () {
        // Arrange
        when(mockProvider.title).thenReturn('DFX');
        when(mockWallet.currency).thenReturn(CryptoCurrency.btc);
        
        final manager = ProviderWalletAddressManager(
          wallet: mockWallet,
          cryptoCurrency: CryptoCurrency.eth,
          provider: mockProvider,
        );

        // Act
        final result = manager.isWalletAddressRequired();

        // Assert
        expect(result, isTrue);
      });

      test('should return true when buying native currency', () {
        // Arrange
        when(mockProvider.title).thenReturn('OnRamper');
        when(mockWallet.currency).thenReturn(CryptoCurrency.btc);
        
        final manager = ProviderWalletAddressManager(
          wallet: mockWallet,
          cryptoCurrency: CryptoCurrency.btc,
          provider: mockProvider,
        );

        // Act
        final result = manager.isWalletAddressRequired();

        // Assert
        expect(result, isTrue);
      });

      test('should return false for non-DFX provider with different currency', () {
        // Arrange
        when(mockProvider.title).thenReturn('OnRamper');
        when(mockWallet.currency).thenReturn(CryptoCurrency.btc);
        
        final manager = ProviderWalletAddressManager(
          wallet: mockWallet,
          cryptoCurrency: CryptoCurrency.eth,
          provider: mockProvider,
        );

        // Act
        final result = manager.isWalletAddressRequired();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}