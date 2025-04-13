import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_provider.dart';
import '../user/user_detail.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  int currentPage = 1;
  bool hasMore = true;
  bool isFetchingMore = false;
  ScrollController scrollController = ScrollController();

  bool _isLoading = true;
  List<dynamic> filteredUsers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();

    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 100) {
        _loadUsers(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore || isFetchingMore) return;
      setState(() => isFetchingMore = true);
      currentPage++;
    } else {
      currentPage = 1;
      filteredUsers.clear();
      setState(() => _isLoading = true);
    }

    final newUsers = await Provider.of<AuthProvider>(context, listen: false).fetchUsers(page: currentPage);

    setState(() {
      if (loadMore) {
        filteredUsers.addAll(newUsers);
      } else {
        filteredUsers = List.from(newUsers);
      }

      hasMore = newUsers.length == 10;
      isFetchingMore = false;
      _isLoading = false;
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _search(String query) {
    final result = filteredUsers.where((user) {
      final name = user['name'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() => filteredUsers = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Cari user...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredUsers.isEmpty
          ? const Center(child: Text('Tidak ada user'))
          : ListView.builder(
        controller: scrollController,
        itemCount: filteredUsers.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filteredUsers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final user = filteredUsers[index];
          return ListTile(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetail(user: user),
                ),
              );
              if (result == true) {
                _loadUsers(); // Refresh from page 1
              }
            },
            leading: CircleAvatar(
              backgroundImage: user['avatar'] != null
                  ? NetworkImage('http://10.0.2.2:8000/storage/${user['avatar']}')
                  : null,
              child: user['avatar'] == null ? Text(user['name'][0].toUpperCase()) : null,
            ),
            title: Text(user['name']),
            subtitle: Text(user['email']),
          );
        },
      )
    );
  }
}
