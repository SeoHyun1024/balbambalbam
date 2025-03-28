import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/new/functions/show_common_dialog.dart';
import 'package:flutter_application_1/new/functions/show_feedback_dialog.dart';
import 'package:flutter_application_1/new/models/app_colors.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/home/home_nav.dart';
import 'package:flutter_application_1/new/services/api/refresh_access_token.dart';
import 'package:flutter_application_1/new/services/token_manage.dart';
import 'package:flutter_application_1/widgets/exit_dialog.dart';
import 'package:flutter_application_1/function.dart';
import 'package:flutter_application_1/permissionservice.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 하루 한 개씩 추천 카드
class TodayLearningCard extends StatefulWidget {
  int cardId;

  TodayLearningCard({
    Key? key,
    required this.cardId,
  }) : super(key: key);

  @override
  State<TodayLearningCard> createState() => _TodayLearningCardState();
}

class _TodayLearningCardState extends State<TodayLearningCard> {
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final PermissionService _permissionService = PermissionService();
  bool _isRecording = false;
  bool _canRecord = true;
  late String _recordedFilePath;

  bool _isLoading = false;
  bool _isFeedbackLoading = false;

  String cardText = '';
  String cardPronunciation = '';
  String cardSummary = '';
  String cardCorrectAudio = '';

  @override
  void initState() {
    super.initState();
    _initialize();
    fetchData();
  }

  Future<void> _initialize() async {
    await _permissionService.requestPermissions();
    await _audioRecorder.openRecorder();
  }

  // 학습카드 리스트 API (음절, 단어, 문장)
  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String? token = await getAccessToken();
      // Backend server URL
      var url = Uri.parse('$mainUrl/cards/today/${widget.cardId}');

      // Function to make the request
      Future<http.Response> makeRequest(String token) {
        var headers = <String, String>{
          'access': token,
          'Content-Type': 'application/json',
        };
        return http.get(url, headers: headers);
      }

      var response = await makeRequest(token!);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          cardText = data['text'];
          cardPronunciation = data['cardPronunciation'];
          cardSummary = data['cardSummary'];
          cardCorrectAudio = data['correctAudio'];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Token expired, attempt to refresh the token
        debugPrint('Access token expired. Refreshing token...');

        // Refresh the access token
        bool isRefreshed = await refreshAccessToken();
        if (isRefreshed) {
          // Retry the request with the new token
          token = await getAccessToken();
          response = await makeRequest(token!);

          if (response.statusCode == 200) {
            var data = json.decode(response.body);
            setState(() {
              cardText = data['text'];
              cardPronunciation = data['cardPronunciation'];
              cardSummary = data['cardSummary'];
              cardCorrectAudio = data['correctAudio'];
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("$e");
      setState(() {
        _isLoading = false;
      });
    }
    return; // Return null if there's an error or unsuccessful fetch
  }

  Future<void> _recordAudio() async {
    if (_isRecording) {
      final path = await _audioRecorder.stopRecorder();

      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
          _isFeedbackLoading = true; // Start loading
        });
        final audioFile = File(path);
        final fileBytes = await audioFile.readAsBytes();
        final base64userAudio = base64Encode(fileBytes);
        final currentCardId = widget.cardId;

        try {
          // Set a timeout for the getFeedback call
          final feedbackData = await getTodayFeedback(
            currentCardId,
            base64userAudio,
            cardCorrectAudio,
          ).timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              throw TimeoutException('Feedback request timed out');
            },
          );

          if (mounted && feedbackData != null) {
            setState(() {
              _isFeedbackLoading = false; // Stop loading
            });
            showFeedbackDialog(
                context, feedbackData, _recordedFilePath, cardText);
          } else {
            setState(() {
              _isFeedbackLoading = false; // Stop loading
            });
            if (!mounted) return; // 위젯이 여전히 존재하는지 확인
            showCommonDialog(context,
                dialogType: DialogType.recordingError); // 녹음 오류 dialog
          }
        } catch (e) {
          setState(() {
            _isLoading = false; // Stop loading
            _isFeedbackLoading = false;
          });
          if (e.toString() == 'Exception: ReRecordNeeded') {
            if (!mounted) return; // 위젯이 여전히 존재하는지 확인
            showCommonDialog(context,
                dialogType: DialogType.recordingError,
                recordingErrorType:
                    RecordingErrorType.tooShort); // 녹음 길이가 너무 짧음
          } else if (e is TimeoutException) {
            if (!mounted) return; // 위젯이 여전히 존재하는지 확인
            showCommonDialog(context,
                dialogType: DialogType.recordingError,
                recordingErrorType: RecordingErrorType.timeout); // 서버 타임아웃
          } else {
            if (!mounted) return; // 위젯이 여전히 존재하는지 확인
            showCommonDialog(context,
                dialogType: DialogType.recordingError); // 녹음 오류 dialog
          }
        }
      }
    } else {
      await _audioRecorder.startRecorder(
        toFile: 'audio_record.wav',
        codec: Codec.pcm16WAV,
      );
      setState(() {
        _isRecording = true;
      });
    }
  }

  void _onListenPressed() async {
    try {
      if (!_audioPlayer.isOpen()) {
        await _audioPlayer.openPlayer();
      }

      Uint8List audioBytes = base64Decode(cardCorrectAudio);
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/correct_audio.wav';
      final audioFile = File(filePath);
      await audioFile.writeAsBytes(audioBytes);

      await _audioPlayer.startPlayer(fromURI: filePath, codec: Codec.pcm16WAV);

      setState(() {
        _canRecord = true;
      });
    } catch (e) {
      debugPrint("오디오 재생 중 오류 발생: $e");
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final double height = MediaQuery.of(context).size.height / 852;
        final double width = MediaQuery.of(context).size.width / 393;

        return ExitDialog(
          width: width,
          height: height,
          page: HomeNav(),
        );
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.closePlayer();
    _audioRecorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.70;
    double cardHeight = MediaQuery.of(context).size.height * 0.27;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: bam,
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 3.8, 0),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.black,
                size: 30,
              ),
              onPressed: _showExitDialog,
            ),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      body: Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: primary,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: cardWidth,
                            height: cardHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: const Color(0xFFF26647), width: 3.w),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  cardText,
                                  style: TextStyle(
                                      fontSize: 36.h,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "[$cardPronunciation]",
                                  style: TextStyle(
                                      fontSize: 22, color: Colors.grey[700]),
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF26647),
                                    minimumSize: const Size(220, 40),
                                  ),
                                  onPressed: _onListenPressed,
                                  icon: const Icon(
                                    Icons.volume_up,
                                    color: Colors.white,
                                  ),
                                  label: const Text(
                                    'Listen',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 50.h,
                  ),
                  _isFeedbackLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFF26647)),
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.all(10.w),
                              child: Text(
                                "Meaning of the word",
                                style: TextStyle(
                                  fontSize: 18.w,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 25.h,
                            ),
                            Container(
                              width: 280.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.all(10.w),
                              child: Text(
                                cardSummary,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28.w,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
      ),
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: _canRecord && !_isLoading ? _recordAudio : null,
          backgroundColor: _isLoading
              ? const Color.fromARGB(37, 206, 204, 204) // 로딩 중 색상
              : _canRecord
                  ? (_isRecording
                      ? const Color(0xFF976841)
                      : const Color(0xFFF26647))
                  : const Color.fromARGB(37, 206, 204, 204),
          elevation: 0.0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(35))), // 조건 업데이트
          child: Icon(
            _isRecording ? Icons.stop : Icons.mic,
            size: 40,
            color: const Color.fromARGB(231, 255, 255, 255),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
