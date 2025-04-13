import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_provider.dart';

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
  List<dynamic> allUsers = []; // Semua data user
  List<dynamic> displayedUsers = []; // Data yang ditampilkan
  TextEditingController searchController = TextEditingController();
  String _currentSearchQuery = ""; // Menyimpan query pencarian terakhir

  @override
  void initState() {
    super.initState();
    _loadUsers();
    scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 100) {
      _loadUsers(loadMore: true);
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool loadMore = false}) async {
    if (loadMore) {
      if (!hasMore || isFetchingMore) return;
      setState(() => isFetchingMore = true);
      currentPage++;
    } else {
      currentPage = 1;
      allUsers.clear();
      displayedUsers.clear();
      setState(() => _isLoading = true);
    }

    try {
      final newUsers = await Provider.of<AuthProvider>(context, listen: false)
          .fetchUsers(page: currentPage);

      setState(() {
        allUsers.addAll(newUsers);

        // Terapkan pencarian ulang jika ada query
        if (_currentSearchQuery.isNotEmpty) {
          displayedUsers = _filterUsers(allUsers, _currentSearchQuery);
        } else {
          displayedUsers = List.from(allUsers);
        }

        hasMore = newUsers.length == 10;
        isFetchingMore = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        isFetchingMore = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  List<dynamic> _filterUsers(List<dynamic> users, String query) {
    return users.where((user) {
      final name = user['name'].toString().toLowerCase();
      final email = user['email'].toString().toLowerCase();
      return name.contains(query.toLowerCase()) ||
          email.contains(query.toLowerCase());
    }).toList();
  }

  void _search(String query) {
    setState(() {
      _currentSearchQuery = query;
      if (query.isEmpty) {
        displayedUsers = List.from(allUsers);
      } else {
        displayedUsers = _filterUsers(allUsers, query);
      }
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              searchController.clear();
              _loadUsers();
            },
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
          : displayedUsers.isEmpty
          ? Center(
        child: _currentSearchQuery.isNotEmpty
            ? const Text('Tidak ditemukan hasil pencarian')
            : const Text('Tidak ada user'),
      )
          : ListView.builder(
        controller: scrollController,
        itemCount: displayedUsers.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= displayedUsers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final user = displayedUsers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user['avatar'] != null
                  ? NetworkImage(user['avatar'])
                  : null,
              child: user['avatar'] == null
                  ? Text(user['name'][0].toUpperCase())
                  : null,
            ),
            title: Text(user['name']),
            subtitle: Text(user['email']),
          );
        },
      ),
    );
  }
}