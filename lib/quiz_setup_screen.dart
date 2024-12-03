import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizScreen extends StatefulWidget {
  final int numQuestions;
  final String? category;
  final String? difficulty;
  final String? type;

  const QuizScreen({
    required this.numQuestions,
    this.category,
    this.difficulty,
    this.type,
    super.key,
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _timer = 15;
  bool _isAnswered = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    try {
      final url =
          'https://opentdb.com/api.php?amount=${widget.numQuestions}&category=${widget.category}&difficulty=${widget.difficulty}&type=${widget.type}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response_code'] == 0 && data['results'].isNotEmpty) {
          if (mounted) {
            setState(() {
              _questions = data['results'];
            });
            _startTimer();
          }
        } else {
          _showError("No questions available. Try different settings.");
        }
      } else {
        _showError("Failed to load questions. Please try again.");
      }
    } catch (e) {
      _showError("An error occurred while fetching questions.");
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _timer = 15;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer == 0) {
        _nextQuestion();
      } else {
        if (mounted) {
          setState(() {
            _timer--;
          });
        }
      }
    });
  }

  void _nextQuestion() {
    if (mounted) {
      setState(() {
        _isAnswered = false;
      });

      if (_currentQuestionIndex < _questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
        });
        _startTimer();
      } else {
        _countdownTimer?.cancel();
        _showSummary();
      }
    }
  }

  void _answerQuestion(bool correct) {
    if (_isAnswered) return;

    if (mounted) {
      setState(() {
        _isAnswered = true;
        if (correct) _score++;
      });
    }

    Future.delayed(const Duration(seconds: 2), _nextQuestion);
  }

  void _showSummary() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Quiz Finished"),
        content: Text("Your score is $_score/${widget.numQuestions}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Back to Setup"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  _currentQuestionIndex = 0;
                  _score = 0;
                  _timer = 15;
                });
              }
              _startTimer();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = _questions[_currentQuestionIndex];
    List<String> answers;
    if (question['type'] == 'multiple') {
      // Order answers as provided by the API, without shuffling
      answers = [question['correct_answer'], ...List<String>.from(question['incorrect_answers'])];
    } else {
      answers = ['True', 'False'];
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
            ),
            const SizedBox(height: 20),
            Text(
              _decodeHtml(question['question']),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ...answers.map((answer) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _isAnswered
                      ? null
                      : () => _answerQuestion(answer == question['correct_answer']),
                  child: Text(_decodeHtml(answer)),
                ),
              );
            }),
            const Spacer(),
            Text("Time left: $_timer seconds"),
          ],
        ),
      ),
    );
  }

  String _decodeHtml(String text) {
    return const HtmlEscape().convert(text);
  }
}
