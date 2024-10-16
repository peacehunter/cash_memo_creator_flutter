import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdContainer extends StatefulWidget {
  @override
  _NativeAdContainerState createState() => _NativeAdContainerState();
}

class _NativeAdContainerState extends State<NativeAdContainer> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  final double _adHeight = 260; // Slightly increased height for the ad container

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: 'ca-app-pub-7069979473754845/1196454253',
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white12,
        callToActionTextStyle: NativeTemplateTextStyle(
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black38,
          backgroundColor: Colors.white70,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ADS label positioned above the ad container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(left: 16.0, bottom: 0.0), // Positioned above the ad
          color: Colors.red,
          child: const Text(
            'ADS',
            style: TextStyle(
              color: Colors.white, // Text color
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Ad container with border
        Container(
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red, // Border color
              width: 2.0,        // Border width
            ),
            borderRadius: BorderRadius.circular(2.0), // Optional rounded corners
          ),
          height: _adHeight, // Fixed height for the ad container
          child: _isAdLoaded
              ? AdWidget(ad: _nativeAd!)
              : const Center(child: CircularProgressIndicator()), // Placeholder while loading
        ),
      ],
    );
  }
}
