import 'package:cake_wallet/entities/fiat_currency.dart';

/// Configuration for buy/sell provider features
class BuyProviderConfig {
  // Singleton instance
  static BuyProviderConfig? _instance;
  
  factory BuyProviderConfig() {
    _instance ??= BuyProviderConfig._internal();
    return _instance!;
  }
  
  BuyProviderConfig._internal();
  
  /// Dispose of the singleton instance and free resources
  static void dispose() {
    _instance?._cleanup();
    _instance = null;
  }
  
  void _cleanup() {
    // Clear all cached data
    _currencyFallbacks.clear();
    // Reset to defaults to free any held references
    _quoteTimeoutSeconds = 10;
    _authenticationTimeoutSeconds = 30;
    _providerLaunchTimeoutSeconds = 60;
    _maxRetryAttempts = 3;
    _retryDelayMilliseconds = 1000;
    _quoteCacheDurationSeconds = 30;
    _enableQuoteCache = true;
  }

  // Currency fallback configuration
  final Map<FiatCurrency, List<FiatCurrency>> _currencyFallbacks = {
    FiatCurrency.usd: [FiatCurrency.eur, FiatCurrency.gbp],
    FiatCurrency.cad: [FiatCurrency.usd, FiatCurrency.eur],
    FiatCurrency.aud: [FiatCurrency.usd, FiatCurrency.eur],
    FiatCurrency.chf: [FiatCurrency.eur, FiatCurrency.usd],
    FiatCurrency.jpy: [FiatCurrency.usd, FiatCurrency.eur],
  };

  // Timeout configuration (in seconds)
  int _quoteTimeoutSeconds = 10;
  int _authenticationTimeoutSeconds = 30;
  int _providerLaunchTimeoutSeconds = 60;

  // Retry configuration
  int _maxRetryAttempts = 3;
  int _retryDelayMilliseconds = 1000;
  
  // Cache configuration
  int _quoteCacheDurationSeconds = 30;
  bool _enableQuoteCache = true;

  // Getters
  List<FiatCurrency> getFallbackCurrencies(FiatCurrency from) {
    return _currencyFallbacks[from] ?? [];
  }

  Duration get quoteTimeout => Duration(seconds: _quoteTimeoutSeconds);
  Duration get authenticationTimeout => Duration(seconds: _authenticationTimeoutSeconds);
  Duration get providerLaunchTimeout => Duration(seconds: _providerLaunchTimeoutSeconds);
  
  int get maxRetryAttempts => _maxRetryAttempts;
  Duration get retryDelay => Duration(milliseconds: _retryDelayMilliseconds);
  
  Duration get quoteCacheDuration => Duration(seconds: _quoteCacheDurationSeconds);
  bool get isQuoteCacheEnabled => _enableQuoteCache;

  // Setters for runtime configuration
  void setQuoteTimeout(int seconds) {
    if (seconds > 0 && seconds <= 120) {
      _quoteTimeoutSeconds = seconds;
    }
  }

  void setAuthenticationTimeout(int seconds) {
    if (seconds > 0 && seconds <= 120) {
      _authenticationTimeoutSeconds = seconds;
    }
  }

  void setMaxRetryAttempts(int attempts) {
    if (attempts >= 0 && attempts <= 10) {
      _maxRetryAttempts = attempts;
    }
  }

  void setRetryDelay(int milliseconds) {
    if (milliseconds >= 0 && milliseconds <= 10000) {
      _retryDelayMilliseconds = milliseconds;
    }
  }

  void setQuoteCacheDuration(int seconds) {
    if (seconds >= 0 && seconds <= 300) {
      _quoteCacheDurationSeconds = seconds;
    }
  }

  void setQuoteCacheEnabled(bool enabled) {
    _enableQuoteCache = enabled;
  }

  void addCurrencyFallback(FiatCurrency from, FiatCurrency to) {
    if (!_currencyFallbacks.containsKey(from)) {
      _currencyFallbacks[from] = [];
    }
    if (!_currencyFallbacks[from]!.contains(to)) {
      _currencyFallbacks[from]!.add(to);
    }
  }

  void removeCurrencyFallback(FiatCurrency from, FiatCurrency to) {
    _currencyFallbacks[from]?.remove(to);
  }

  void clearCurrencyFallbacks(FiatCurrency from) {
    _currencyFallbacks[from]?.clear();
  }

  // Reset to defaults
  void resetToDefaults() {
    _quoteTimeoutSeconds = 10;
    _authenticationTimeoutSeconds = 30;
    _providerLaunchTimeoutSeconds = 60;
    _maxRetryAttempts = 3;
    _retryDelayMilliseconds = 1000;
    _quoteCacheDurationSeconds = 30;
    _enableQuoteCache = true;
    
    _currencyFallbacks.clear();
    _currencyFallbacks[FiatCurrency.usd] = [FiatCurrency.eur, FiatCurrency.gbp];
    _currencyFallbacks[FiatCurrency.cad] = [FiatCurrency.usd, FiatCurrency.eur];
    _currencyFallbacks[FiatCurrency.aud] = [FiatCurrency.usd, FiatCurrency.eur];
    _currencyFallbacks[FiatCurrency.chf] = [FiatCurrency.eur, FiatCurrency.usd];
    _currencyFallbacks[FiatCurrency.jpy] = [FiatCurrency.usd, FiatCurrency.eur];
  }

  // Load from JSON (for persistence)
  void loadFromJson(Map<String, dynamic> json) {
    if (json['quoteTimeoutSeconds'] != null) {
      setQuoteTimeout(json['quoteTimeoutSeconds'] as int);
    }
    if (json['authenticationTimeoutSeconds'] != null) {
      setAuthenticationTimeout(json['authenticationTimeoutSeconds'] as int);
    }
    if (json['maxRetryAttempts'] != null) {
      setMaxRetryAttempts(json['maxRetryAttempts'] as int);
    }
    if (json['retryDelayMilliseconds'] != null) {
      setRetryDelay(json['retryDelayMilliseconds'] as int);
    }
    if (json['quoteCacheDurationSeconds'] != null) {
      setQuoteCacheDuration(json['quoteCacheDurationSeconds'] as int);
    }
    if (json['enableQuoteCache'] != null) {
      setQuoteCacheEnabled(json['enableQuoteCache'] as bool);
    }
    
    // Load currency fallbacks
    if (json['currencyFallbacks'] != null) {
      _currencyFallbacks.clear();
      final fallbacks = json['currencyFallbacks'] as Map<String, dynamic>;
      fallbacks.forEach((key, value) {
        final fromCurrency = FiatCurrency.all.firstWhere(
          (e) => e.toString() == key,
          orElse: () => FiatCurrency.usd,
        );
        final toCurrencies = (value as List<dynamic>).map((e) {
          return FiatCurrency.all.firstWhere(
            (c) => c.toString() == e.toString(),
            orElse: () => FiatCurrency.eur,
          );
        }).toList();
        _currencyFallbacks[fromCurrency] = toCurrencies;
      });
    }
  }

  // Save to JSON (for persistence)
  Map<String, dynamic> toJson() {
    final fallbacksJson = <String, dynamic>{};
    _currencyFallbacks.forEach((key, value) {
      fallbacksJson[key.toString()] = value.map((e) => e.toString()).toList();
    });

    return {
      'quoteTimeoutSeconds': _quoteTimeoutSeconds,
      'authenticationTimeoutSeconds': _authenticationTimeoutSeconds,
      'providerLaunchTimeoutSeconds': _providerLaunchTimeoutSeconds,
      'maxRetryAttempts': _maxRetryAttempts,
      'retryDelayMilliseconds': _retryDelayMilliseconds,
      'quoteCacheDurationSeconds': _quoteCacheDurationSeconds,
      'enableQuoteCache': _enableQuoteCache,
      'currencyFallbacks': fallbacksJson,
    };
  }
}