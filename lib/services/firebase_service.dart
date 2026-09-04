// Camada de abstração Firebase - permite fallback para MOCK LOCAL
// caso o Firebase nao esteja disponivel (sem internet, sem login, etc)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static bool useMock = false;

  static void enableMockMode() {
    useMock = true;
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
}

// ============================================
// MOCK LOCAL - usado quando Firebase nao conecta
// ============================================

class MockAuth {
  static final Map<String, _MockUser> _users = {};
  static _MockUser? _currentUser;
  static final _controller = _MockAuthStream();

  static Stream<_MockUser?> get authStateChanges => _controller.stream;

  static _MockUser? get currentUser => _currentUser;

  static Future<_MockUserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_users.containsKey(email)) {
      throw MockFirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Email ja cadastrado',
      );
    }
    final user = _MockUser(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
    );
    _users[email] = user;
    _currentUser = user;
    _controller.emit(user);
    return _MockUserCredential(user);
  }

  static Future<_MockUserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = _users[email];
    if (user == null) {
      throw MockFirebaseAuthException(
        code: 'user-not-found',
        message: 'Usuario nao encontrado',
      );
    }
    _currentUser = user;
    _controller.emit(user);
    return _MockUserCredential(user);
  }

  static Future<void> signOut() async {
    _currentUser = null;
    _controller.emit(null);
  }
}

class _MockUser {
  final String uid;
  final String email;
  _MockUser({required this.uid, required this.email});
}

class _MockUserCredential {
  final _MockUser user;
  _MockUserCredential(this.user);
}

class _MockAuthStream {
  final List<void Function(_MockUser?)> _listeners = [];
  _MockUser? _currentUser;

  Stream<_MockUser?> get stream {
    return Stream.multi((controller) {
      void listener(_MockUser? user) => controller.add(user);
      _listeners.add(listener);
      controller.onCancel = () => _listeners.remove(listener);
      listener(_currentUser);
    });
  }

  void emit(_MockUser? user) {
    _currentUser = user;
    for (final l in List.of(_listeners)) {
      l(user);
    }
  }
}

class MockFirestore {
  static final Map<String, Map<String, dynamic>> _documents = {};

  static Future<void> setDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _documents['$collection/$id'] = data;
  }

  static Future<Map<String, dynamic>?> getDocument(
    String collection,
    String id,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _documents['$collection/$id'];
  }

  static Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _documents.entries
        .where((e) => e.key.startsWith('$collection/'))
        .map((e) => e.value)
        .toList();
  }
}

class MockFirebaseAuthException implements Exception {
  final String code;
  final String message;
  MockFirebaseAuthException({required this.code, required this.message});
  @override
  String toString() => message;
}