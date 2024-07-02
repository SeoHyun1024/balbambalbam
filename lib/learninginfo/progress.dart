import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/token.dart';
import 'package:http/http.dart' as http;

class LearningProgressScreen extends StatelessWidget {
  final double syllableProgress;
  final double wordProgress;
  final double sentenceProgress;

  LearningProgressScreen({
    required this.syllableProgress,
    required this.wordProgress,
    required this.sentenceProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: Color.fromARGB(230, 255, 255, 255),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // SizedBox(height: 10),
              Text(
                'Learning Progress Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              CustomProgressBar(
                value: syllableProgress / 100,
                color: const Color(0xFFFE6E88),
                label: 'Syllable',
              ),
              SizedBox(height: 12),
              CustomProgressBar(
                value: wordProgress / 100,
                color: const Color(0xFF466CFF),
                label: 'Word',
              ),
              SizedBox(height: 12),
              CustomProgressBar(
                value: sentenceProgress / 100,
                color: const Color(0xFF3AB9FE),
                label: 'Sentence',
              ),
              SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final String label;

  CustomProgressBar({
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        SizedBox(width: 5),
        Container(
          // width: 210,
          width: MediaQuery.of(context).size.width * 0.58,
          height: 18,
          decoration: BoxDecoration(
            //borderRadius: BorderRadius.circular(2),
            color: Colors.grey[300],
          ),
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.58 * value,
                height: 18,
                decoration: BoxDecoration(
                  //borderRadius: BorderRadius.circular(15),
                  color: color,
                ),
              ),
              Center(
                child: Text(
                  '${(value * 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<Map<String, double>> fetchProgressData() async {
  var url = Uri.parse('http://potato.seatnullnull.com/learning/progress');
  String? token = await getAccessToken();

  // Set headers with the token
  var headers = <String, String>{
    'access': '$token',
    'Content-Type': 'application/json',
  };
  var response = await http.get(url, headers: headers);

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    return {
      'syllableProgress': data['syllableProgress'],
      'wordProgress': data['wordProgress'],
      'sentenceProgress': data['sentenceProgress'],
    };
  } else {
    throw Exception('Failed to load progress data');
  }
}
