import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/widgets/auth_form_widgets.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreed = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> handleSignUp() async {
    // TODO: Replace this stub with your sign-up API or registration logic.
    return true;
  }

  Future<void> _submitSignUp() async {
    final isSuccess = await handleSignUp();
    if (!mounted || !isSuccess) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
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
                  const Text(
                    'Create Your Account',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your personalized journey through the museum.',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.blueGrey.shade700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const FieldLabel(
                    text: 'Full Name',
                    fontSize: 19,
                    bottomPadding: 7,
                  ),
                  AppTextField(
                    controller: _nameController,
                    hintText: 'Enter your name',
                    fontSize: 17,
                    hintFontSize: 17,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
                  const FieldLabel(
                    text: 'Password',
                    fontSize: 19,
                    bottomPadding: 7,
                  ),
                  AppTextField(
                    controller: _passwordController,
                    hintText: 'Enter your password',
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
                    hintText: 'Enter your password',
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreed,
                          onChanged: (value) {
                            setState(() {
                              _agreed = value ?? false;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                          activeColor: const Color(0xFFCC353A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I Agree to the ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms',
                                style: TextStyle(color: Color(0xFFCC353A)),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Conditions',
                                style: TextStyle(color: Color(0xFFCC353A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed: _submitSignUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFCC353A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
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
                        const Text(
                          'Already have an account?',
                          style: TextStyle(fontSize: 15),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
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
