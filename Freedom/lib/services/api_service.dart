import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  // GET semua user
  Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) {
        final map = Map<String, dynamic>.from(item);
        map['city'] = item['address']?['city'] ?? item['city'] ?? '';
        return User.fromJson(map);
      }).toList();
    } else {
      throw Exception('Gagal mengambil data User (${response.statusCode})');
    }
  }

  // GET satu user berdasarkan ID
  Future<User> getUserById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode == 200) {
      final map = Map<String, dynamic>.from(jsonDecode(response.body));
      map['city'] = map['address']?['city'] ?? map['city'] ?? '';
      return User.fromJson(map);
    } else {
      throw Exception('User dengan ID $id tidak ditemukan (${response.statusCode})');
    }
  }

  // POST user baru berdasarkan ID dari NIM (1000 + N)
  Future<User> createUser({
    required int nimLastThreeDigits,
    required String name,
    required String email,
    required String city,
  }) async {
    final newId = 1000 + nimLastThreeDigits;
    final body = {
      'id': newId,
      'name': name,
      'email': email,
      'city': city,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = Map<String, dynamic>.from(jsonDecode(response.body));
      return User(
        id: newId,
        name: decoded['name']?.toString() ?? name,
        email: decoded['email']?.toString() ?? email,
        city: decoded['city']?.toString() ?? city,
      );
    } else {
      throw Exception('Gagal menambah User (${response.statusCode})');
    }
  }

  // PUT: memperbarui nama dan email User
  Future<User> updateUserPut({
    required int id,
    required String name,
    required String email,
    required String city,
  }) async {
    final payload = {
      'id': id,
      'name': name,
      'email': email,
      'city': city,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return User(id: id, name: name, email: email, city: city);
    } else if (response.statusCode == 404 && id > 10) {
      // Fallback simulasi untuk ID custom (misal 1345)
      return User(id: id, name: name, email: email, city: city);
    } else {
      throw Exception('Gagal update PUT User (${response.statusCode})');
    }
  }

  // PATCH: memperbarui nama User dengan menambahkan "- Flutter Developer"
  Future<User> patchUserName({
    required User currentUser,
  }) async {
    const suffix = ' - Flutter Developer';
    final updatedName = currentUser.name.endsWith(suffix)
        ? currentUser.name
        : '${currentUser.name}$suffix';

    final response = await http.patch(
      Uri.parse('$baseUrl/users/${currentUser.id}'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'name': updatedName}),
    );

    if (response.statusCode == 200 || (response.statusCode == 404 && currentUser.id > 10)) {
      return User(
        id: currentUser.id,
        name: updatedName,
        email: currentUser.email,
        city: currentUser.city,
      );
    } else {
      throw Exception('Gagal PATCH nama User (${response.statusCode})');
    }
  }

  // DELETE: menghapus User berdasarkan ID
  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
    if (response.statusCode == 200 || (response.statusCode == 404 && id > 10)) {
      return;
    } else {
      throw Exception('Gagal menghapus User ID $id (${response.statusCode})');
    }
  }
}