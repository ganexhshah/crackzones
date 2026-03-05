import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'firebase_options.dart';
import 'services/in_app_chat_popup_service.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/tournament_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/splash_screen.dart';

String _pushPlatform() {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    default:
      return 'android';
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;
  await Firebase.initializeApp();
}

Future<void> _initPushNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');
    // Don't register token here - will be registered after login in AuthProvider

    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token Refresh: $newToken');
      // Token will be registered after login in AuthProvider
    });

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('FCM foreground message: ${message.messageId}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM opened app from notification: ${message.messageId}');
    });
  } catch (e) {
    debugPrint('Push notifications init skipped: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  await _initPushNotifications();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InAppChatPopupService.instance.init(
        navigatorKey: _navigatorKey,
        messengerKey: _messengerKey,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: MaterialApp(
        title: 'crackzone',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
