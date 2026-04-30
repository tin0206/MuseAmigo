import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/widgets/auth_form_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  bool _showResetForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await BackendApi.instance.forgotPassword(email);
      if (!mounted) return;

      final token = result['token'] as String?;
      if (token != null) {
        _tokenController.text = token;
      }

      setState(() => _showResetForm = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token generated. Enter your new password below.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to process request. $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitResetPassword() async {
    final token = _tokenController.text.trim();
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is required.')),
      );
      return;
    }
    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is required.')),
      );
      return;
    }
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await BackendApi.instance.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful. Please log in.')),
      );
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to reset password. $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _backToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    _showResetForm ? 'Reset Password' : 'Forgot Password',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showResetForm
                        ? 'Enter the token and your new password.'
                        : 'Enter your email to receive a reset token.',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.blueGrey.shade700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FieldLabel(
                    text: 'Email',
                    fontSize: 19,
                    bottomPadding: 7,
                  ),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                    fontSize: 17,
                    hintFontSize: 17,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                  ),
                  if (_showResetForm) ...[
                    const SizedBox(height: 14),
                    const FieldLabel(
                      text: 'Reset Token',
                      fontSize: 19,
                      bottomPadding: 7,
                    ),
                    AppTextField(
                      controller: _tokenController,
                      hintText: 'Paste your reset token',
                      fontSize: 17,
                      hintFontSize: 17,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const FieldLabel(
                      text: 'New Password',
                      fontSize: 19,
                      bottomPadding: 7,
                    ),
                    AppTextField(
                      controller: _passwordController,
                      hintText: 'Enter new password',
                      obscureText: _obscurePassword,
                      fontSize: 17,
                      hintFontSize: 17,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.blueGrey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const FieldLabel(
                      text: 'Confirm Password',
                      fontSize: 19,
                      bottomPadding: 7,
                    ),
                    AppTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm new password',
                      obscureText: _obscureConfirmPassword,
                      fontSize: 17,
                      hintFontSize: 17,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.blueGrey.shade300,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed: _isSubmitting
                          ? null
                          : (_showResetForm ? _submitResetPassword : _submitForgotPassword),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _showResetForm ? 'Reset Password' : 'Send Reset Token',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Back to', style: TextStyle(fontSize: 15)),
                        InkWell(
                          onTap: _backToLogin,
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
