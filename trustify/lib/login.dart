import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:trustify/main.dart';
import 'package:trustify/register.dart';
import 'package:trustify/userhome.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'sans-serif'),
      home: const LoginPage(title: 'login'),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.title});
  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _rememberMe = true;

  final TextEditingController usernamecontroller = TextEditingController();
  final TextEditingController passwordcontroller = TextEditingController();

  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    usernamecontroller.dispose();
    passwordcontroller.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _usernameError = usernamecontroller.text.trim().isEmpty
          ? 'Username is required'
          : null;
      _passwordError = passwordcontroller.text.trim().isEmpty
          ? 'Password is required'
          : passwordcontroller.text.trim().length < 4
          ? 'Password must be at least 4 characters'
          : null;
    });
    return _usernameError == null && _passwordError == null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to IP entry page, clearing the stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyAppPage(title: '')),
              (route) => false,
        );
        return false; // prevent default back behaviour
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F0F0),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top black header ───────────────────────────
                Container(
                  width: double.infinity,
                  color: const Color(0xFF0A0A0A),
                  padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TRUSTIFY',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Welcome\nBack',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign in to continue to your account',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.45),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── White form card ────────────────────────────
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Username ──────────────────────────────
                      _buildLabel('Username'),
                      const SizedBox(height: 8),
                      _TRUSTIFYInputField(
                        controller: usernamecontroller,
                        hintText: 'Enter your username',
                        obscureText: false,
                        errorText: _usernameError,
                        suffixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: Color(0xFF999999),
                          size: 20,
                        ),
                        onChanged: (_) {
                          if (_usernameError != null) {
                            setState(() => _usernameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Password ──────────────────────────────
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      _TRUSTIFYInputField(
                        controller: passwordcontroller,
                        hintText: 'Enter your password',
                        obscureText: _obscurePassword,
                        errorText: _passwordError,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(
                                    () => _obscurePassword = !_obscurePassword);
                          },
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF999999),
                            size: 20,
                          ),
                        ),
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 18),

                      // ── Login button ──────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: send_data,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A0A0A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Divider ───────────────────────────────
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: Color(0xFFE8E8E8))),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'or',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ),
                          const Expanded(
                              child: Divider(color: Color(0xFFE8E8E8))),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Sign up row ───────────────────────────
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const RegistrationPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Signup',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0A0A0A),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0A0A0A),
        letterSpacing: 0.3,
      ),
    );
  }

  void send_data() async {
    if (!_validate()) return;

    String username = usernamecontroller.text.trim();
    String password = passwordcontroller.text.trim();

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');

    if (url == null) {
      Fluttertoast.showToast(msg: "Server URL not found");
      return;
    }

    final Uri urls = Uri.parse('$url/user_login/');

    try {
      final response = await http.post(
        urls,
        body: {
          'username': username,
          'password': password,
        },
      );

      print("Server Response: ${response.body}");

      var jsonData = jsonDecode(response.body);

      if (jsonData['status'] == "ok") {
        String lid = jsonData['lid'].toString();
        await sh.setString("lid", lid);

        Fluttertoast.showToast(msg: "Login Successful");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Homepage(title: "Home"),
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "Invalid Username or Password");
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: "Connection Error");
    }
  }
}

// ─── TRUSTIFY Styled Input Field ──────────────────────────────────
class _TRUSTIFYInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final String? errorText;
  final Widget suffixIcon;
  final ValueChanged<String>? onChanged;

  const _TRUSTIFYInputField({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.suffixIcon,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFFE0E0E0),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 14,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: suffixIcon,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
            cursorColor: const Color(0xFF0A0A0A),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 13, color: Color(0xFFFF3B30)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  errorText!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}