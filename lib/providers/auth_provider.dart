import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  AppUser? _currentUser;
  User? _firebaseUser;

  AppUser? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;

  AuthProvider() {
    if (FirebaseService.useMock) {
      // Modo MOCK: escuta o MockAuth
      MockAuth.authStateChanges.listen((mockUser) {
        if (mockUser != null) {
          _currentUser = AppUser(
            uid: mockUser.uid,
            name: mockUser.email.split('@')[0],
            email: mockUser.email,
            createdAt: DateTime.now(),
          );
        } else {
          _currentUser = null;
        }
        _firebaseUser = null;
        notifyListeners();
      });
    } else {
      // Modo Firebase real
      _auth.authStateChanges().listen((User? user) async {
        _firebaseUser = user;
        if (user != null) {
          await _getUserData(user.uid);
        } else {
          _currentUser = null;
        }
        notifyListeners();
      });
    }
  }

  Future _getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromMap(doc.data() as Map);
      }
      notifyListeners();
    } catch (e) {
      print('Error getting user data: $e');
    }
  }

  Future register(String name, String email, String password) async {
    try {
      if (FirebaseService.useMock) {
        final credential = await MockAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        _currentUser = AppUser(
          uid: credential.user.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );
        _firebaseUser = null;
        notifyListeners();
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        AppUser newUser = AppUser(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
        _currentUser = newUser;
        notifyListeners();
      }
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e is FirebaseAuthException) {
        errorMessage = _getAuthErrorMessage(e.code);
      } else if (e is FirebaseException) {
        errorMessage = 'Firestore error: ${e.message}';
      } else if (e.toString().contains('Firestore')) {
        errorMessage = 'Erro de conexão com o banco de dados. Verifique se os emuladores estão rodando.';
      }
      throw Exception(errorMessage);
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este email já está cadastrado';
      case 'invalid-email':
        return 'Email inválido';
      case 'operation-not-allowed':
        return 'Operação não permitida';
      case 'weak-password':
        return 'Senha muito fraca (mínimo 6 caracteres)';
      case 'user-disabled':
        return 'Usuário desativado';
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet ou se os emuladores estão rodando.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      default:
        return 'Erro de autenticação: $code';
    }
  }

  Future login(String email, String password) async {
    try {
      if (FirebaseService.useMock) {
        final credential = await MockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        _currentUser = AppUser(
          uid: credential.user.uid,
          name: credential.user.email.split('@')[0],
          email: email,
          createdAt: DateTime.now(),
        );
        _firebaseUser = null;
        notifyListeners();
      } else {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      }
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e is FirebaseAuthException) {
        errorMessage = _getAuthErrorMessage(e.code);
      } else if (e is FirebaseException) {
        errorMessage = 'Firebase error: ${e.message}';
      } else if (e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('connection refused') ||
          e.toString().toLowerCase().contains('socket')) {
        errorMessage = 'Erro de conexao. Verifique se os emuladores do Firebase estao rodando (portas 9099 e 8080).';
      }
      throw Exception(errorMessage);
    }
  }

  Future logout() async {
    if (FirebaseService.useMock) {
      await MockAuth.signOut();
    } else {
      await _auth.signOut();
    }
    _currentUser = null;
    _firebaseUser = null;
    notifyListeners();
  }
}
