import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/utils/logger.dart';
import 'core/constants/app_constants.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/locale_provider.dart';

// Global navigator key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AppLogger.info('🚀 Lidapay App Starting...', 'Main');
  
  // Initialize SharedPreferences
  AppLogger.info('📦 Initializing SharedPreferences', 'Main');
  final prefs = await SharedPreferences.getInstance();
  AppLogger.info('✅ SharedPreferences initialized', 'Main');

  ThemeMode initialThemeMode = ThemeMode.light;
  final savedThemeMode = prefs.getString(AppConstants.themeModeKey);
  switch (savedThemeMode) {
    case 'dark':
      initialThemeMode = ThemeMode.dark;
      break;
    case 'system':
      initialThemeMode = ThemeMode.system;
      break;
    case 'light':
    default:
      initialThemeMode = ThemeMode.light;
      break;
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  AppLogger.info('🎨 App theme configured', 'Main');
  AppLogger.info('🌐 API Base URL: ${AppConstants.apiBaseUrl}${AppConstants.apiVersion}', 'Main');
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        themeModeProvider.overrideWith((ref) => initialThemeMode),
      ],
      child: const LidapayApp(),
    ),
  );

  AppLogger.info('✅ Lidapay App Started Successfully!', 'Main');
}

class LidapayApp extends ConsumerStatefulWidget {
  const LidapayApp({super.key});

  @override
  ConsumerState<LidapayApp> createState() => _LidapayAppState();
}

class _LidapayAppState extends ConsumerState<LidapayApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle deep link when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      AppLogger.info('🔗 Deep link received: $uri', 'DeepLink');
      _handleDeepLink(uri);
    });

    // Handle deep link when app is launched from a link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        AppLogger.info('🔗 Initial deep link: $initialLink', 'DeepLink');
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      AppLogger.error('Failed to get initial deep link', e, null, 'DeepLink');
    }
  }

  void _handleDeepLink(Uri uri) {
    // Handle payment callback deep links
    // Expected formats:
    // 1. lidapay://payment/callback?status=success&token=xxx&order-id=xxx
    // 2. https://lidapay.app/payment/callback?status=success&token=xxx&order-id=xxx
    // 3. AdvansiPay redirect: /api/v1/advansispay/redirect-url?order-id=xxx&token=xxx
    
    final path = uri.path;
    
    // Sanitize query parameters - remove newlines, extra spaces, and trim values
    final rawParams = uri.queryParameters;
    final queryParams = rawParams.map((key, value) {
      // Remove newlines, carriage returns, and trim whitespace
      final sanitizedKey = key.replaceAll(RegExp(r'[\n\r\s]+'), '').trim();
      final sanitizedValue = value.replaceAll(RegExp(r'[\n\r]+'), '').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      return MapEntry(sanitizedKey, sanitizedValue);
    });

    AppLogger.info('🔗 Handling deep link - path: $path, params: $queryParams', 'DeepLink');

    // Handle AdvansiPay redirect URL format
    // URL: https://api.advansistechnologies.com/api/v1/advansispay/redirect-url?order-id=xxx&token=xxx
    if (path.contains('advansispay/redirect-url') || path.contains('redirect-url')) {
      final token = queryParams['token'];
      final orderId = queryParams['order-id'] ?? queryParams['orderId'];
      
      final tokenPreview = token != null && token.length > 10 ? '${token.substring(0, 10)}...' : token ?? 'null';
      AppLogger.info('💳 AdvansiPay redirect received - token: $tokenPreview, orderId: $orderId', 'DeepLink');

      // Navigate to payment callback screen with token for verification
      final router = ref.read(routerProvider);
      router.go('/payment/callback?status=pending${token != null ? '&token=$token' : ''}${orderId != null ? '&order-id=$orderId' : ''}');
      return;
    }

    // Handle standard payment callback format
    if (path.contains('payment/callback') || path.contains('payment-callback')) {
      final status = queryParams['status'] ?? 'unknown';
      final token = queryParams['token'];
      final orderId = queryParams['order-id'] ?? queryParams['orderId'];

      // Navigate to payment callback screen
      final router = ref.read(routerProvider);
      router.go('/payment/callback?status=$status${token != null ? '&token=$token' : ''}${orderId != null ? '&order-id=$orderId' : ''}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Lidapay',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      // Use individual router components to filter custom scheme URIs
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: _SafeRouteInformationProvider(
        router.routeInformationProvider,
      ),
      backButtonDispatcher: router.backButtonDispatcher,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

/// Custom RouteInformationProvider that filters out custom scheme URIs
/// This prevents GoRouter from crashing when receiving lidapay:// deep links
class _SafeRouteInformationProvider extends RouteInformationProvider with ChangeNotifier {
  final RouteInformationProvider _delegate;
  RouteInformation _value;

  _SafeRouteInformationProvider(this._delegate) 
      : _value = _delegate.value {
    _delegate.addListener(_onDelegateChanged);
  }

  void _onDelegateChanged() {
    final newValue = _delegate.value;
    final uri = newValue.uri;
    
    // Filter out custom scheme URIs - they're handled by AppLinks in _handleDeepLink
    if (uri.scheme.isNotEmpty && uri.scheme != 'http' && uri.scheme != 'https') {
      AppLogger.info('🛡️ Filtering custom scheme URI from GoRouter: ${uri.scheme}://', 'DeepLink');
      // Don't update - let the deep link handler manage navigation
      return;
    }
    
    _value = newValue;
    notifyListeners();
  }

  @override
  RouteInformation get value => _value;

  @override
  void routerReportsNewRouteInformation(RouteInformation routeInformation, {RouteInformationReportingType type = RouteInformationReportingType.none}) {
    if (_delegate is GoRouteInformationProvider) {
      (_delegate as GoRouteInformationProvider).routerReportsNewRouteInformation(routeInformation, type: type);
    }
  }

  @override
  void dispose() {
    _delegate.removeListener(_onDelegateChanged);
    super.dispose();
  }
}
