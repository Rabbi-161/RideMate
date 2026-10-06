import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import '../../backend/services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signUp(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _phoneController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        setState(() => _isLoading = false);
        HomeScreen.switchToTab(0);
        final messenger = ScaffoldMessenger.of(context);
        final welcomeName = user.name.isNotEmpty ? user.name : 'User';
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Account created! Welcome to RideMate, $welcomeName.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.successColor,
          ),
        );
        return;
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to create account. Please check your information and try again.',
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email. Please log in instead.';
          break;
        case 'weak-password':
          errorMessage =
              'The password is too weak. Please use at least 6 characters.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is invalid.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Email/Password registration is not enabled in Firebase Console.';
          break;
        case 'configuration-not-found':
          errorMessage = 'Firebase Auth configuration not found. Please verify Firebase project settings.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection and try again.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many attempts. Please try again in a few moments.';
          break;
        default:
          errorMessage =
              e.message ?? 'Registration failed. Please check your details.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sign up timed out. Please check your network connection and try again.',
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final cleanError = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration error: $cleanError'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join RideMate',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connect with verified students and commuters travelling your route.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // Full Name (PRD Section 8)
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Md. Fazle Rabbi',
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone Number
                const Text(
                  'Phone Number (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'e.g. +880 1700-000000',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email (PRD Section 8)
                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password (PRD Section 8)
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Create password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password (PRD Section 8)
                const Text(
                  'Confirm Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Create Account button (PRD Section 8)
                CustomButton(
                  text: 'Create Account',
                  isLoading: _isLoading,
                  onPressed: _handleSignUp,
                ),
                const SizedBox(height: 16),

                // Back to login
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
