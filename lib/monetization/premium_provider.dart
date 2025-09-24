import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'revenuecat_keys.dart';

class PremiumController extends ChangeNotifier {
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  CustomerInfo? _customerInfo;
  CustomerInfo? get customerInfo => _customerInfo;

  Future<void> initialize({required String apiKey}) async {
    // Guard: if API key is missing or placeholder, skip initialization safely
    if (apiKey.isEmpty || apiKey.contains('REVENUECAT_')) {
      return;
    }
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _customerInfo = await Purchases.getCustomerInfo();
    _isPremium = _hasPremium(_customerInfo);
    notifyListeners();
    Purchases.addCustomerInfoUpdateListener((CustomerInfo info) {
      _customerInfo = info;
      final premium = _hasPremium(info);
      if (premium != _isPremium) {
        _isPremium = premium;
        notifyListeners();
      }
    });
  }

  bool _hasPremium(CustomerInfo? info) {
    if (info == null) return false;
    // Use the entitlement id configured in RevenueCat
    final ent = info.entitlements.all[kPremiumEntitlementId];
    return ent?.isActive == true;
  }

  Future<void> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    _customerInfo = info;
    final premium = _hasPremium(info);
    if (premium != _isPremium) {
      _isPremium = premium;
      notifyListeners();
    }
  }

  Future<bool> purchasePremium() async {
    try {
      final offerings = await Purchases.getOfferings();
      final pkg = offerings.current?.availablePackages.first;
      if (pkg == null) return false;
  // Using purchasePackage for compatibility (API variants may differ by SDK version)
  // ignore: deprecated_member_use
  await Purchases.purchasePackage(pkg);
      // Listener will update _isPremium if entitlement becomes active
      return true;
    } on PurchasesErrorCode catch (e) {
      // Ignore user cancellations
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

}
