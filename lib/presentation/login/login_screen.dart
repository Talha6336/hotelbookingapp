import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/app_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Animations
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showErrorSnackBar("Please enter email and password.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (userCredential.user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        final role = doc.data()?['role'] ?? 'customer';

        if (!mounted) return;

        if (role == 'owner') {
          Navigator.of(context).pushReplacementNamed('/owner_nav');
        } else {
          Navigator.of(context).pushReplacementNamed('/customer_nav');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? "Authentication failed.");
    } catch (e) {
      _showErrorSnackBar("An error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showRoleSelectionDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // Forces them to make a choice
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.adaptiveSurface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.adaptiveBorder(context)),
          ),
          title: Text(
            "Welcome to StayEase!",
            style: TextStyle(
              color: AppColors.adaptiveTextPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "To complete your profile, please tell us how you will be using the app:",
            style: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'customer'),
              icon: Icon(
                Icons.luggage,
                color: AppColors.adaptiveTextPrimary(context),
                size: 18,
              ),
              label: Text(
                "Book Hotels",
                style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adaptiveSurfaceMuted(context),
                elevation: 0,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'owner'),
              icon: const Icon(Icons.domain, color: Colors.white, size: 18),
              label: const Text(
                "List Hotels",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User canceled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final docSnapshot = await userDocRef.get();

        String role;

        if (!docSnapshot.exists) {
          final selectedRole = await _showRoleSelectionDialog();

          if (selectedRole == null) {
            await user.delete();
            setState(() => _isLoading = false);
            return;
          }

          role = selectedRole;

          await userDocRef.set({
            'uid': user.uid,
            'name': user.displayName ?? 'Google User',
            'email': user.email,
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          role = docSnapshot.data()?['role'] ?? 'customer';
        }

        if (!mounted) return;

        if (role == 'owner') {
          Navigator.of(context).pushReplacementNamed('/owner_nav');
        } else {
          Navigator.of(context).pushReplacementNamed('/customer_nav');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? "Google Sign-In failed.");
    } catch (e, stackTrace) {
      debugPrint("Google Sign-In Error: $e");
      debugPrint("StackTrace: $stackTrace");
      _showErrorSnackBar("Google Sign-In Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        useSafeArea: true,
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildGlassmorphismCard(),
                    const SizedBox(height: 32),
                    _buildGoogleSignInButton(),
                    const SizedBox(height: 24),
                    _buildSignUpText(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome to\nStayEase",
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: AppColors.adaptiveTextPrimary(context),
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Book your perfect stay easily.",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.adaptiveTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassmorphismCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.adaptiveSurface(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.adaptiveBorder(context),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.adaptiveShadow(context),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildTextField(
                controller: _emailController,
                hintText: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hintText: "Password",
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.adaptiveTextPrimary(context)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.adaptiveTextSecondary(context)),
        prefixIcon: Icon(icon, color: AppColors.adaptiveTextSecondary(context)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.adaptiveSurfaceMuted(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.adaptiveBorder(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.adaptiveBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shadowColor: AppColors.primary.withValues(alpha: 0.4),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                "Login",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _signInWithGoogle,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: AppColors.adaptiveBorder(context), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.adaptiveSurfaceMuted(context),
      ),
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.g_mobiledata, color: Colors.black, size: 24),
      ),
      label: Text(
        "Continue with Google",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.adaptiveTextPrimary(context),
        ),
      ),
    );
  }

  Widget _buildSignUpText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: AppColors.adaptiveTextSecondary(context),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/signup');
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
