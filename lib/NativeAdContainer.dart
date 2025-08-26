import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdContainer extends StatefulWidget {
  const NativeAdContainer({super.key});

  @override
  _NativeAdContainerState createState() => _NativeAdContainerState();
}

class _NativeAdContainerState extends State<NativeAdContainer> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  final double _adHeight = 260; // Adjust as needed

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId:
          'ca-app-pub-7069979473754845/1196454253', // Replace with your real ad unit
      factoryId:
          'adFactoryExample', // Only needed if using custom factory (can ignore if using template)
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        callToActionTextStyle: NativeTemplateTextStyle(
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black87,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
      request: AdRequest(),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      height: _adHeight,
      alignment: Alignment.center,
      child: _isAdLoaded
          ? AdWidget(ad: _nativeAd!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
