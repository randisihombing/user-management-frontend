import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_management_frontend/login/register.dart';
import '../auth/auth_provider.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                controller: emailController,
                onSaved: (value){
                  email = value!;
                },
                validator: (value){
                  if(value!.isEmpty){
                    return 'Email tidak boleh kosong';
                  } else {
                    return null;
                  }
                }
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                controller: passwordController,
                onSaved: (value) => password = value!,
                validator: (value) {
                  if(value!.isEmpty) {
                    return 'Password tidak boleh kosong';
                  } else {
                    return null;
                  }
                },
                onChanged: (password){
                  // passwordController.text.
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    authProvider.login(context, email, password);
                  }
                },
                child: authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPassword()),
                  );
                },
                child: const Text('Lupa Password?'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Register()),
                  );
                },
                child: const Text('Belum punya akun? Daftar di sini'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
