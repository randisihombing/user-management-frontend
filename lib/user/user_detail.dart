import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';

class UserDetail extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetail({super.key, required this.user});

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  File? _image;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user['name']);
    emailController = TextEditingController(text: widget.user['email']);
  }

  String formatDate(String dateStr) {
    final dateTime = DateTime.parse(dateStr);
    return DateFormat("d MMMM yyyy").format(dateTime.toLocal());
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  // void _saveChanges() async {
  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
  //
  //   final updatedUser = await authProvider.updateProfile(
  //     name: nameController.text,
  //     email: emailController.text,
  //     avatar: _image,
  //   );
  //
  //   if (updatedUser != null) {
  //     setState(() {
  //       widget.user['name'] = updatedUser['name'];
  //       widget.user['email'] = updatedUser['email'];
  //       widget.user['avatar'] = updatedUser['avatar'];
  //     });
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Perubahan berhasil disimpan')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Gagal menyimpan perubahan')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final avatarInitial = widget.user['name'][0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (widget.user['avatar'] != null
                      ? NetworkImage("http://10.0.2.2:8000/storage/${widget.user['avatar']}")
                      : null) as ImageProvider?,

                  child: _image == null
                      ? Text(
                    avatarInitial,
                    style: const TextStyle(fontSize: 30),
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Nama:', style: Theme.of(context).textTheme.titleMedium),
            ),
            TextField(controller: nameController),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Email:', style: Theme.of(context).textTheme.titleMedium),
            ),
            TextField(controller: emailController),
            const SizedBox(height: 16),
            if (widget.user.containsKey('created_at')) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Dibuat pada:', style: Theme.of(context).textTheme.titleMedium),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  formatDate(widget.user['created_at']),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            // onPressed: _saveChanges,
              onPressed: () async {
                final updatedUser = await Provider.of<AuthProvider>(context, listen: false)
                    .updateUserById(
                  id: widget.user['id'], // kirim ID user
                  name: nameController.text,
                  email: emailController.text,
                  avatar: _image,
                );

                if (updatedUser != null) {
                  setState(() {
                    widget.user['name'] = updatedUser['name'];
                    widget.user['email'] = updatedUser['email'];
                    widget.user['avatar'] = updatedUser['avatar'];
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perubahan berhasil disimpan')),
                  );
                  if (!mounted) return;
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menyimpan perubahan')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Simpan Perubahan'),
          ),
        ),
      ),
    );
  }
}
