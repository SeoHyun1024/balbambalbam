import 'dart:convert';
import 'dart:io';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/userauthmanager.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart' as audioplayers;
import 'package:path_provider/path_provider.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  static TtsService get instance => _instance;

  TtsService._internal();

  static final audioplayers.AudioPlayer _audioPlayer =
      audioplayers.AudioPlayer();
  static final String _baseUrl = '$main_url/cards/';

  String? base64CorrectAudio;

  // correctAudio를 서버에서 가져오는 메서드
  static Future<void> fetchCorrectAudio(int cardId) async {
    String? token = await getAccessToken();
    final audioUrl = '$_baseUrl$cardId';
    try {
      final response = await http.get(
        Uri.parse(audioUrl),
        headers: <String, String>{
          'access': '$token',
          'Content-Type': 'application/json',
        },
      );
      // print("tts : ${response.body}");
      if (response.statusCode == 200) {
        // 응답이 성공적인 경우
        final jsonData = jsonDecode(response.body); // 응답 데이터를 디코딩
        final String base64correctAudio =
            jsonData['correctAudio']; // 오디오 데이터 추출
        _instance.base64CorrectAudio = base64correctAudio; // 인스턴스 변수에 저장
        // 오디오 파일로 저장
        await _instance.saveAudioToFile(cardId, base64correctAudio);
        return;
      } else if (response.statusCode == 401) {
        // 토큰이 만료된 경우
        print('Access token expired. Refreshing token...');

        // 토큰 갱신 시도
        bool isRefreshed = await refreshAccessToken();

        if (isRefreshed) {
          // 갱신에 성공하면 요청을 다시 시도
          print('Token refreshed successfully. Retrying request...');
          String? newToken = await getAccessToken();
          final retryResponse = await http.get(
            Uri.parse(audioUrl),
            headers: <String, String>{
              'access': '$newToken',
              'Content-Type': 'application/json',
            },
          );

          if (retryResponse.statusCode == 200) {
            final jsonData = jsonDecode(retryResponse.body);

            final String base64correctAudio = jsonData['correctAudio'];
            _instance.base64CorrectAudio = base64correctAudio;
            await _instance.saveAudioToFile(cardId, base64correctAudio);
            return;
          } else {
            final errorMessage = jsonDecode(retryResponse.body)['message'];
            throw Exception('Failed to load audio after retry: $errorMessage');
          }
        } else {
          print('Failed to refresh token. Please log in again.');
          throw Exception('Failed to refresh token.');
        }
      } else {
        final errorMessage = jsonDecode(response.body)['message'];
        throw Exception('Failed to load audio: $errorMessage');
      }
    } catch (e) {
      print('Error occurred: $e');
      rethrow;
    }
  }

  // 오디오 데이터를 파일로 저장하는 메서드
  Future<void> saveAudioToFile(int cardId, String base64String) async {
    final bytes = base64Decode(base64String);
    final String dir = (await getTemporaryDirectory()).path;
    final String fileName = 'correct_audio_$cardId.wav';
    final File file = File('$dir/$fileName');

    await file.writeAsBytes(bytes);
  }

  // 저장된 오디오 파일을 재생하는 메서드
  Future<void> playCachedAudio(int cardId) async {
    final String dir = (await getTemporaryDirectory()).path;
    final String fileName = 'correct_audio_$cardId.wav';
    final File file = File('$dir/$fileName');

    await Future.delayed(const Duration(seconds: 2)); // 혹시 몰라서 딜레이 2초

    await _audioPlayer.play(audioplayers.DeviceFileSource(file.path));
  }
}
