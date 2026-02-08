import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      final prefs = await SharedPreferences.getInstance();
      bool enabled = prefs.getBool('biometric_enabled') ?? false;
      
      setState(() {
        _biometricAvailable = canCheckBiometrics && isDeviceSupported;
        _biometricEnabled = enabled && _biometricAvailable;
      });
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
        _biometricEnabled = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Save credentials for biometric login if enabled
      final prefs = await SharedPreferences.getInstance();
      bool biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      if (biometricEnabled) {
        await prefs.setString('biometric_email', email);
        await prefs.setString('biometric_password', password);
      }
      
      if (!mounted) return;
      _showMessage('Login successful!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email.';
          break;
        case 'wrong-password':
          msg = 'Incorrect password.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address.';
          break;
        case 'user-disabled':
          msg = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          msg = 'Invalid email or password.';
          break;
        default:
          msg = e.message ?? 'Login failed. Please try again.';
      }
      _showMessage(msg, isError: true);
    } catch (e) {
      _showMessage('Login failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      if (!mounted) return;
      _showMessage('Signed in with Google!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } catch (e) {
      _showMessage('Google sign-in failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Please enter your email first', isError: true);
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showMessage('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address.';
          break;
        default:
          msg = e.message ?? 'Failed to send reset email.';
      }
      _showMessage(msg, isError: true);
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);
    
    try {
      // Authenticate with biometrics
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Retrieve saved credentials
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('biometric_email');
        final password = prefs.getString('biometric_password');

        if (email == null || password == null) {
          _showMessage('No saved credentials. Please login with email/password first.', isError: true);
          return;
        }

        // Sign in with Firebase
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        if (!mounted) return;
        _showMessage('Login successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        _showMessage('Authentication failed', isError: true);
      }
    } on FirebaseAuthException catch (e) {
      _showMessage('Login failed: ${e.message}', isError: true);
    } catch (e) {
      _showMessage('Biometric authentication failed', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Top section with lavender image and curved background
                  SizedBox(
                    height: isSmallScreen ? 200 : 300,
                    child: Stack(
                      children: [
                        // Curved mint/green background
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: CustomPaint(
                            size: Size(screenWidth, isSmallScreen ? 200 : 300),
                            painter: CurvedBackgroundPainter(),
                          ),
                        ),
                        // Lavender flower image placeholder
                        Center(
                          child: _buildLavenderImage(isSmallScreen),
                        ),
                      ],
                    ),
                  ),

                  // Form section
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth > 600 ? 100 : 32,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // Email field
                          _buildEmailField(),
                          const SizedBox(height: 20),

                          // Password field
                          _buildPasswordField(),
                          const SizedBox(height: 8),

                          // Forgot Password
                          _buildForgotPassword(),
                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Login Button
                          _buildLoginButton(),
                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Biometric Button (if enabled)
                          if (_biometricEnabled) ...[
                            _buildBiometricButton(),
                            SizedBox(height: isSmallScreen ? 16 : 24),
                          ],

                          // Or divider
                          _buildOrDivider(),
                          SizedBox(height: isSmallScreen ? 16 : 24),

                          // Social login buttons
                          _buildSocialButtons(),
                          const Spacer(),

                          // Sign up link
                          _buildSignUpLink(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLavenderImage(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 160 : 250,
      width: isSmallScreen ? 160 : 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stack of flower icons to simulate lavender
          Stack(
            alignment: Alignment.center,
            children: [
              // Main lavender representation
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lavender flowers
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Transform.rotate(
                        angle: -0.3,
                        child: _buildLavenderStalk(isSmallScreen ? 60 : 100),
                      ),
                      _buildLavenderStalk(isSmallScreen ? 80 : 120),
                      Transform.rotate(
                        angle: 0.3,
                        child: _buildLavenderStalk(isSmallScreen ? 70 : 110),
                      ),
                    ],
                  ),
                  // Leaves
                  Icon(
                    Icons.eco,
                    size: isSmallScreen ? 40 : 60,
                    color: const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLavenderStalk(double height) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Flower spikes
        for (int i = 0; i < 5; i++)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 1),
            child: Icon(
              Icons.water_drop,
              size: height / 8,
              color: Color.lerp(
                const Color(0xFF9C27B0),
                const Color(0xFF7B1FA2),
                i / 5,
              ),
            ),
          ),
        // Stem
        Container(
          width: 3,
          height: height * 0.3,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'email@gmail.com',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: Colors.grey[600],
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Colors.purple[300]!,
            width: 2,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.grey[600],
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(
            color: Colors.purple[300]!,
            width: 2,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: Text(
          'Forgot Password',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD9B3F5),
            Color(0xFFCB9EF0),
            Color(0xFFB57EDC),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCB9EF0).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFFCB9EF0).withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal[300]!,
            Colors.teal[400]!,
            Colors.teal[500]!,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleBiometricLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Login with Biometric',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '- or -',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google
        _socialLoginButton(
          onPressed: _isLoading ? () {} : _handleGoogleSignIn,
          child: Container(
            width: 24,
            height: 24,
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Facebook
        _socialLoginButton(
          onPressed: () {},
          child: const Icon(
            Icons.facebook,
            color: Color(0xFF1877F2),
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
        // Apple
        _socialLoginButton(
          onPressed: () {},
          child: const Icon(
            Icons.apple,
            color: Colors.black,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const RegisterScreen()),
            );
          },
          child: Text(
            'Sign up',
            style: TextStyle(
              color: Colors.teal[400],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialLoginButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8F8F8),
          ],
        ),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: child,
      ),
    );
  }
}

class CurvedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD5F5E8)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.1,
      0,
      size.height * 0.4,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Draw decorative curved line
    final linePaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final linePath = Path();
    linePath.moveTo(0, size.height * 0.85);
    linePath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.65,
      size.width * 0.5,
      size.height * 0.75,
    );
    linePath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.85,
      size.width,
      size.height * 0.7,
    );

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
