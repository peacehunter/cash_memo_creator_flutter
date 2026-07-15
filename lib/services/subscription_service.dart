import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  static SubscriptionService get instance => _instance;

  SubscriptionService._internal();

  bool _isProUser = false;
  bool get isProUser => _isProUser;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Single subscription product ID in Google Play Console
  static const String _kProductId = 'cash_memo_pro';

  // Base plan IDs within the single subscription (matches Play Console)
  static const String _kWeeklyBasePlanId  = 'weekly-plan';
  static const String _kMonthlyBasePlanId = 'monthly-plan';
  static const String _kYearlyBasePlanId  = 'yearly-plan';

  static const String _kCreationTimestampsKey = 'free_memo_creation_timestamps';
  static const int _kMaxFreeCreations = 5;

  /// Maps a plan index (0=Weekly, 1=Monthly, 2=Yearly) to a base plan ID.
  static String _basePlanId(int planIndex) {
    switch (planIndex) {
      case 0:  return _kWeeklyBasePlanId;
      case 1:  return _kMonthlyBasePlanId;
      default: return _kYearlyBasePlanId;
    }
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  /// Initializes billing and loads cached pro status.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isProUser = prefs.getBool('is_pro_user') ?? false;
    debugPrint('💳 [SubscriptionService] Initialized. Pro status: $_isProUser');
    notifyListeners();

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _purchaseSubscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (Object error) =>
          debugPrint('💳 [SubscriptionService] Billing stream error: $error'),
    );
  }

  // ─── Purchase ───────────────────────────────────────────────────────────

  /// Triggers the Google Play purchase flow for the selected plan index.
  /// planIndex: 0 = Weekly ($2.49), 1 = Monthly ($7.99), 2 = Yearly ($47.99)
  Future<void> purchaseSubscription(int planIndex) async {
    final String targetBasePlanId = _basePlanId(planIndex);
    debugPrint(
        '💳 [SubscriptionService] Purchasing base plan "$targetBasePlanId"'
        ' under product "$_kProductId"');

    final bool available = await _iap.isAvailable();
    if (!available) {
      throw Exception('Google Play Billing is not available on this device.');
    }

    // Query the single subscription product — Play returns one
    // GooglePlayProductDetails entry per base plan / offer combination.
    final ProductDetailsResponse response =
        await _iap.queryProductDetails({_kProductId});

    if (response.productDetails.isEmpty) {
      throw Exception(
        'Product "$_kProductId" not found in Google Play Store. '
        'Make sure base plans are active in Play Console.',
      );
    }

    if (Platform.isAndroid) {
      // Find the GooglePlayProductDetails whose subscriptionIndex points to
      // the SubscriptionOfferDetailsWrapper matching our base plan ID.
      GooglePlayProductDetails? matchedDetails;
      for (final ProductDetails pd in response.productDetails) {
        final GooglePlayProductDetails gpd = pd as GooglePlayProductDetails;
        final List<SubscriptionOfferDetailsWrapper>? offers =
            gpd.productDetails.subscriptionOfferDetails;
        if (offers == null) continue;

        final int idx = gpd.subscriptionIndex ?? 0;
        if (idx < offers.length && offers[idx].basePlanId == targetBasePlanId) {
          matchedDetails = gpd;
          break;
        }
      }

      if (matchedDetails == null) {
        throw Exception(
          'Base plan "$targetBasePlanId" not found in Play Console. '
          'Check that the base plan is created and activated.',
        );
      }

      final GooglePlayPurchaseParam purchaseParam = GooglePlayPurchaseParam(
        productDetails: matchedDetails,
        changeSubscriptionParam: null,
      );

      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      // iOS / other platforms
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: response.productDetails.first);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  /// Restore previous purchases.
  Future<void> restorePurchases() async {
    debugPrint('💳 [SubscriptionService] Restoring purchases...');
    await _iap.restorePurchases();
  }

  /// Cancel subscription locally (actual cancellation happens in Play Store).
  Future<void> cancelSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro_user', false);
    _isProUser = false;
    debugPrint('💳 [SubscriptionService] Subscription cancelled locally.');
    notifyListeners();
  }

  // ─── Purchase stream listener ────────────────────────────────────────────

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('💳 [SubscriptionService] Purchase pending...');
          break;
        case PurchaseStatus.error:
          debugPrint(
              '💳 [SubscriptionService] Purchase error: ${purchaseDetails.error}');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) await _setProStatus(true);
          if (purchaseDetails.pendingCompletePurchase) {
            await _iap.completePurchase(purchaseDetails);
          }
          break;
        default:
          break;
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: In production, verify the purchaseToken with the
    // Google Play Developer API via a secure backend server.
    return true;
  }

  Future<void> _setProStatus(bool isPro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro_user', isPro);
    _isProUser = isPro;
    debugPrint('💳 [SubscriptionService] Pro status set to: $isPro');
    notifyListeners();
  }

  // ─── Free-tier creation limits ───────────────────────────────────────────

  /// Returns true if the user can create another memo.
  Future<bool> canCreateMemo() async {
    if (_isProUser) return true;

    final prefs = await SharedPreferences.getInstance();
    final List<String> timestamps =
        prefs.getStringList(_kCreationTimestampsKey) ?? [];
    final DateTime cutoff =
        DateTime.now().subtract(const Duration(hours: 24));

    final List<String> active = timestamps.where((t) {
      try {
        return DateTime.parse(t).isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();

    if (active.length != timestamps.length) {
      await prefs.setStringList(_kCreationTimestampsKey, active);
    }

    return active.length < _kMaxFreeCreations;
  }

  /// Records a memo creation timestamp for free-tier tracking.
  Future<void> recordMemoCreation() async {
    if (_isProUser) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> timestamps =
        prefs.getStringList(_kCreationTimestampsKey) ?? [];

    timestamps.add(DateTime.now().toIso8601String());

    final DateTime cutoff =
        DateTime.now().subtract(const Duration(hours: 24));
    final List<String> active = timestamps.where((t) {
      try {
        return DateTime.parse(t).isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();

    await prefs.setStringList(_kCreationTimestampsKey, active);
    debugPrint(
        '💳 [SubscriptionService] Memo recorded. Active (24h): ${active.length}');
  }

  /// Returns remaining free creations in 24 h (-1 = unlimited for Pro).
  Future<int> getRemainingCreations() async {
    if (_isProUser) return -1;

    final prefs = await SharedPreferences.getInstance();
    final List<String> timestamps =
        prefs.getStringList(_kCreationTimestampsKey) ?? [];
    final DateTime cutoff =
        DateTime.now().subtract(const Duration(hours: 24));

    final int active = timestamps.where((t) {
      try {
        return DateTime.parse(t).isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).length;

    return (_kMaxFreeCreations - active).clamp(0, _kMaxFreeCreations);
  }
}
