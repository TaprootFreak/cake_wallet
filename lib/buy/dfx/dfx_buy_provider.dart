import 'dart:convert';

import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/dfx/dfx_authentication_service.dart';
import 'package:cake_wallet/core/logger_service.dart';
import 'package:cake_wallet/buy/pairs_utils.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DFXBuyProvider extends BuyProvider {
  DFXBuyProvider({
    required WalletBase wallet,
    bool isTestEnvironment = false,
    LedgerViewModel? ledgerVM,
  }) : super(
      wallet: wallet,
      isTestEnvironment: isTestEnvironment,
      ledgerVM: ledgerVM,
      supportedCryptoList: supportedCryptoToFiatPairs(
          notSupportedCrypto: _notSupportedCrypto, notSupportedFiat: _notSupportedFiat),
      supportedFiatList: supportedFiatToCryptoPairs(
          notSupportedFiat: _notSupportedFiat, notSupportedCrypto: _notSupportedCrypto)
  );

  static const _baseUrl = 'api.dfx.swiss';

  // static const _signMessagePath = '/v1/auth/signMessage';
  static const _authPath = '/v1/auth';
  static const walletName = 'CakeWallet';

  static const List<CryptoCurrency> _notSupportedCrypto = [];
  static const List<FiatCurrency> _notSupportedFiat = [];

  @override
  String get title => 'DFX.swiss';

  @override
  String get providerDescription => S.current.dfx_option_description;

  @override
  String get lightIcon => 'assets/images/dfx_light.png';

  @override
  String get darkIcon => 'assets/images/dfx_dark.png';

  @override
  bool get isAggregator => false;

  String get blockchain {
    final authService = DfxAuthenticationService();
    return authService.getBlockchainName(wallet.type);
  }


  Future<String> getSignMessage(String walletAddress) async =>
      "By_signing_this_message,_you_confirm_that_you_are_the_sole_owner_of_the_provided_Blockchain_address._Your_ID:_$walletAddress";

  // Lets keep this just in case, but we can avoid this API Call
  // Future<String> getSignMessage() async {
  //  final uri = Uri.https(_baseUrl, _signMessagePath, {'address': walletAddress});
  //
  //  final response = await http.get(uri, headers: {'accept': 'application/json'});
  //
  //  if (response.statusCode == 200) {
  //    final responseBody = jsonDecode(response.body);
  //    return responseBody['message'] as String;
  //  } else {
  //    throw Exception(
  //      'Failed to get sign message. Status: ${response.statusCode} ${response.body}');
  //  }
  // }

  Future<String> auth(String walletAddress) async {
    final signMessage = await getSignature(
        await getSignMessage(walletAddress), walletAddress);

    final requestBody = jsonEncode({
      'wallet': walletName,
      'address': walletAddress,
      'signature': signMessage,
    });

    final uri = Uri.https(_baseUrl, _authPath);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    

    if (response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      return responseBody['accessToken'] as String;
    } else if (response.statusCode == 403) {
      final responseBody = jsonDecode(response.body);
      final message = responseBody['message'] ?? 'Service unavailable in your country';
      throw Exception(message);
    } else {
      throw Exception('Failed to sign up. Status: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> getSignature(String message, String walletAddress) async {
    final authService = DfxAuthenticationService();
    return await authService.authenticate(
      wallet: wallet,
      walletAddress: walletAddress,
      message: message,
    );
  }

  Future<Map<String, dynamic>> fetchFiatCredentials(String fiatCurrency) async {
    final url = Uri.https(_baseUrl, '/v1/fiat');

    try {
      final response = await ProxyWrapper().get(
        clearnetUri: url,
        headers: {'accept': 'application/json'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        for (final item in data) {
          if (item['name'] == fiatCurrency) return item as Map<String, dynamic>;
        }
        LoggerService.warning('DFX does not support fiat: $fiatCurrency', tag: 'DFX');
        return {};
      } else {
        LoggerService.warning('DFX Failed to fetch fiat currencies: ${response.statusCode}', tag: 'DFX');
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching fiat currencies', error: e, tag: 'DFX');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchAssetCredential(String assetsName) async {
    final url = Uri.https(_baseUrl, '/v1/asset', {'blockchains': blockchain});
    LoggerService.debug('Fetching asset credential for: $assetsName, blockchain: $blockchain, URL: $url', tag: 'DFX');

    try {
      final response = await ProxyWrapper().get(clearnetUri: url, headers: {'accept': 'application/json'});
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        LoggerService.debug('Asset API response: $responseData', tag: 'DFX');

        if (responseData is List && responseData.isNotEmpty) {
          LoggerService.debug('Found ${responseData.length} assets', tag: 'DFX');
          for (final i in responseData) {
            LoggerService.debug('Checking asset: ${i["dexName"]} (buyable: ${i["buyable"]}, sellable: ${i["sellable"]})', tag: 'DFX');
            if (assetsName.toLowerCase() == i["dexName"].toString().toLowerCase()) {
              LoggerService.debug('Matched asset: $i', tag: 'DFX');
              return i as Map<String, dynamic>;
            }
          }
          LoggerService.debug('Asset not found, returning first available: ${responseData.first}', tag: 'DFX');
          return responseData.first as Map<String, dynamic>;
        } else if (responseData is Map<String, dynamic>) {
          LoggerService.debug('Single asset response: $responseData', tag: 'DFX');
          return responseData;
        } else {
          LoggerService.debug('Does not support this asset name : ${blockchain}', tag: 'DFX');
        }
      } else {
        LoggerService.debug('Failed to fetch assets: ${response.statusCode}, body: ${response.body}', tag: 'DFX');
      }
    } catch (e) {
      LoggerService.debug('Error fetching assets: $e', tag: 'DFX');
    }
    return {};
  }

  Future<List<PaymentMethod>> getAvailablePaymentTypes(
      String fiatCurrency, CryptoCurrency cryptoCurrency, bool isBuyAction) async {
    final List<PaymentMethod> paymentMethods = [];

    if (isBuyAction) {
      final fiatBuyCredentials = await fetchFiatCredentials(fiatCurrency);
      if (fiatBuyCredentials.isNotEmpty) {
        fiatBuyCredentials.forEach((key, value) {
          if (key == 'limits') {
            final limits = value as Map<String, dynamic>;
            limits.forEach((paymentMethodKey, paymentMethodValue) {
              final min = _toDouble(paymentMethodValue['minVolume']);
              final max = _toDouble(paymentMethodValue['maxVolume']);
              if (min != null && max != null && min > 0 && max > 0) {
                final paymentMethod = PaymentMethod.fromDFX(
                    paymentMethodKey, _getPaymentTypeByString(paymentMethodKey));
                paymentMethods.add(paymentMethod);
              }
            });
          }
        });
      }
    } else {
      final assetCredentials = await fetchAssetCredential(cryptoCurrency.title);
      if (assetCredentials.isNotEmpty) {
        if (assetCredentials['sellable'] == true) {
          final availablePaymentTypes = [
            PaymentType.bankTransfer,
            PaymentType.creditCard,
            PaymentType.sepa
          ];
          availablePaymentTypes.forEach((element) {
            final paymentMethod = PaymentMethod.fromDFX(normalizePaymentMethod(element)!, element);
            paymentMethods.add(paymentMethod);
          });
        }
      }
    }

    return paymentMethods;
  }

  @override
  Future<List<Quote>?> fetchQuote(
      {required CryptoCurrency cryptoCurrency,
      required FiatCurrency fiatCurrency,
      required double amount,
      required bool isBuyAction,
      required String walletAddress,
      PaymentType? paymentType,
      String? customPaymentMethodType,
      String? countryCode}) async {
    /// if buying with any currency other than eur or chf then DFX is not supported

    if (isBuyAction && (fiatCurrency != FiatCurrency.eur && fiatCurrency != FiatCurrency.chf)) {
      return null;
    }

    String? paymentMethod;
    if (paymentType != null && paymentType != PaymentType.all) {
      paymentMethod = normalizePaymentMethod(paymentType);
      if (paymentMethod == null) paymentMethod = paymentType.name;
    } else {
      paymentMethod = 'Bank';
    }

    final action = isBuyAction ? 'buy' : 'sell';

    final fiatCredentials = await fetchFiatCredentials(fiatCurrency.name.toString());
    if (fiatCredentials['id'] == null) return null;

    final assetCredentials = await fetchAssetCredential(cryptoCurrency.title.toString());
    if (assetCredentials['id'] == null) return null;
    
    // Check if asset is buyable/sellable for this action
    final actionKey = isBuyAction ? 'buyable' : 'sellable';
    if (assetCredentials[actionKey] != true) {
      LoggerService.debug('Asset ${cryptoCurrency.title} is not ${actionKey} (${actionKey}: ${assetCredentials[actionKey]})', tag: 'DFX');
      return null;
    }

    LoggerService.debug('Fetching $action quote: ${isBuyAction ? cryptoCurrency : fiatCurrency} -> ${isBuyAction ? fiatCurrency : cryptoCurrency}, amount: $amount, paymentMethod: $paymentMethod', tag: 'DFX');
    LoggerService.debug('FiatCredentials: $fiatCredentials', tag: 'DFX');
    LoggerService.debug('AssetCredentials: $assetCredentials', tag: 'DFX');

    final url = Uri.https(_baseUrl, '/v1/$action/quote');
    final headers = {'accept': 'application/json', 'Content-Type': 'application/json'};
    final body = jsonEncode({
      'currency': {'id': fiatCredentials['id'] as int},
      'asset': {'id': assetCredentials['id']},
      'amount': amount,
      'targetAmount': 0,
      'paymentMethod': paymentMethod,
      'discountCode': ''
    });
    LoggerService.debug('Request URL: $url', tag: 'DFX');
    LoggerService.debug('Request body: $body', tag: 'DFX');

    try {
      final response = await ProxyWrapper().put(
        clearnetUri: url,
        headers: headers,
        body: body,
      );
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData is Map<String, dynamic>) {
          final paymentType = _getPaymentTypeByString(responseData['paymentMethod'] as String?);
          final quote = Quote.fromDFXJson(responseData, isBuyAction, paymentType);
          quote.setFiatCurrency = fiatCurrency;
          quote.setCryptoCurrency = cryptoCurrency;
          return [quote];
        } else {
          LoggerService.warning('Unexpected data type: ${responseData.runtimeType}', tag: 'DFX');
          return null;
        }
      } else {
        LoggerService.debug('HTTP Status Code: ${response.statusCode}', tag: 'DFX');
        LoggerService.debug('Response body: ${response.body}', tag: 'DFX');
        if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
          LoggerService.warning('Error: ${responseData['message']}', tag: 'DFX');
        } else {
          LoggerService.warning('Failed to fetch buy quote: ${response.statusCode}', tag: 'DFX');
        }
        return null;
      }
    } catch (e) {
      LoggerService.error('Error fetching buy quote', error: e, tag: 'DFX');
      return null;
    }
  }

  Future<void>? launchProvider(
      {required BuildContext context,
      required Quote quote,
      required double amount,
      required bool isBuyAction,
      required String cryptoCurrencyAddress,
      String? countryCode}) async {
    if (wallet.isHardwareWallet) {
      if (!ledgerVM!.isConnected) {
        await Navigator.of(context).pushNamed(Routes.connectDevices,
            arguments: ConnectDevicePageParams(
                walletType: wallet.walletInfo.type,
                onConnectDevice: (BuildContext context, LedgerViewModel ledgerVM) {
                  ledgerVM.setLedger(wallet);
                  Navigator.of(context).pop();
                }));
      } else {
        ledgerVM!.setLedger(wallet);
      }
    }

    try {
      final actionType = isBuyAction ? '/buy' : '/sell';

      final accessToken = await auth(cryptoCurrencyAddress);

      final uri = Uri.https('app.dfx.swiss', actionType, {
        'session': accessToken,
        'lang': 'en',
        'asset-out': isBuyAction ? quote.cryptoCurrency.toString() : quote.fiatCurrency.toString(),
        'blockchain': blockchain,
        'asset-in': isBuyAction ? quote.fiatCurrency.toString() : quote.cryptoCurrency.toString(),
        'amount': amount.toString() //TODO: Amount does not work
      });

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: "DFX.swiss",
                alertContent: S.of(context).buy_provider_unavailable + ': $e',
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    }
  }

  String? normalizePaymentMethod(PaymentType paymentMethod) {
    switch (paymentMethod) {
      case PaymentType.bankTransfer:
        return 'Bank';
      case PaymentType.creditCard:
        return 'Card';
      case PaymentType.sepa:
        return 'Instant';
      default:
        return null;
    }
  }

  PaymentType _getPaymentTypeByString(String? paymentMethod) {
    switch (paymentMethod) {
      case 'Bank':
        return PaymentType.bankTransfer;
      case 'Card':
        return PaymentType.creditCard;
      case 'Instant':
        return PaymentType.sepa;
      default:
        return PaymentType.unknown;
    }
  }

  double? _toDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    }
    return null;
  }
}
