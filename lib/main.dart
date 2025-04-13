import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:user_management_frontend/home/home.dart';
import 'package:user_management_frontend/login/forgot_password.dart';
import 'package:user_management_frontend/login/login.dart';
import 'package:user_management_frontend/login/register.dart';
import 'package:user_management_frontend/user/user_detail.dart';

import 'auth/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cek mode release atau debug
  bool isRelease = bool.fromEnvironment("dart.vm.product");

  // await dotenv.load(fileName: isRelease ? ".env.production" : ".env");
  await dotenv.load(fileName: ".env.production");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: '/', // ⬅️ route awal
        routes: {
          '/': (context) => const LoginScreen(),
          '/forgot_password': (context) => const ForgotPassword(),
          '/register': (context) => const Register(),
          '/home': (context) => const Home(),
        },
      ),
    );
  }
}