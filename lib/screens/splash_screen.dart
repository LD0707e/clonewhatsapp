import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class SplashScreen extends StatefulWidget {
  final bool firebaseOk;
  const SplashScreen({Key? key, this.firebaseOk = true}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  void _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Aguarda um momento para o Firebase carregar o estado de autenticação
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseService.useMock
        ? MockAuth.currentUser
        : authProvider.firebaseUser;

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/users');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMock = FirebaseService.useMock;

    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'WhatsApp Clone',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isMock ? 'Modo Demo (local)' : 'Conectado ao Firebase',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
