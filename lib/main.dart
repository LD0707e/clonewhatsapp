import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/users_screen.dart';
import 'providers/auth_provider.dart';

// Flag para controlar uso do emulador local do Firebase
// Quando true, conecta nos emuladores locais (Auth 9099, Firestore 8080)
const bool USE_FIREBASE_EMULATOR = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseOk = false;

  // Tenta inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    firebaseOk = true;
    debugPrint('Firebase inicializado com sucesso');
  } catch (e) {
    debugPrint('Firebase nao inicializou: $e');
    firebaseOk = false;
  }

  // Se Firebase inicializou, configura os emuladores ANTES de qualquer operacao
  if (firebaseOk && USE_FIREBASE_EMULATOR) {
    try {
      debugPrint('Conectando aos emuladores locais...');
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      debugPrint('Emuladores configurados: Auth=9099, Firestore=8080');
    } catch (e) {
      debugPrint('Falha ao conectar nos emuladores: $e');
      firebaseOk = false;
    }
  }

  // Se Firebase falhou em qualquer ponto, ativa modo MOCK
  if (!firebaseOk) {
    debugPrint('=== ATIVANDO MODO MOCK LOCAL ===');
    FirebaseService.enableMockMode();
  }

  runApp(MyApp(firebaseOk: firebaseOk));
}

class MyApp extends StatelessWidget {
  final bool firebaseOk;
  const MyApp({Key? key, required this.firebaseOk}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'WhatsApp Clone',
        theme: ThemeData(
          primaryColor: const Color(0xFF075E54),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF075E54),
            primary: const Color(0xFF075E54),
            secondary: const Color(0xFF25D366),
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(firebaseOk: firebaseOk),
          '/login': (context) => const LoginScreen(),
          '/users': (context) => const UsersScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
