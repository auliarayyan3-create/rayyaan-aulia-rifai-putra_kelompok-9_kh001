import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/admin.dart';
import '../services/api_service.dart';
import '../services/admin.service.dart';

class MainHomePage extends StatefulWidget {
  final int nimLastThreeDigits;

  const MainHomePage({
    super.key,
    required this.nimLastThreeDigits,
  });

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ApiService _apiService = ApiService();
  late final AdminService _adminService;

  List<User> _users = [];
  List<Admin> _admins = [];
  bool _loadingUsers = false;
  bool _loadingAdmins = false;

  final TextEditingController _userIdSearchController = TextEditingController();
  final TextEditingController _adminIdSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _adminService = AdminService(nimLastThreeDigits: widget.nimLastThreeDigits);
    _fetchUsers();
    _fetchAdmins();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userIdSearchController.dispose();
    _adminIdSearchController.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------- USER OPERATIONS ----------------

  Future<void> _fetchUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final list = await _apiService.getUsers();
      setState(() => _users = list);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _searchUserById() async {
    final id = int.tryParse(_userIdSearchController.text.trim());
    if (id == null) {
      _showMessage('Masukkan ID User berupa angka');
      return;
    }

    final localMatch = _users.where((u) => u.id == id).toList();
    if (localMatch.isNotEmpty) {
      _showUserDetailDialog(localMatch.first);
      return;
    }

    try {
      final user = await _apiService.getUserById(id);
      _showUserDetailDialog(user);
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _showUserDetailDialog(User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detail User #${user.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${user.id}'),
            Text('Nama: ${user.name}'),
            Text('Email: ${user.email}'),
            Text('Kota: ${user.city}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _openCreateUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final newId = 1000 + widget.nimLastThreeDigits;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah User (ID: $newId)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final created = await _apiService.createUser(
                  nimLastThreeDigits: widget.nimLastThreeDigits,
                  name: nameCtrl.text.trim().isEmpty ? 'User $newId' : nameCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty ? 'user$newId@mail.com' : emailCtrl.text.trim(),
                  city: cityCtrl.text.trim().isEmpty ? 'Bekasi' : cityCtrl.text.trim(),
                );
                setState(() {
                  _users.removeWhere((u) => u.id == created.id);
                  _users.insert(0, created);
                });
                _showMessage('User ID ${created.id} ditambahkan');
              } catch (e) {
                _showMessage(e.toString());
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _openEditUserPutDialog(User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('PUT User #${user.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Baru')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Baru')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final updated = await _apiService.updateUserPut(
                  id: user.id,
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  city: user.city,
                );
                setState(() {
                  final idx = _users.indexWhere((u) => u.id == user.id);
                  if (idx != -1) _users[idx] = updated;
                });
                _showMessage('User #${user.id} diperbarui');
              } catch (e) {
                _showMessage(e.toString());
              }
            },
            child: const Text('Update PUT'),
          ),
        ],
      ),
    );
  }

  Future<void> _patchUser(User user) async {
    try {
      final patched = await _apiService.patchUserName(currentUser: user);
      setState(() {
        final idx = _users.indexWhere((u) => u.id == user.id);
        if (idx != -1) _users[idx] = patched;
      });
      _showMessage('Nama User #${user.id} di-PATCH');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  Future<void> _deleteUser(User user) async {
    try {
      await _apiService.deleteUser(user.id);
      setState(() {
        _users.removeWhere((u) => u.id == user.id);
      });
      _showMessage('User #${user.id} dihapus');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  // ---------------- ADMIN OPERATIONS ----------------

  Future<void> _fetchAdmins() async {
    setState(() => _loadingAdmins = true);
    try {
      final list = await _adminService.getAdmins();
      setState(() => _admins = list);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _loadingAdmins = false);
    }
  }

  Future<void> _searchAdminById() async {
    final id = int.tryParse(_adminIdSearchController.text.trim());
    if (id == null) {
      _showMessage('Masukkan ID Admin berupa angka');
      return;
    }

    final localMatch = _admins.where((a) => a.id == id).toList();
    if (localMatch.isNotEmpty) {
      _showAdminDetailDialog(localMatch.first);
      return;
    }

    try {
      final admin = await _adminService.getAdmin(id);
      _showAdminDetailDialog(admin);
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _showAdminDetailDialog(Admin admin) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Detail Admin #${admin.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${admin.id}'),
            Text('Nama: ${admin.name}'),
            Text('Email: ${admin.email}'),
            Text('Department: ${admin.department}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAdminById(int id) async {
    try {
      await _adminService.deleteAdmin(id);
      setState(() {
        _admins.removeWhere((a) => a.id == id);
      });
      _showMessage('Admin dengan ID $id berhasil dihapus');
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  // ---------------- UI BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRUD User & Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Users'),
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'Admins'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildAdminsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateUserDialog,
        icon: const Icon(Icons.add),
        label: Text('User ${1000 + widget.nimLastThreeDigits}'),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userIdSearchController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cari Detail User by ID',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _searchUserById,
                child: const Text('Detail'),
              ),
              IconButton(
                onPressed: _fetchUsers,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh GET Users',
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingUsers
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _users.length,
            itemBuilder: (_, index) {
              final user = _users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text('#${user.id} - ${user.name}'),
                  subtitle: Text('${user.email} • ${user.city}'),
                  onTap: () => _showUserDetailDialog(user),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'PUT Edit',
                        onPressed: () => _openEditUserPutDialog(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.badge),
                        tooltip: 'PATCH + Flutter Developer',
                        onPressed: () => _patchUser(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'DELETE',
                        onPressed: () => _deleteUser(user),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _adminIdSearchController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cari / Hapus Admin by ID (mis. ${2000 + widget.nimLastThreeDigits})',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _searchAdminById,
                child: const Text('Detail'),
              ),
              const SizedBox(width: 4),
              OutlinedButton(
                onPressed: () {
                  final id = int.tryParse(_adminIdSearchController.text.trim());
                  if (id == null) {
                    _showMessage('Masukkan ID Admin yang ingin dihapus');
                    return;
                  }
                  _deleteAdminById(id);
                },
                child: const Text('Hapus ID'),
              ),
              IconButton(
                onPressed: _fetchAdmins,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh GET Admins',
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingAdmins
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: _admins.length,
            itemBuilder: (_, index) {
              final admin = _admins[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  title: Text('#${admin.id} - ${admin.name}'),
                  subtitle: Text('${admin.email} • Dept: ${admin.department}'),
                  onTap: () => _showAdminDetailDialog(admin),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Hapus Admin',
                    onPressed: () => _deleteAdminById(admin.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}