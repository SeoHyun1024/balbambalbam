// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/new/functions/show_feedback_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/new/functions/show_common_dialog.dart';
import 'package:flutter_application_1/new/models/app_colors.dart';
import 'package:flutter_application_1/function.dart';
import 'package:flutter_application_1/learning_coures/syllables/fetchimage.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/home/home_nav.dart';
import 'package:flutter_application_1/new/services/api/weak_sound_test_api.dart';
import 'package:flutter_application_1/new/services/api/refresh_access_token.dart';
import 'package:flutter_application_1/permissionservice.dart';
import 'package:flutter_application_1/widgets/exit_dialog.dart';
import 'package:flutter_application_1/new/services/token_manage.dart';
import 'package:flutter_application_1/report/vulnerablesoundtest/updatecardweaksound.dart';
import 'package:flutter_application_1/widgets/success_dialog.dart';

class TodayCourseLearningCard extends StatefulWidget {
  int courseSize;
  List<int> ids = [];
  List<String> texts = [];
  List<String> correctAudios = [];

  List<String> cardTranslations = [];
  List<String> cardPronunciations = [];
  List<String> pictureUrls = [];
  List<String> explanations = [];

  List<bool> weakCards = [];
  List<bool> bookmarks = [];

  TodayCourseLearningCard({
    super.key,
    required this.courseSize,
    required this.ids,
    required this.texts,
    required this.correctAudios,
    required this.cardTranslations,
    required this.cardPronunciations,
    required this.pictureUrls,
    required this.explanations,
    required this.weakCards,
    required this.bookmarks,
  });

  @override
  TodayCourseLearningCardState createState() => TodayCourseLearningCardState();
}

class TodayCourseLearningCardState extends State<TodayCourseLearningCard> {
  late FlutterSoundRecorder _recorder;
  late String _recordedFilePath; // 녹음된 파일 경로

  bool _isRecording = false;
  bool _isRecorded = false;
  bool _canRecord = true;
  int _currentIndex = 0;

  bool _isLoading = false; // 피드백 로딩 중인지 여부
  Uint8List? _imageData; // 이미지를 저장할 변수
  bool _isImageLoading = true; // 이미지 로딩 중인지 여부

  FlutterSoundPlayer audioPlayer = FlutterSoundPlayer();

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final PermissionService _permissionService = PermissionService();

  // 학습한 카드 갯수 변수
  int learnedCardCount = 0;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _loadImage();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await _permissionService.requestPermissions();
    await _recorder.openRecorder();
    await audioPlayer.openPlayer();
  }

  // 카드 학습 후 학습한 카드 갯수 업데이트
  Future<void> incrementLearnedCardCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('learnedCardCount') ?? 0;
    currentCount++;
    await prefs.setInt('learnedCardCount', currentCount);
    setState(() {
      learnedCardCount = currentCount;
    });
  }

  // 마지막 학습 카드 ID 저장
  Future<void> saveLastFinishedCard(int cardId) async {
    await secureStorage.write(
        key: 'lastFinishedCardId', value: cardId.toString());
    debugPrint("Saved last finished card ID: $cardId");
  }

  // Base64 오디오 데이터를 디코딩하고 AudioPlayer로 재생
  void _playBase64Audio(int currentIndex) async {
    // Base64로 인코딩된 오디오 데이터를 디코딩
    Uint8List audioBytes = base64Decode(widget.correctAudios[currentIndex]);

    // 파일 경로 얻기
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    String filePath = '${appDocDirectory.path}/audio.wav';

    // 파일로 저장
    File audioFile = File(filePath);
    await audioFile.writeAsBytes(audioBytes);

    // 저장된 파일 재생
    await audioPlayer.startPlayer(fromURI: filePath, codec: Codec.pcm16WAV);
  }

  void _onListenPressed(int currentIndex) async {
    _playBase64Audio(currentIndex);
    setState(() {
      _canRecord = true;
    });
  }

  // 오디오 녹음 및 처리
  Future<void> _recordAudio() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();

      setState(() {
        _isLoading = true;
        _isRecorded = true;
      });
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
        });

        final audioFile = File(path);
        final fileBytes = await audioFile.readAsBytes();
        final base64userAudio = base64Encode(fileBytes);
        final currentCardId = widget.ids[_currentIndex];
        final base64correctAudio = widget.correctAudios[_currentIndex];
        //await audioPlayer.play(audioplayers.DeviceFileSource(audioFile.path));
        try {
          // Set a timeout for the getFeedback call
          final feedbackData = await getFeedback(
            currentCardId,
            base64userAudio,
            base64correctAudio,
          ).timeout(
            const Duration(seconds: 7),
            onTimeout: () {
              throw TimeoutException('Feedback request timed out');
            },
          );

          if (mounted && feedbackData != null) {
            setState(() {
              _isLoading = false; // Stop loading
            });
            showFeedbackDialog(context, feedbackData, _recordedFilePath,
                widget.texts[_currentIndex]);
            Future.delayed(const Duration(milliseconds: 300), () {
              debugPrint("Dialog animation finished, calling nextCard...");
              _nextCard();
            });
          } else {
            setState(() {
              _isLoading = false; // Stop loading
            });
            if (!mounted) return; // 위젯이 여전히 존재하는지 확인
            showCommonDialog(context,
                dialogType: DialogType.recordingError); // 녹음 오류 dialog
          }
        } catch (e) {
          setState(() {
            _isLoading = false; // Stop loading
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
      await _recorder.startRecorder(
        toFile: 'audio_record.wav',
        codec: Codec.pcm16WAV,
      );
      setState(() {
        _isRecording = true;
      });
    }
  }

  // 서버로 사용자가 녹음한 오디오 전송
  Future<void> _uploadRecording(String? userAudioPath) async {
    if (userAudioPath != null) {
      String? token = await getAccessToken();
      var url = Uri.parse('$mainUrl/cards/${widget.ids[_currentIndex]}');

      // userAudioPath와 correctAudioPath를 base64로 인코딩
      String userAudioBase64 =
          base64Encode(await File(userAudioPath).readAsBytes());
      String correctAudioBase64 = widget.correctAudios[_currentIndex];

      // JSON Body 생성
      Map<String, String> body = {
        "userAudio": userAudioBase64,
        "correctAudio": correctAudioBase64,
      };

      try {
        // POST 요청
        var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'access': token!,
          },
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          debugPrint('File uploaded successfully');
          debugPrint('Response body: ${response.body}');
          _nextCard();
        } else if (response.statusCode == 401) {
          // Token expired, attempt to refresh the token
          debugPrint('Access token expired. Refreshing token...');

          // Refresh the access token
          bool isRefreshed = await refreshAccessToken();
          if (isRefreshed) {
            // Retry the upload request with the new token
            token = await getAccessToken();
            var retryResponse = await http.post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'access': token!,
              },
              body: jsonEncode(body),
            );
            if (retryResponse.statusCode == 200) {
              debugPrint('File uploaded successfully after token refresh');
              debugPrint('Response body: $response.body');
              _nextCard();
            } else {
              debugPrint(
                  'File upload failed after token refresh with status: ${retryResponse.statusCode}');
              if (!mounted) return; // 위젯이 여전히 존재하는지 확인
              showCommonDialog(context,
                  dialogType: DialogType.recordingError); // 녹음 오류 dialog
            }
          } else {
            debugPrint('Failed to refresh access token');
            if (!mounted) return; // 위젯이 여전히 존재하는지 확인
            showCommonDialog(context,
                dialogType: DialogType.recordingError); // 녹음 오류 dialog
          }
        } else {
          debugPrint('File upload failed with status: ${response.statusCode}');
          if (!mounted) return; // 위젯이 여전히 존재하는지 확인
          showCommonDialog(context,
              dialogType: DialogType.recordingError); // 녹음 오류 dialog
        }
      } catch (e) {
        debugPrint('Error uploading file: $e');
        if (!mounted) return; // 위젯이 여전히 존재하는지 확인
        showCommonDialog(context,
            dialogType: DialogType.recordingError); // 녹음 오류 dialog
      }
    }
  }

  // 이미지 로드
  Future<void> _loadImage() async {
    try {
      setState(() {
        _isImageLoading = true;
      });
      final imageData =
          await fetchImage(widget.pictureUrls[_currentIndex]); // 이미지 데이터 가져오기
      if (mounted) {
        // dispose() 이후 setState 방지
        setState(() {
          _isImageLoading = false;
          _imageData = imageData; // 이미지 데이터 갱신
        });
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
  }

  void _nextCard() {
    debugPrint('Before: currentIndex = $_currentIndex'); // 디버깅용

    if (_isRecorded) {
      if (_currentIndex < widget.ids.length - 1) {
        incrementLearnedCardCount();
        setState(() {
          _currentIndex++;
          _isRecorded = false;
          saveLastFinishedCard(widget.ids[_currentIndex - 1]); // 이전 카드 인덱스 저장
          debugPrint('After: currentIndex = $_currentIndex'); // 디버깅용
        });
      } else {
        debugPrint('Last card reached');
        _showCompletionDialog();
        incrementLearnedCardCount(); // 카드 갯수 + 1
        setTodayCourseCompleted(); // 오늘 학습 완료 저장
      }
    } else {
      debugPrint('Recording not completed!');
      // showErrorDialog();
    }
  }

  // 완료하면 true로 바꾸게 설정
  Future<void> setTodayCourseCompleted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('cardIdList'); // cardList 초기화
    // Set "checkTodayCourse" to true and save today's date
    await prefs.setBool('checkTodayCourse', true);

    // Update "lastSavedDate" to today's date
    DateTime now = DateTime.now();
    // String todayDate = "${now.year}-${now.month}-${now.day}";
    String todayDate = "${now.month}-${now.day}-${now.minute}"; // 임시 분 단위
    await prefs.setString('lastSavedDate', todayDate);
    debugPrint(todayDate);

    debugPrint('checkTodayCourse set to true and lastSavedDate updated.');
  }

  // 피드백 다이얼로그 표시
  // void showFeedbackDialog(BuildContext context, FeedbackData feedbackData) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return FeedbackDialog(
  //           feedbackData: feedbackData,
  //           recordedFilePath: path,
  //           correctText:  widget.texts[_currentIndex]);
  //     }).then((_) {
  //     // 다이얼로그가 닫히면 nextCard 호출

  //     Future.delayed(const Duration(milliseconds: 300), () {
  //       debugPrint("Dialog animation finished, calling nextCard...");
  //       _nextCard();
  //     });
  //   });
  // }

  void _showCompletionDialog() async {
    int responseCode = await sendTestFinalizeRequest();
    // 현재까지 학습한 마지막 카드 ID 저장
    if (widget.ids.isNotEmpty) {
      int lastCardId = widget.ids.last; // 현재까지 학습한 마지막 카드 ID
      await saveLastFinishedCard(lastCardId);
      debugPrint("Saved last finished card ID: $lastCardId");
    }

    String title;
    String content;
    // 테스트했고 틀린 발음 바탕으로 학습 카드에 취약음소 표시
    if (responseCode == 200) {
      updatecardweaksound();
      title = 'Test Completed';
      content = 'You have completed the pronunciation test.';
    }
    // 테스트했는데 100점 맞았을 때
    else if (responseCode == 404) {
      title = 'Perfect Pronunciation';
      content = 'You have no mispronunciations. Well done!';
    } else {
      title = 'Error';
      content = 'An error occurred while finalizing the test.';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SuccessDialog(
          title: title,
          subtitle: content,
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeNav()),
              (route) => false,
            );
          },
        );
      },
    );
  }

  void _showExitDialog() async {
    // 현재까지 학습한 마지막 카드 ID 저장
    if (widget.ids.isNotEmpty) {
      int lastCardId = widget.ids[_currentIndex]; // 현재까지 학습한 마지막 카드 ID
      await saveLastFinishedCard(lastCardId);
      debugPrint("Saved last finished card ID: $lastCardId");
    }

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
    _recorder.closeRecorder();
    audioPlayer.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.70;

    int cardCount = (widget.courseSize - widget.ids.length) + _currentIndex + 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Today\'s Course!',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Container(
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border.all(color: const Color(0xFFF26647), width: 3.w),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0.h, horizontal: 16.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.texts[_currentIndex],
                          style: TextStyle(
                              fontSize: 24.0.sp, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 7.h),
                        Text(
                          '[${widget.cardPronunciations[_currentIndex]}]',
                          style: TextStyle(
                              fontSize: 18.sp, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          widget.cardTranslations[_currentIndex],
                          style: TextStyle(
                              fontSize: 18.0.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 231, 156, 135)),
                          textAlign: TextAlign.center,
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF26647),
                            minimumSize: const Size(220, 40),
                          ),
                          onPressed: () {
                            _onListenPressed(_currentIndex);
                          },
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
                ),
                SizedBox(height: 30.h),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              color: Colors.grey[300],
                            ),
                          ),
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: cardCount / widget.courseSize,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFf26647),
                                        Color(0xFFf2a647)
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        '$cardCount/${widget.courseSize}',
                        style: const TextStyle(
                          color: Color.fromARGB(129, 0, 0, 0),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 80.h,
                ),
                if (_isLoading)
                  Center(
                      child: CircularProgressIndicator(
                    color: primary,
                  )),
              ],
            ),
          ],
        ),
      ),
      // 녹음하기 버튼
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          //onPressed: _isRecording ? _stopRecording : _startRecording,
          onPressed: _canRecord && !_isLoading ? _recordAudio : null,
          backgroundColor:
              _isRecording ? const Color(0xFF976841) : const Color(0xFFF26647),
          elevation: 0.0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(35))),
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
