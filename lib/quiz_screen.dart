import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'quiz_setup_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  _QuizSetupScreenState createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  int _numQuestions = 10;
  String? _selectedCategory;
  String? _selectedDifficulty;
  String? _selectedType;

  List<Map<String, String>> _categories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('https://opentdb.com/api_category.php'));
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Decoded data: $data");

        if (data['trivia_categories'] != null) {
          setState(() {
            _categories = List<Map<String, String>>.from(
              (data['trivia_categories'] as List).map(
                (category) => {
                  'id': category['id'].toString(),
                  'name': category['name'].toString()
                },
              ),
            );
            _isLoadingCategories = false;
          });
          print("Categories fetched successfully: $_categories");
        } else {
          throw Exception("Invalid data structure received.");
        }
      } else {
        throw Exception("Failed to fetch categories. Server returned status ${response.statusCode}.");
      }
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() {
        _categories = [];
        _isLoadingCategories = false;
      });
      _showError("An error occurred while fetching categories. Please check your internet connection and try again.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startQuiz() {
    if (_selectedCategory == null || _selectedDifficulty == null || _selectedType == null) {
      _showError("Please select all options before starting the quiz.");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          numQuestions: _numQuestions,
          category: _selectedCategory!,
          difficulty: _selectedDifficulty!,
          type: _selectedType!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      appBar: AppBar(
        title: const Text("Quiz Setup"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Number of Questions"),
              value: _numQuestions,
              items: [5, 10, 15]
                  .map((e) => DropdownMenuItem<int>(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _numQuestions = value!;
                });
              },
            ),
            const SizedBox(height: 10),
            _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Category"),
                    value: _selectedCategory,
                    items: _categories
                        .map((e) => DropdownMenuItem<String>(
                              value: e['id'],
                              child: Text(e['name']!),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Difficulty"),
              value: _selectedDifficulty,
              items: ['easy', 'medium', 'hard']
                  .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Question Type"),
              value: _selectedType,
              items: ['multiple', 'boolean']
                  .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startQuiz,
              child: const Text("Start Quiz"),
            ),
          ],
        ),
      ),
    );
  }
}
