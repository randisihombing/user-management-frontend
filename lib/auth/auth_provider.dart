import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  // String baseUrl = "http://10.0.2.2:8000/api";
  String baseUrl = dotenv.env['BASE_URL'] ?? 'https://user-management-backen-production.up.railway.app/api';

  List<dynamic> _users = [];
  List<dynamic> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int currentPage = 1;
  int lastPage = 1;
  List<dynamic> listUser = [];

  Future<void> login(BuildContext context, String email, String password) async {
    _isLoading = true;
    notifyListeners();


    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
      },
      body: {
        'email': email,
        'password': password,
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    _isLoading = false;
    notifyListeners();

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['access_token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['access_token']);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Login berhasil')));
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Login gagal')),
      );
    }
  }

  Future<bool> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
        },
        body: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final token = data['access_token'];

        // Simpan token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);

        notifyListeners();
        return true;
      } else {
        // Handle error dari response (misal: validation)
        debugPrint('Register failed: ${data['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {'email': email},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        debugPrint('Email reset terkirim: ${data['message']}');
        return true;
      } else {
        debugPrint('Gagal kirim reset email: ${data['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error forgot password: $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchUsers({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      debugPrint('Token tidak ditemukan');
      return [];
    }

    final url = Uri.parse('$baseUrl/users?page=$page');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        return data['data']; // langsung return data
      } else {
        debugPrint('Gagal ambil data user: ${data['message']}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetchUsers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> updateUserById({
    required int id,
    required String name,
    required String email,
    File? avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/users/update/$id');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['name'] = name
      ..fields['email'] = email;

    if (avatar != null) {
      final file = await http.MultipartFile.fromPath('avatar', avatar.path);
      request.files.add(file);
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('User berhasil diupdate: $data');
      return data['user'];
    } else {
      print('Gagal update user: ${response.statusCode}');
      print(response.body);
      return null;
    }
  }


  Future<Map<String, dynamic>?> updateProfile({
    required String name,
    required String email,
    File? avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/user/update');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['name'] = name
      ..fields['email'] = email;

    if (avatar != null) {
      final file = await http.MultipartFile.fromPath('avatar', avatar.path);
      request.files.add(file);
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Profil berhasil diupdate: $data');
      return data['user'];
    } else {
      print('Gagal update: ${response.statusCode}');
      print(response.body);
      return null;
    }
  }


}
