import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class Ads {
  static Future<InitializationStatus> initialize() {
    return MobileAds.instance.initialize();
  }
}

class BannerAdContainer extends StatefulWidget {
  const BannerAdContainer({super.key, this.unitId});

  final String? unitId; // if null, uses test unit

  @override
  State<BannerAdContainer> createState() => _BannerAdContainerState();
}

class _BannerAdContainerState extends State<BannerAdContainer> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final defaultTestUnitId = Platform.isIOS
        ? 'ca-app-pub-3940256099942544/2934735716' // iOS banner test unit
        : 'ca-app-pub-3940256099942544/6300978111'; // Android banner test unit
    _ad = BannerAd(
      size: AdSize.banner,
      adUnitId: widget.unitId ?? defaultTestUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
