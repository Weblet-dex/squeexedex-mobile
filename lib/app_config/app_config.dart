import 'package:flutter/material.dart';

import '../model/feed_provider.dart';
import '../screens/help-feedback/support_channel_item.dart';

AppConfig appConfig = AppConfig();

class AppConfig {
  int get maxCoinsEnabledAndroid => 50;
  int get maxCoinEnabledIOS => 20;

  String get transactionWarningInfoUrl =>
      'https://atomicdex.io/en/blog/preventing-address-poisoning';

  // number of decimal places for trade amount input fields
  int get tradeFormPrecision => 8;

  int get batteryLevelLow => 30; // show warnign on swap confirmation page
  int get batteryLevelCritical => 20; // swaps disabled

  // Brand config below

  String get appName => 'atomicDEX';
  String get appCompanyLong => 'Komodo Platform';
  String get appCompanyShort => 'Komodo';

  List<String> get defaultCoins => ['KMD', 'BTC', 'VOTE2023'];
  List<String> get coinsFiat => ['BTC', 'KMD'];
  List<String> get walletOnlyCoins => [
        'ARRR-BEP20',
        'ATOM',
        'RBTC',
        'OSMO',
        'BET',
        'BOTS',
        'CELR-ARB20',
        'CRYPTO',
        'HODL',
        'JUMBLR',
        'LUNA-ERC20',
        'LUNA-BEP20',
        'LUNA-HRC20',
        'LUNA-PLG20',
        'MSHARK',
        'PAXG-ERC20',
        'ETH-ARB20',
        'ETHK-OPT20',
        'ETHR-ARB20',
        'USDT-ARB20',
        'USDT-ERC20',
        'MGW',
        'DEX',
        'PANGEA',
        'REVS',
        'SUPERNET',
        'NVC',
        'UST-ERC20',
        'UST-BEP20',
        'UST-HRC20',
        'UST-PLG20',
        'XPM',
        'XVC-OLD',
        'VOTE2023'
      ];

  List<String> get protocolSuffixes => [
        'QRC20',
        'ERC20',
        'BEP20',
        'PLG20',
        'FTM20',
        'HRC20',
        'MVR20',
        'HCO20',
        'KRC20',
        'AVX20',
        'SLP',
        'OLD',
        'IBC_IRIS',
        'segwit',
      ];
  List<String> get defaultTestCoins => ['RICK', 'MORTY'];
  Map<String, String> get allProtocolNames => {
        'utxo': 'UTXO',
        'smartChain': 'Smart Chain',
        'erc': 'Ethereum (ERC-20)',
        'bep': 'Binance (BEP-20)',
        'qrc': 'QTUM (QRC-20)',
        'plg': 'Polygon (PLG-20)',
        'ftm': 'Fantom (FTM-20)',
        'hrc': 'Harmony (HRC-20)',
        'avx': 'Avax (AVX-20)',
        'hco': 'HecoChain (HCO-20)',
        'mvr': 'Moonriver (MVR-20)',
        'krc': 'Kucoin (KRC-20)',
        'ubiq': 'Ubiq',
        'etc': 'Ethereum Classic (ETC)',
        'sbch': 'SmartBCH (SBCH)',
        'slp': 'SLP Tokens',
        'iris': 'Iris Network',
        'cosmos': 'Cosmos Network',
      };

  // ERC: [0]= limit , [1] = gwei
  // smartchains : [0] = fee
  Map<String, List<double>> standardFees = {
    'utxo': [0],
    'smartChain': [0],
    'erc': [0, 0],
    'bep': [0, 0],
    'qrc': [0, 0],
    'plg': [0, 0],
    'ftm': [0, 0],
    'hrc': [0, 0],
    'avx': [0, 0],
    'hco': [0, 0],
    'mvr': [0, 0],
    'krc': [0, 0],
    'ubiq': [0, 0],
    'etc': [0, 0],
    'sbch': [0, 0],
    'slp': [0, 0],
  };

  bool get isSwapShareCardEnabled => true;

  // support channels (showed on help page)
  List<SupportChannel> supportChannels = [
    SupportChannel(
      title: 'DISCORD',
      subtitle: 'Komodo #support',
      link: 'https://komodoplatform.com/discord',
      icon: SizedBox(
        width: 60,
        child: Image.asset('assets/discord_logo.png'),
      ),
    ),
  ];

  // endpoint source code:
  // https://github.com/KomodoPlatform/discord_feed_parser
  bool get isFeedEnabled => true;
  String get feedProviderSourceUrl => 'https://komodo.live/messages';
  NewsSource get defaultNewsSource => NewsSource(
        name: 'Komodo #official-news',
        url:
            'https://discord.com/channels/412898016371015680/412915799251222539',
        pic:
            'https://cdn.discordapp.com/icons/412898016371015680/a_157cb08c4198ad53b9e9b7168c930571.png',
      );

  // endpoint source code (currently same as news feed endpoint):
  // https://github.com/KomodoPlatform/discord_feed_parser
  bool get isUpdateCheckerEnabled => true;
  String get updateCheckerEndpoint => 'https://komodo.live/adexversion';

  // endpoint source code:
  // https://github.com/KomodoPlatform/mobile_endpoints_proxy/blob/main/main.py#L113
  String get fiatPricesEndpoint => 'https://rates.komodo.live/api/v1/usd_rates';

  // endpoint source code:
  // https://github.com/KomodoPlatform/mobile_endpoints_proxy/blob/main/main.py#L95
  String get cryptoPricesEndpoint =>
      'https://prices.komodo.live:1313/api/v2/tickers?expire_at=600';
  String get cryptoPricesFallback =>
      'https://api.coingecko.com/api/v3/simple/price?ids=';

  // endpoint source code:
  // https://github.com/KomodoPlatform/CexPricesEndpoint
  String get candlestickTickersList =>
      'https://komodo.live:3333/api/v1/ohlc/tickers_list';
  String get candlestickData => 'https://komodo.live:3333/api/v1/ohlc';

  // At the moment (8/24/2020) tx history is disabled on parity nodes,
  // so we switching ETH/ERC20, BNB/BEP20 tx history to
  // the web endpoint
  //
  // API calls:
  // '/api/v1/eth_tx_history/{address}' - ETH transaction history for address
  // '/api/v1/erc_tx_history/{token}/{address}' - ERC20 transaction history
  // endpoint source code:
  // https://github.com/KomodoPlatform/etherscan-mm2-proxy
  String get ethUrl => 'https://komodo.live:3334/api/v1/eth_tx_history';
  String get ercUrl => 'https://komodo.live:3334/api/v2/erc_tx_history';
  String get bnbUrl => 'https://komodo.live:3334/api/v1/bnb_tx_history';
  String get bepUrl => 'https://komodo.live:3334/api/v2/bep_tx_history';
  String get maticUrl => 'https://komodo.live:3334/api/v1/plg_tx_history';
  String get plgUrl => 'https://komodo.live:3334/api/v2/plg_tx_history';
  String get fantomUrl => 'https://komodo.live:3334/api/v1/ftm_tx_history';
  String get ftmUrl => 'https://komodo.live:3334/api/v2/ftm_tx_history';
  String get oneUrl => 'https://komodo.live:3334/api/v1/hrc_tx_history';
  String get hrcUrl => 'https://komodo.live:3334/api/v2/hrc_tx_history';
  String get movrUrl => 'https://komodo.live:3334/api/v1/moonriver_tx_history';
  String get mvrUrl => 'https://komodo.live:3334/api/v2/moonriver_tx_history';
  String get htUrl => 'https://komodo.live:3334/api/v1/heco_tx_history';
  String get hcoUrl => 'https://komodo.live:3334/api/v2/heco_tx_history';
  String get kcsUrl => 'https://komodo.live:3334/api/v1/krc_tx_history';
  String get krcUrl => 'https://komodo.live:3334/api/v2/krc_tx_history';
  String get etcUrl => 'https://komodo.live:3334/api/v1/etc_tx_history';
  String get sbchUrl => 'https://komodo.live:3334/api/v1/sbch_tx_history';
  String get ubqUrl => 'https://komodo.live:3334/api/v1/ubq_tx_history';
  String get avaxUrl => 'https://komodo.live:3334/api/v1/avx_tx_history';
  String get avxUrl => 'https://komodo.live:3334/api/v2/avx_tx_history';

  /// We're using different rpc ports for different wallet packages
  /// in order to allow multiple wallets to run simultaneously.
  int get rpcPort => 7783;
}
