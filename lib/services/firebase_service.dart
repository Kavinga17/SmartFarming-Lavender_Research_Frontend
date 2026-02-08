import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Service - Centralized Firebase functionality
/// 
/// This service provides easy access to all Firebase features:
/// - Authentication (Email/Password, Google Sign-In)
/// - Cloud Firestore (Database)
/// - Firebase Storage (File/Image Storage)
/// - Firebase Analytics
/// - Firebase Cloud Messaging (Push Notifications)
class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Getters for Firebase instances
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseAnalytics get analytics => _analytics;
  FirebaseMessaging get messaging => _messaging;

  // Current user
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _logAnalyticsEvent('login', {'method': 'email'});
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Register with email and password
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _logAnalyticsEvent('sign_up', {'method': 'email'});
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);
      await _logAnalyticsEvent('login', {'method': 'google'});
      return userCredential;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _logAnalyticsEvent('logout', {});
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
    }
  }

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================================
  // FIRESTORE METHODS
  // ============================================================================

  /// Get a collection reference
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  /// Get a document reference
  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  /// Add a document to a collection
  Future<DocumentReference<Map<String, dynamic>>> addDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    return await _firestore.collection(collectionPath).add(data);
  }

  /// Set a document (create or overwrite)
  Future<void> setDocument(
    String documentPath,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    if (!merge) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.doc(documentPath).set(data, SetOptions(merge: merge));
  }

  /// Update a document
  Future<void> updateDocument(
    String documentPath,
    Map<String, dynamic> data,
  ) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.doc(documentPath).update(data);
  }

  /// Delete a document
  Future<void> deleteDocument(String documentPath) async {
    await _firestore.doc(documentPath).delete();
  }

  /// Get a document
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(String path) async {
    return await _firestore.doc(path).get();
  }

  /// Get documents from a collection with optional query
  Future<QuerySnapshot<Map<String, dynamic>>> getDocuments(
    String collectionPath, {
    List<List<dynamic>>? whereConditions,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

    if (whereConditions != null) {
      for (var condition in whereConditions) {
        query = query.where(condition[0], isEqualTo: condition[1]);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query.get();
  }

  /// Stream documents from a collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
    String collectionPath, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // ============================================================================
  // STORAGE METHODS
  // ============================================================================

  /// Upload a file to Firebase Storage
  Future<String> uploadFile(String path, File file) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Upload bytes to Firebase Storage
  Future<String> uploadBytes(String path, List<int> bytes, {String? contentType}) async {
    final ref = _storage.ref().child(path);
    final metadata = contentType != null ? SettableMetadata(contentType: contentType) : null;
    final uploadTask = ref.putData(Uint8List.fromList(bytes), metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }

  /// Get download URL for a file
  Future<String> getDownloadURL(String path) async {
    final ref = _storage.ref().child(path);
    return await ref.getDownloadURL();
  }

  // ============================================================================
  // ANALYTICS METHODS
  // ============================================================================

  /// Log a custom analytics event
  Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await _logAnalyticsEvent(name, parameters);
  }

  /// Set user properties for analytics
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Set the current screen for analytics
  Future<void> setCurrentScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  /// Log analytics event (internal helper)
  Future<void> _logAnalyticsEvent(String name, Map<String, dynamic> params) async {
    await _analytics.logEvent(
      name: name,
      parameters: params.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  // ============================================================================
  // CLOUD MESSAGING METHODS
  // ============================================================================

  /// Initialize FCM and request permissions
  Future<void> initializeMessaging() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted FCM permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional FCM permission');
    } else {
      print('User declined FCM permission');
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Listen to foreground messages
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Handle message opened app
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;

  // ============================================================================
  // USER DATA METHODS (FIRESTORE)
  // ============================================================================

  /// Save user data to Firestore
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final user = currentUser;
    if (user != null) {
      await setDocument('users/${user.uid}', userData, merge: true);
    }
  }

  /// Get current user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final user = currentUser;
    if (user != null) {
      final doc = await getDocument('users/${user.uid}');
      return doc.data();
    }
    return null;
  }

  /// Stream current user data
  Stream<DocumentSnapshot<Map<String, dynamic>>>? streamUserData() {
    final user = currentUser;
    if (user != null) {
      return _firestore.doc('users/${user.uid}').snapshots();
    }
    return null;
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

// Typedef for convenience
typedef Uint8List = List<int>;
