import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/features/onboarding/screens/onboarding_screen.dart';
import '../../presentation/features/auth/screens/login_screen.dart';
import '../../presentation/features/auth/screens/register_screen_v2.dart';
import '../../presentation/features/auth/screens/otp_screen.dart';
import '../../presentation/features/auth/screens/forgot_password_screen.dart';
import '../../presentation/features/dashboard/screens/dashboard_screen.dart';
import '../../presentation/features/airtime/screens/air_menu_screen.dart';
import '../../presentation/features/airtime/screens/select_recipient_screen.dart';
import '../../presentation/features/airtime/screens/enter_amount_screen.dart';
import '../../presentation/features/airtime/screens/confirm_transaction_screen.dart';
import '../../presentation/features/airtime/screens/select_country_screen.dart';
import '../../presentation/features/airtime/screens/enter_phone_screen.dart';
import '../../presentation/features/airtime/screens/select_amount_screen.dart';
import '../../presentation/features/airtime/screens/confirm_airtime_screen.dart';
import '../../presentation/features/airtime/screens/airtime_converter_screen.dart';
import '../../presentation/features/data/screens/select_country_data_screen.dart';
import '../../presentation/features/data/screens/enter_phone_data_screen.dart';
import '../../presentation/features/data/screens/select_bundle_screen.dart';
import '../../presentation/features/data/screens/confirm_data_screen.dart';
import '../../presentation/features/transactions/screens/transactions_screen.dart';
import '../../presentation/features/transactions/screens/transaction_detail_screen.dart';
import '../../presentation/features/transactions/screens/statistics_screen.dart';
import '../../presentation/features/analytics/screens/analytics_dashboard_screen.dart';
import '../../presentation/features/search/screens/search_screen.dart';
import '../../presentation/features/rewards/screens/rewards_hub_screen.dart';
import '../../presentation/features/notifications/screens/notifications_screen.dart';
import '../../presentation/features/services/screens/services_screen.dart';
import '../../presentation/features/settings/screens/settings_screen.dart';
import '../../presentation/features/settings/screens/profile_screen.dart';
import '../../presentation/features/settings/screens/change_password_screen.dart';
import '../../presentation/features/settings/screens/edit_profile_screen.dart';
import '../../presentation/features/settings/screens/kyc_screen.dart';
import '../../presentation/features/settings/screens/payment_methods_screen.dart';
import '../../presentation/features/settings/screens/wallet_screen.dart';
import '../../presentation/features/settings/screens/language_screen.dart';
import '../../presentation/features/settings/screens/help_center_screen.dart';
import '../../presentation/features/settings/screens/about_screen.dart';
import '../../presentation/features/settings/screens/terms_of_service_screen.dart';
import '../../presentation/features/settings/screens/privacy_policy_screen.dart';
import '../../presentation/features/settings/screens/email_verification_screen.dart';
import '../../presentation/features/settings/screens/phone_verification_screen.dart';
import '../../presentation/features/payment/screens/payment_callback_screen.dart';
import '../../presentation/features/payment/screens/payment_receipt_screen.dart';
import '../../presentation/features/ai/screens/ai_chat_screen.dart';
import '../../data/models/api_models.dart';
import '../../core/constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Determine initial location based on onboarding completion
  Future<String> getInitialLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
    return onboardingCompleted ? '/login' : '/onboarding';
  }
  
  return GoRouter(
    initialLocation: '/onboarding', // This will be overridden by redirect
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) async {
      // Only check onboarding for the root route
      if (state.matchedLocation == '/onboarding') {
        final prefs = await SharedPreferences.getInstance();
        final onboardingCompleted = prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
        if (onboardingCompleted) {
          return '/login';
        }
      }
      return null;
    },
    routes: [
      // Onboarding Route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreenV2(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      
      // Main Routes
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // AI Chat Route
      GoRoute(
        path: '/ai-chat',
        name: 'ai-chat',
        builder: (context, state) => const AiChatScreen(),
      ),
      
      // Airtime Routes
      GoRoute(
        path: '/airtime',
        name: 'airtime',
        builder: (context, state) => const AirMenuScreen(),
      ),
      GoRoute(
        path: '/airtime/menu',
        name: 'air-menu',
        builder: (context, state) => const AirMenuScreen(),
      ),
      GoRoute(
        path: '/airtime/select-recipient',
        name: 'select-recipient',
        builder: (context, state) => const SelectRecipientScreen(),
      ),
      GoRoute(
        path: '/airtime/enter-amount',
        name: 'enter-amount',
        builder: (context, state) {
          final recipient = state.uri.queryParameters['recipient'] ?? '';
          final recipientName = state.uri.queryParameters['name'] ?? '';
          return EnterAmountScreen(
            recipientPhone: recipient,
            recipientName: recipientName,
          );
        },
      ),
      GoRoute(
        path: '/airtime/confirm',
        name: 'confirm-transaction',
        builder: (context, state) {
          final recipient = state.uri.queryParameters['recipient'] ?? '';
          final recipientName = state.uri.queryParameters['name'] ?? '';
          final amount = state.uri.queryParameters['amount'] ?? '';
          final note = state.uri.queryParameters['note'] ?? '';
          return ConfirmTransactionScreen(
            recipientPhone: recipient,
            recipientName: recipientName,
            amount: double.tryParse(amount) ?? 0.0,
            note: note,
          );
        },
      ),
      // Airtime Wizard Routes (New Reloadly Flow)
      GoRoute(
        path: '/airtime/select-country',
        name: 'select-country',
        builder: (context, state) => const SelectCountryScreen(),
      ),
      GoRoute(
        path: '/airtime/enter-phone',
        name: 'enter-phone',
        builder: (context, state) => const EnterPhoneScreen(),
      ),
      GoRoute(
        path: '/airtime/select-amount',
        name: 'select-amount',
        builder: (context, state) => const SelectAmountScreen(),
      ),
      GoRoute(
        path: '/airtime/confirm-airtime',
        name: 'confirm-airtime',
        builder: (context, state) => const ConfirmAirtimeScreen(),
      ),
      GoRoute(
        path: '/airtime/converter',
        name: 'airtime-converter',
        builder: (context, state) => const AirtimeConverterScreen(),
      ),
      // Data Bundle Wizard Routes
      GoRoute(
        path: '/data/select-country',
        name: 'select-country-data',
        builder: (context, state) => const SelectCountryDataScreen(),
      ),
      GoRoute(
        path: '/data/enter-phone',
        name: 'enter-phone-data',
        builder: (context, state) => const EnterPhoneDataScreen(),
      ),
      GoRoute(
        path: '/data/select-bundle',
        name: 'select-bundle',
        builder: (context, state) => const SelectBundleScreen(),
      ),
      GoRoute(
        path: '/data/confirm',
        name: 'confirm-data',
        builder: (context, state) => const ConfirmDataScreen(),
      ),
      
      // Transactions Routes
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/transactions/:id',
        name: 'transaction-detail',
        builder: (context, state) {
          final transaction = state.extra as Transaction?;
          if (transaction == null) {
            // Fallback: navigate back if no transaction provided
            return const TransactionsScreen();
          }
          return TransactionDetailScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      
      // Services Route
      GoRoute(
        path: '/services',
        name: 'services',
        builder: (context, state) => const ServicesScreen(),
      ),

      // Rewards & Points
      GoRoute(
        path: '/rewards',
        name: 'rewards',
        builder: (context, state) => const RewardsHubScreen(),
      ),
      
      // Settings Routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) {
          final user = state.extra as User?;
          if (user == null) {
            return const ProfileScreen();
          }
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: '/kyc',
        name: 'kyc',
        builder: (context, state) => const KycScreen(),
      ),
      GoRoute(
        path: '/payment-methods',
        name: 'payment-methods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/wallet',
        name: 'wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/language',
        name: 'language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/help-center',
        name: 'help-center',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        name: 'terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        name: 'email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/phone-verification',
        name: 'phone-verification',
        builder: (context, state) => const PhoneVerificationScreen(),
      ),
      
      // Payment Callback Route (for deep linking)
      GoRoute(
        path: '/payment/callback',
        name: 'payment-callback',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'] ?? 'unknown';
          final token = state.uri.queryParameters['token'];
          final orderId = state.uri.queryParameters['order-id'];
          return PaymentCallbackScreen(
            status: status,
            token: token,
            orderId: orderId,
          );
        },
      ),
      
      // Payment Receipt Route
      GoRoute(
        path: '/payment/receipt',
        name: 'payment-receipt',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentReceiptScreen(
            isSuccess: extra?['isSuccess'] ?? false,
            transactionType: extra?['transactionType'] ?? 'AIRTIME',
            transactionId: extra?['transactionId'],
            amount: (extra?['amount'] ?? 0.0).toDouble(),
            currency: extra?['currency'] ?? 'GHS',
            topupAmount: (extra?['topupAmount'] as num?)?.toDouble(),
            topupCurrency: extra?['topupCurrency'] as String?,
            paymentAmount: (extra?['paymentAmount'] as num?)?.toDouble(),
            paymentCurrency: extra?['paymentCurrency'] as String?,
            recipientNumber: extra?['recipientNumber'] ?? '',
            operatorName: extra?['operatorName'],
            countryName: extra?['countryName'],
            bundleName: extra?['bundleName'],
            errorMessage: extra?['errorMessage'],
            timestamp: extra?['timestamp'] as DateTime?,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

