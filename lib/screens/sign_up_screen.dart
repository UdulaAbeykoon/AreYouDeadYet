import 'package:death_app/providers/check_in_provider.dart';
import 'package:death_app/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print("Attempting Sign Up for: ${_emailController.text}");
      
      // 1. Attempt to Sign Up
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'name': _nameController.text.trim()},
      );

      print("Sign Up Response: User=${response.user?.id}, Session=${response.session}");

      if (mounted) {
        // 2. Check if we have a valid session (Auto-login successful)
        if (response.session != null) {
          print("Session received. Auto-login successful.");
          // Success! SettingsAuthWrapper will switch to SettingsScreen because it watches the provider/session.
        } else {
          print("User created but NO session. FORCE manual login bypass.");
          
          // FORCE BYPASS: Treat as logged in manually to show the settings page immediately
          await context.read<CheckInProvider>().loginManually(
            _nameController.text.trim(),
            _emailController.text.trim()
          );
        }
      }
    } on AuthException catch (error) {
      if (error.message.contains('User already registered') || error.message.contains('already registered')) {
        print("User exists. Attempting Sign In...");
        try {
          final response = await Supabase.instance.client.auth.signInWithPassword(
             email: _emailController.text.trim(),
             password: _passwordController.text.trim(),
          );
           if (response.session != null) {
              print("Sign In successful.");
               if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Welcome back! Logged in successfully.')),
                  );
               }
              // Success - Wrapper will handle navigation
              return; 
           }
        } catch (signInError) {
           print("Sign In failed: $signInError");
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Login failed: ${signInError.toString()}')),
                );
             }
        }
      }

      print("AuthException: ${error.message} - FORCING BYPASS ANYWAY");
      
      // FALLBACK: Only if sign in failed or it was another error
      if (mounted) {
        await context.read<CheckInProvider>().loginManually(
            _nameController.text.trim(),
            _emailController.text.trim()
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login forced (Offline/Bypass Mode) - EMAILS WILL NOT WORK'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (error) {
      print("Unexpected error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SIGN UP", style: AppTheme.bigHeaderStyle),
                Text(
                  "Create an account to configure settings",
                  style: AppTheme.bodyStyle.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  controller: _nameController,
                  label: "Name",
                  icon: Icons.person,
                  validator: (val) =>
                      val == null || val.isEmpty ? "Name is required" : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email,
                  validator: (val) =>
                      val == null || val.isEmpty ? "Email is required" : null,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  label: "Password",
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (val) => val == null || val.length < 6
                      ? "Password must be at least 6 characters"
                      : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SIGN UP",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}
