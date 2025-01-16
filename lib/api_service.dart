import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  Future<List<Language>> fetchLanguages() async {
    try {
      final response = await http.get(
        Uri.parse('https://bolls.life/static/bolls/app/views/languages.json'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Language.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      print('Error fetching languages: $e');
      rethrow;
    }
  }

  Future<List<Book>> fetchBooks(String translation) async {
    try {
      final response = await http.get(
        Uri.parse('https://bolls.life/get-books/$translation/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error fetching books: $e');
      rethrow;
    }
  }

  Future<List<Verse>> fetchChapterText(String translation, String bookId, String chapter) async {
    try {
      final response = await http.get(
        Uri.parse('https://bolls.life/get-text/$translation/$bookId/$chapter/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Verse.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chapter text');
      }
    } catch (e) {
      print('Error fetching chapter text: $e');
      rethrow;
    }
  }
}