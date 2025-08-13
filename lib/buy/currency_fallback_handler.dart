import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/core/logger_service.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_provider_config.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/payment_method.dart';

class CurrencyFallbackHandler {
  final BuyProviderConfig _config = BuyProviderConfig();
  
  final List<BuyProvider> providers;
  final CryptoCurrency cryptoCurrency;
  final double amount;
  final String walletAddress;
  final bool isBuyAction;
  final PaymentMethod? paymentMethod;
  
  CurrencyFallbackHandler({
    required this.providers,
    required this.cryptoCurrency,
    required this.amount,
    required this.walletAddress,
    required this.isBuyAction,
    this.paymentMethod,
  });

  Future<CurrencyFallbackResult?> tryAllConfiguredFallbacks(FiatCurrency fromCurrency) async {
    final fallbackCurrencies = _config.getFallbackCurrencies(fromCurrency);
    
    if (fallbackCurrencies.isEmpty) {
      LoggerService.debug('No fallback currencies configured for $fromCurrency', tag: 'CurrencyFallback');
      return null;
    }
    
    for (final fallbackCurrency in fallbackCurrencies) {
      LoggerService.info('Trying fallback from $fromCurrency to $fallbackCurrency', tag: 'CurrencyFallback');
      
      final result = await tryFallbackCurrency(
        fromCurrency: fromCurrency,
        toCurrency: fallbackCurrency,
      );
      
      if (result != null) {
        return result;
      }
    }
    
    LoggerService.info('All fallback currencies failed for $fromCurrency', tag: 'CurrencyFallback');
    return null;
  }
  
  Future<CurrencyFallbackResult?> tryFallbackCurrency({
    required FiatCurrency fromCurrency,
    required FiatCurrency toCurrency,
  }) async {
    LoggerService.info('Attempting currency fallback from $fromCurrency to $toCurrency for $cryptoCurrency', tag: 'CurrencyFallback');
    
    final eligibleProviders = _getEligibleProviders(toCurrency);
    
    if (eligibleProviders.isEmpty) {
      LoggerService.debug('No eligible providers found for $toCurrency', tag: 'CurrencyFallback');
      return null;
    }
    
    final quotes = await _fetchQuotes(eligibleProviders, toCurrency);
    
    if (quotes.isEmpty) {
      LoggerService.debug('No valid quotes received for $toCurrency', tag: 'CurrencyFallback');
      return null;
    }
    
    LoggerService.info('Successfully obtained ${quotes.length} quotes for $toCurrency', tag: 'CurrencyFallback');
    return CurrencyFallbackResult(
      currency: toCurrency,
      quotes: quotes,
      message: 'Automatically switched from $fromCurrency to $toCurrency for better provider support',
    );
  }
  
  List<BuyProvider> _getEligibleProviders(FiatCurrency targetCurrency) {
    return providers.where((provider) {
      if (isBuyAction) {
        return provider.supportedCryptoList.any((pair) =>
            pair.from == cryptoCurrency && pair.to == targetCurrency);
      } else {
        return provider.supportedFiatList.any((pair) =>
            pair.from == targetCurrency && pair.to == cryptoCurrency);
      }
    }).toList();
  }
  
  Future<List<Quote>> _fetchQuotes(
    List<BuyProvider> providers,
    FiatCurrency currency,
  ) async {
    final quotesFutures = providers.map((provider) => 
      _fetchQuoteWithTimeout(provider, currency)
    );
    
    final results = await Future.wait(quotesFutures);
    
    return results
        .where((quotes) => quotes != null && quotes.isNotEmpty)
        .expand((quotes) => quotes!)
        .toList();
  }
  
  Future<List<Quote>?> _fetchQuoteWithTimeout(
    BuyProvider provider,
    FiatCurrency currency,
  ) async {
    try {
      return await provider
          .fetchQuote(
            cryptoCurrency: cryptoCurrency,
            fiatCurrency: currency,
            amount: amount,
            paymentType: paymentMethod?.paymentMethodType,
            isBuyAction: isBuyAction,
            walletAddress: walletAddress,
            customPaymentMethodType: paymentMethod?.customPaymentMethodType,
          )
          .timeout(_config.quoteTimeout, onTimeout: () => null);
    } catch (e) {
      LoggerService.warning('Error fetching quote from ${provider.title}', error: e, tag: 'CurrencyFallback');
      return null;
    }
  }
}

class CurrencyFallbackResult {
  final FiatCurrency currency;
  final List<Quote> quotes;
  final String message;
  
  CurrencyFallbackResult({
    required this.currency,
    required this.quotes,
    required this.message,
  });
}