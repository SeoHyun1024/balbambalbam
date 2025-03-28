import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/new/services/api/refresh_access_token.dart';
import 'package:flutter_application_1/new/services/token_manage.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class CustomTtsService {
  static final CustomTtsService _instance = CustomTtsService._internal();
  // 추가: instance에 대한 getter 메서드
  static CustomTtsService get instance => _instance;

  CustomTtsService._internal();

  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final String _baseUrl = '$mainUrl/cards/custom/';

  String? base64CorrectAudio; // 여기에 base64 오디오 데이터를 저장합니다.

  // 맞춤 문장 correctAudio API
  static Future<void> fetchCorrectAudio(int cardId) async {
    String? token = await getAccessToken();
    final audioUrl = '$_baseUrl$cardId';

    try {
      final response = await http.get(
        Uri.parse(audioUrl),
        headers: {
          'access': '$token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Custom TTS fetch complete');
        final jsonData = jsonDecode(response.body);
        final String? base64correctAudio = jsonData['correctAudio'];

        if (base64correctAudio != null) {
          _instance.base64CorrectAudio = base64correctAudio;
          await _instance.saveAudioToFile(cardId, base64correctAudio);
        } else {
          debugPrint('No audio data found in response.');
        }
      } else if (response.statusCode == 401) {
        debugPrint('Access token expired. Attempting to refresh...');
        if (await refreshAccessToken()) {
          debugPrint('Retrying request after token refresh...');
          await fetchCorrectAudio(cardId);
        } else {
          throw Exception('Token refresh failed.');
        }
      } else {
        final errorMessage = jsonDecode(response.body)['message'];
        throw Exception('Failed to load audio: $errorMessage');
      }
    } catch (e) {
      debugPrint('Error fetching audio: $e');
      rethrow;
    }
  }

  Future<void> saveAudioToFile(int cardId, String? base64String) async {
    if (base64String == null) {
      debugPrint('Base64 String is null, cannot save audio.');
      return;
    }

    try {
      final bytes = base64Decode(base64String);
      final String dir =
          (await getApplicationSupportDirectory()).path; // 저장 경로 변경
      final String fileName = 'custom_correct_audio_$cardId.wav';
      final String filePath = '$dir/$fileName';
      final File file = File(filePath);

      await file.writeAsBytes(bytes);
      debugPrint('Audio saved to: $filePath');

      // 파일 존재 여부 검증
      if (await file.exists()) {
        debugPrint('File saved successfully and verified at $filePath.');
      } else {
        debugPrint('File failed to save at $filePath.');
      }
    } catch (e) {
      debugPrint('Error saving audio file: $e');
    }
  }

  Future<void> playCachedAudio(int cardId) async {
    try {
      final String dir = (await getApplicationSupportDirectory()).path;
      final String fileName = 'custom_correct_audio_$cardId.wav';
      final File file = File('$dir/$fileName');

      if (await file.exists()) {
        debugPrint('Playing audio from: ${file.path}');
        await _audioPlayer.setSource(DeviceFileSource(file.path));
        await _audioPlayer.resume();
      } else {
        debugPrint('Audio file not found at: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error playing cached audio: $e');
    }
  }
}
