import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin.dart';

class AdminService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  final int nimLastThreeDigits;

  AdminService({required this.nimLastThreeDigits});

  int get adminIdFromNim => 2000 + nimLastThreeDigits;

  // Mengambil seluruh data Admin (termasuk ID 2000 + N)
  Future<List<Admin>> getAdmins() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(response.body);
      final departments = ['IT & Security', 'Operations', 'Academic System'];

      final admins = rawList.take(3).toList().asMap().entries.map((entry) {
        final idx = entry.key;
        final item = Map<String, dynamic>.from(entry.value);
        return Admin.fromJson({
          'id': item['id'],
          'name': 'Admin ${item['name'] ?? ''}',
          'email': item['email'] ?? '',
          'department': departments[idx % departments.length],
        });
      }).toList();

      // Tambahkan Admin khusus berbasis NIM: 2000 + N
      admins.insert(
        0,
        Admin(
          id: adminIdFromNim,
          name: 'Admin NIM $nimLastThreeDigits',
          email: 'admin.$nimLastThreeDigits@campus.ac.id',
          department: 'System Administration',
        ),
      );

      return admins;
    } else {
      throw Exception('Gagal mengambil data Admin (${response.statusCode})');
    }
  }

  // Mengambil satu data Admin berdasarkan ID
  Future<Admin> getAdmin(int id) async {
    final allAdmins = await getAdmins();
    try {
      return allAdmins.firstWhere((admin) => admin.id == id);
    } catch (_) {
      final response = await http.get(Uri.parse('$baseUrl/users/$id'));
      if (response.statusCode == 200) {
        final map = Map<String, dynamic>.from(jsonDecode(response.body));
        return Admin.fromJson({
          'id': map['id'],
          'name': 'Admin ${map['name'] ?? ''}',
          'email': map['email'] ?? '',
          'department': 'General Administration',
        });
      }
      throw Exception('Admin dengan ID $id tidak ditemukan');
    }
  }

  // Menghapus data Admin berdasarkan ID
  Future<void> deleteAdmin(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode == 200 || (response.statusCode == 404 && id >= 2000)) {
      return;
    } else {
      throw Exception('Gagal menghapus Admin ID $id (${response.statusCode})');
    }
  }
}