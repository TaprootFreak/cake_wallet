import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cake_wallet/buy/currency_fallback_handler.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/fiat_currency.dart';

// Mock classes
class MockBuyProvider extends Mock implements BuyProvider {}
class MockQuote extends Mock implements Quote {}

void main() {
  group('CurrencyFallbackHandler', () {
    late MockBuyProvider mockProvider1;
    late MockBuyProvider mockProvider2;
    late MockQuote mockQuote1;
    late MockQuote mockQuote2;

    setUp(() {
      mockProvider1 = MockBuyProvider();
      mockProvider2 = MockBuyProvider();
      mockQuote1 = MockQuote();
      mockQuote2 = MockQuote();
    });

    test('should return fallback result when EUR quotes are available', () async {
      // Arrange
      final handler = CurrencyFallbackHandler(
        providers: [mockProvider1, mockProvider2],
        cryptoCurrency: CryptoCurrency.btc,
        amount: 100.0,
        walletAddress: 'test_address',
        isBuyAction: true,
      );

      // Setup provider 1 to support EUR
      when(mockProvider1.supportedCryptoList).thenReturn([
        CryptoPairProvider(from: CryptoCurrency.btc, to: FiatCurrency.eur),
      ]);
      when(mockProvider1.fetchQuote(
        cryptoCurrency: CryptoCurrency.btc,
        fiatCurrency: FiatCurrency.eur,
        amount: 100.0,
        paymentType: null,
        isBuyAction: true,
        walletAddress: 'test_address',
        customPaymentMethodType: null,
      )).thenAnswer((_) async => [mockQuote1]);

      // Setup provider 2 to not support EUR
      when(mockProvider2.supportedCryptoList).thenReturn([]);

      // Act
      final result = await handler.tryFallbackCurrency(
        fromCurrency: FiatCurrency.usd,
        toCurrency: FiatCurrency.eur,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.currency, equals(FiatCurrency.eur));
      expect(result.quotes, contains(mockQuote1));
      expect(result.message, contains('USD to EUR'));
    });

    test('should return null when no providers support fallback currency', () async {
      // Arrange
      final handler = CurrencyFallbackHandler(
        providers: [mockProvider1, mockProvider2],
        cryptoCurrency: CryptoCurrency.btc,
        amount: 100.0,
        walletAddress: 'test_address',
        isBuyAction: true,
      );

      // Both providers don't support EUR
      when(mockProvider1.supportedCryptoList).thenReturn([]);
      when(mockProvider2.supportedCryptoList).thenReturn([]);

      // Act
      final result = await handler.tryFallbackCurrency(
        fromCurrency: FiatCurrency.usd,
        toCurrency: FiatCurrency.eur,
      );

      // Assert
      expect(result, isNull);
    });

    test('should return null when providers support currency but quotes fail', () async {
      // Arrange
      final handler = CurrencyFallbackHandler(
        providers: [mockProvider1],
        cryptoCurrency: CryptoCurrency.btc,
        amount: 100.0,
        walletAddress: 'test_address',
        isBuyAction: true,
      );

      // Provider supports EUR but quote fails
      when(mockProvider1.supportedCryptoList).thenReturn([
        CryptoPairProvider(from: CryptoCurrency.btc, to: FiatCurrency.eur),
      ]);
      when(mockProvider1.fetchQuote(
        cryptoCurrency: any,
        fiatCurrency: any,
        amount: any,
        paymentType: any,
        isBuyAction: any,
        walletAddress: any,
        customPaymentMethodType: any,
      )).thenAnswer((_) async => null);

      // Act
      final result = await handler.tryFallbackCurrency(
        fromCurrency: FiatCurrency.usd,
        toCurrency: FiatCurrency.eur,
      );

      // Assert
      expect(result, isNull);
    });

    test('should handle sell action correctly', () async {
      // Arrange
      final handler = CurrencyFallbackHandler(
        providers: [mockProvider1],
        cryptoCurrency: CryptoCurrency.btc,
        amount: 100.0,
        walletAddress: 'test_address',
        isBuyAction: false, // Sell action
      );

      // Provider supports EUR for selling
      when(mockProvider1.supportedFiatList).thenReturn([
        CryptoFiatProvider(from: FiatCurrency.eur, to: CryptoCurrency.btc),
      ]);
      when(mockProvider1.fetchQuote(
        cryptoCurrency: CryptoCurrency.btc,
        fiatCurrency: FiatCurrency.eur,
        amount: 100.0,
        paymentType: null,
        isBuyAction: false,
        walletAddress: 'test_address',
        customPaymentMethodType: null,
      )).thenAnswer((_) async => [mockQuote1]);

      // Act
      final result = await handler.tryFallbackCurrency(
        fromCurrency: FiatCurrency.usd,
        toCurrency: FiatCurrency.eur,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.currency, equals(FiatCurrency.eur));
      expect(result.quotes.length, equals(1));
    });

    test('should handle quote timeout gracefully', () async {
      // Arrange
      final handler = CurrencyFallbackHandler(
        providers: [mockProvider1, mockProvider2],
        cryptoCurrency: CryptoCurrency.btc,
        amount: 100.0,
        walletAddress: 'test_address',
        isBuyAction: true,
      );

      // Provider 1 times out
      when(mockProvider1.supportedCryptoList).thenReturn([
        CryptoPairProvider(from: CryptoCurrency.btc, to: FiatCurrency.eur),
      ]);
      when(mockProvider1.fetchQuote(
        cryptoCurrency: any,
        fiatCurrency: any,
        amount: any,
        paymentType: any,
        isBuyAction: any,
        walletAddress: any,
        customPaymentMethodType: any,
      )).thenAnswer((_) async {
        await Future.delayed(Duration(seconds: 15)); // Longer than timeout
        return [mockQuote1];
      });

      // Provider 2 responds normally
      when(mockProvider2.supportedCryptoList).thenReturn([
        CryptoPairProvider(from: CryptoCurrency.btc, to: FiatCurrency.eur),
      ]);
      when(mockProvider2.fetchQuote(
        cryptoCurrency: any,
        fiatCurrency: any,
        amount: any,
        paymentType: any,
        isBuyAction: any,
        walletAddress: any,
        customPaymentMethodType: any,
      )).thenAnswer((_) async => [mockQuote2]);

      // Act
      final result = await handler.tryFallbackCurrency(
        fromCurrency: FiatCurrency.usd,
        toCurrency: FiatCurrency.eur,
      );

      // Assert
      expect(result, isNotNull);
      expect(result!.quotes, contains(mockQuote2));
      expect(result.quotes, isNot(contains(mockQuote1))); // Timed out quote not included
    });
  });
}