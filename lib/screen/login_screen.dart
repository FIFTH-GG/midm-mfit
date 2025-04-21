import 'package:flutter/material.dart';
import 'package:mfit/service/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'signup_screen.dart'; // 회원가입 화면 import 필요

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _autoLogin = false; // 자동 로그인 상태 변수
  final AuthService _authService = AuthService();


  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final user = await _authService.signIn(email, password);

      if (user != null) {
        if (_autoLogin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', email);
          await prefs.setString('password', password);
          await prefs.setInt('loginTime', DateTime.now().millisecondsSinceEpoch);
        }

        print('로그인 성공');
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please check your email and password.';
        });
      }
    }
  }

  void _goToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignupScreen()),
    );
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');
    final loginTime = prefs.getInt('loginTime');

    if (savedEmail != null &&
        savedPassword != null &&
        loginTime != null &&
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(loginTime)).inDays < 7) {
      final user = await _authService.signIn(savedEmail, savedPassword);
      if (user != null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_background.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40.0),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[300],
                        hintText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email.';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[300],
                        hintText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _autoLogin,
                              onChanged: (value) {
                                setState(() {
                                  _autoLogin = value ?? false;
                                });
                              },
                              activeColor: Colors.amber,
                            ),
                            const Text(
                              'Remember Me',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: _goToSignUp,
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signInWithEmailAndPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
