import 'dart:io'; 
import 'package:flutter/material.dart';
import '../api/auth_api.dart';
import '../storage/auth_storage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyErrorMessage(Object e) {
    final message = e.toString().toLowerCase();

    if (e is SocketException) {
      return 'No internet connection. Please check your network.';
    }

    if (message.contains('email already exists') ||
        message.contains('already registered')) {
      return 'This email is already registered.';
    }

    if (message.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('password')) {
      return 'Password must be at least 6 characters long.';
    }

    if (message.contains('400')) {
      return 'Please check your data and try again.';
    }

    if (message.contains('500')) {
      return 'Server error. Please try again later.';
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await AuthApi.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      final token = res['access_token'];

      if (token != null) {
        await AuthStorage.saveToken(token);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome!'),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _friendlyErrorMessage(e); 
      });

    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( 
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              ElevatedButton(
                onPressed: _loading ? null : _signUp,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Sign Up'),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/signin');
                },
                child: const Text('Already have an account? Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
