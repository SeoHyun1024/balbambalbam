import 'package:flutter/material.dart';
import 'package:flutter_application_1/new/functions/show_common_dialog.dart';
import 'package:flutter_application_1/new/models/app_colors.dart';
import 'package:flutter_application_1/dismisskeyboard.dart';
import 'package:flutter_application_1/home/custom/customlearningcard.dart';
import 'package:flutter_application_1/new/services/api/custom_card_api.dart';
import 'package:flutter_application_1/new/services/api/custom_cards_list_api.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSentenceScreen extends StatefulWidget {
  const CustomSentenceScreen({super.key});

  @override
  CustomSentenceScreenState createState() => CustomSentenceScreenState();
}

class Sentence {
  final int id;
  final String text;
  final String engTranslation;
  final String engPronunciation;
  final bool bookmark;
  String? createdAt;

  Sentence({
    required this.id,
    required this.text,
    required this.engTranslation,
    required this.engPronunciation,
    required this.bookmark,
    required this.createdAt,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'],
      text: json['text'],
      engTranslation: json['engTranslation'],
      engPronunciation: json['engPronunciation'],
      bookmark: json['bookmark'] ?? false,
      createdAt: json['createdAt'] ?? DateTime(2024, 10, 10).toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'engTranslation': engTranslation,
        'engPronunciation': engPronunciation,
        'bookmark': bookmark,
        'createdAt': createdAt,
      };
}

class CustomSentenceScreenState extends State<CustomSentenceScreen> {
  List<Sentence> _sentences = [];
  List<int> idList = [];
  List<String> textList = [];
  List<String> engTranslationList = [];
  List<String> engPronunciationList = [];
  List<int> cardScoreList = [];
  List<bool> weakCardList = [];
  List<bool> bookmarkList = [];
  List<String> createdAtList = [];

  final TextEditingController _controller = TextEditingController();
  final int _maxSentences = 10;
  final int _maxChars = 50;

  late Color addButtonIconColor = const Color(0xFF71706B); // + 버튼 아이콘 색
  late Color addButtonColor = Colors.transparent; // + 버튼 배경 색

  bool isLoading = false;
  bool isAddLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSentencesFromServer();
    _controller.addListener(_updateSuffixIconColor);
  }

  void _updateSuffixIconColor() {
    setState(() {
      // 텍스트가 입력된 경우 파란색, 없을 때 회색으로 설정
      addButtonIconColor = _controller.text.isNotEmpty
          ? const Color.fromARGB(255, 245, 245, 245)
          : const Color(0xFF71706B);
      addButtonColor = _controller.text.isNotEmpty
          ? const Color(0xFFF26647)
          : Colors.transparent;
    });
  }

  Future<void> _loadSentencesFromServer() async {
    setState(() {
      isLoading = true;
    });
    final List<dynamic> responseData = await getCustomCardsListRequest();

    if (mounted) {
      setState(() {
        _sentences.addAll(
          responseData.map((data) => Sentence.fromJson(data)).toList(),
        );

        // 리스트 초기화
        idList.clear();
        textList.clear();
        engTranslationList.clear();
        engPronunciationList.clear();
        cardScoreList.clear();
        weakCardList.clear();
        bookmarkList.clear();
        createdAtList.clear();
        // 변수 리스트에 데이터 저장
        for (var card in responseData) {
          idList.add(card['id']);
          textList.add(card['text']);
          engTranslationList.add(card['engTranslation']);
          engPronunciationList.add(card['engPronunciation']);
          cardScoreList.add(card['cardScore']);
          weakCardList.add(card['weakCard']);
          bookmarkList.add(card['bookmark']);
          createdAtList.add(card['createdAt'] ??
              DateTime(2024, 10, 10).toIso8601String()); // 기본값 추가
        }
        // 리스트 뒤집기
        _sentences = _sentences.reversed.toList();
        idList = idList.reversed.toList();
        textList = textList.reversed.toList();
        engTranslationList = engTranslationList.reversed.toList();
        engPronunciationList = engPronunciationList.reversed.toList();
        cardScoreList = cardScoreList.reversed.toList();
        weakCardList = weakCardList.reversed.toList();
        bookmarkList = bookmarkList.reversed.toList();
        createdAtList = createdAtList.reversed.toList();

        isLoading = false;
      });
    }
  }

  /// 문장 추가 함수
  Future<void> _addSentence() async {
    final text = _controller.text;

    setState(() {
      isAddLoading = true;
    });

    if (text.isNotEmpty &&
        _sentences.length < _maxSentences &&
        text.length <= _maxChars) {
      await createCustomCardRequest(text, onDataReceived: (data) {
        final newSentence = Sentence.fromJson(data);
        setState(() {
          // 리스트에 맨 앞에 추가
          _sentences.insert(0, newSentence);
          idList.insert(0, newSentence.id);
          textList.insert(0, newSentence.text);
          engPronunciationList.insert(0, newSentence.engPronunciation);
          engTranslationList.insert(0, newSentence.engTranslation);
          createdAtList.insert(0, newSentence.createdAt!);
          bookmarkList.insert(0, false);

          _controller.clear();
          isAddLoading = false;
        });
      });
    } else {
      _showErrorDialog('Please enter a sentence with 50 characters or less.');
    }
  }

  /// 문장 삭제 함수
  Future<void> _deleteSentence(int index) async {
    final sentence = _sentences[index];
    setState(() {
      isAddLoading = true;
    });
    await deleteCustomCardRequest(sentence.id, onDataReceived: () {
      setState(() {
        _sentences.removeAt(index);
        isAddLoading = false;
      });
    });
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showCommonDialog(
        context,
        dialogType: DialogType.recordingError,
        customTitle: "Input Error",
        customContent: message,
      );
      setState(() {
        isAddLoading = false;
      });
    }
  }

  bool isToday(String createdAt) {
    // 현재 날짜 가져오기
    DateTime now = DateTime.now();

    // 서버 시간에 대한 보정 (예: 서버가 UTC+0이고 로컬이 UTC+9라면 +9 추가)
    DateTime serverTime =
        DateTime.parse(createdAt).add(const Duration(hours: 0));

    // 년, 월, 일이 동일한지 비교
    return serverTime.year == now.year &&
        serverTime.month == now.month &&
        serverTime.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.icon_001,
            onPressed: () {
              final int cnt = _sentences.length;
              Navigator.pop(context, cnt);
            },
          ),
          title: const Text(
            'Custom Sentences',
            style: TextStyle(
              color: AppColors.brown_000,
              fontWeight: FontWeight.w600,
              fontSize: 22,
            ),
          ),
          centerTitle: false,
          titleSpacing: 0,
          backgroundColor: const Color(0xFFF5F5F5),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // 화면을 탭했을 때 키보드 내리기
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  style: const TextStyle(
                    color: Color(0xFFF26647),
                  ),
                  cursorColor: const Color(0xFFF26647),
                  decoration: InputDecoration(
                    labelText: 'Please enter a sentence',
                    labelStyle: const TextStyle(
                      color: Color(0xFF71706b),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    floatingLabelStyle: const TextStyle(
                      color: Color.fromARGB(255, 181, 181, 181),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0.r),
                      borderSide: const BorderSide(
                        color: Color(0xFFBEBDB8),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0.r),
                      borderSide: const BorderSide(
                        color: Color(0xFFF26647),
                        width: 1.5,
                      ),
                    ),
                    suffix: Container(
                      height: 30.h,
                      width: 30.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100.r),
                        color: addButtonColor,
                      ),
                      child: IconButton(
                        padding: const EdgeInsets.all(0),
                        color: addButtonIconColor,
                        icon: const Icon(
                          Icons.add,
                          size: 19,
                        ),
                        onPressed: _sentences.length < _maxSentences
                            ? _addSentence
                            : null,
                      ),
                    ),
                  ),
                  onSubmitted: (text) => _addSentence(),
                  enabled: _sentences.length < _maxSentences,
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFF26647)),
                        ))
                      : _sentences.isEmpty
                          ? Center(
                              child: isAddLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFF26647)),
                                    ))
                                  : Container(
                                      width: 356,
                                      height: 197,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        border: Border.all(
                                            color: const Color(0xFFEBEBEB)),
                                      ),
                                      child: const Text(
                                        'Got a sentence you\'d like to practice pronouncing? Just write it in English, we’ll translate it into Korean and save it as a card!',
                                        style: TextStyle(
                                          color: Color(0xFF7F7E79),
                                        ),
                                      ),
                                    ),
                            )
                          : Stack(
                              children: [
                                ListView.builder(
                                  reverse: false,
                                  itemCount: _sentences.length,
                                  itemBuilder: (context, index) {
                                    isToday(_sentences[index].createdAt!);
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10.0.h),
                                      child: Bounce(
                                        duration:
                                            const Duration(milliseconds: 100),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CustomSentenceLearningCard(
                                                currentIndex: index,
                                                cardIds: idList,
                                                texts: textList,
                                                pronunciations:
                                                    engTranslationList,
                                                engpronunciations:
                                                    engPronunciationList,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEBEBEB),
                                            borderRadius:
                                                BorderRadius.circular(8.r),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.17),
                                                blurRadius: 5,
                                                offset: const Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    vertical: 10.0.h,
                                                    horizontal: 10.0.w),
                                            title: Row(
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      right: 10.w),
                                                  width: 8.w,
                                                  height: 8.h,
                                                  decoration: BoxDecoration(
                                                    color: (isToday(
                                                            _sentences[index]
                                                                .createdAt!))
                                                        ? AppColors
                                                            .cardProgressBar_000
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.r),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _sentences[index]
                                                            .engTranslation,
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 15.h,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        softWrap: true,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                      Text(
                                                        _sentences[index].text,
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontSize: 15.h,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        softWrap: true,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.black38,
                                                    ),
                                                    onPressed: () {
                                                      _deleteSentence(index);
                                                      setState(() {
                                                        idList.removeAt(index);
                                                        textList
                                                            .removeAt(index);
                                                        engTranslationList
                                                            .removeAt(index);
                                                        engPronunciationList
                                                            .removeAt(index);
                                                        bookmarkList
                                                            .removeAt(index);
                                                      });
                                                    }),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (isAddLoading)
                                  const Center(
                                      child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFF26647)),
                                  )),
                              ],
                            ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
