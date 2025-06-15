import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'HomePage.dart';
import 'register_screen.dart';
import 'questionnaire_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _loginWithEmail() async {
    setState(() => isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      final doc = await FirebaseFirestore.instance.collection('questionnaires').doc(uid).get();

      setState(() => isLoading = false);

      if (doc.exists) {
        print('✅ Questionnaire data found. Navigating to Dashboard.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        print('🟡 No questionnaire data found. Navigating to Questionnaire.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => QuestionnaireScreen()),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('🚨 Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }


  Future<void> _loginWithFacebook() async {
    setState(() => isLoading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(result.accessToken!.token);

        await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);

        final uid = FirebaseAuth.instance.currentUser!.uid;
        final doc = await FirebaseFirestore.instance.collection('questionnaires').doc(uid).get();

        if (doc.exists) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuestionnaireScreen()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Facebook login failed: ${result.message}")),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Facebook error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login"), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) =>
                value == null || !value.contains('@') ? "Enter valid email" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                value == null || value.length < 6 ? "Minimum 6 characters" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loginWithEmail,
                child: const Text("Login"),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loginWithFacebook,
                icon: const Icon(Icons.facebook, color: Colors.white),
                label: const Text("Login with Facebook"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _navigateToRegister,
                child: const Text("Don't have an account? Sign up here"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
