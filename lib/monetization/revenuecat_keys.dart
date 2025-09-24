/// RevenueCat SDK keys and identifiers.
///
/// Replace the placeholder values with your real Public SDK keys from
/// https://app.revenuecat.com (Projects -> your project -> API keys -> Public SDK Key)
///
/// Also ensure you have created an entitlement with the identifier below
/// and that your products are attached to an offering that unlocks it.

// iOS Public SDK key (NOT the secret key). Example: "appl_XXXXXXXXXXXXXXXXXXXXXX"
const String kRevenueCatApiKeyIOS = 'REVENUECAT_IOS_PUBLIC_SDK_KEY_HERE';

// Android Public SDK key. Example: "goog_XXXXXXXXXXXXXXXXXXXXXX"
const String kRevenueCatApiKeyAndroid = 'REVENUECAT_ANDROID_PUBLIC_SDK_KEY_HERE';

// Your entitlement identifier as configured in RevenueCat dashboard.
// We assume 'premium' throughout the app; change here if you used a different id.
const String kPremiumEntitlementId = 'premium';
