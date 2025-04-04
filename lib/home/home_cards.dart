// ignore_for_file: use_build_context_synchronously

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/new/models/app_colors.dart';
import 'package:flutter_application_1/icons/custom_icons.dart';
import 'package:flutter_application_1/home/custom/customsentence_screen.dart';
import 'package:flutter_application_1/home/today_learning_card.dart';
import 'package:flutter_application_1/home/missed_cards_screen.dart';
import 'package:flutter_application_1/home/saved_cards_screen.dart';
import 'package:flutter_application_1/learning_coures/learning_course_screen.dart';
import 'package:flutter_application_1/new/services/api/attendance_api.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CustomHomeCard extends StatelessWidget {
  CustomHomeCard({
    super.key,
    required this.contents,
    required this.boxColor,
  });

  final Widget contents;
  Color boxColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.17),
            offset: const Offset(2, 2),
            blurRadius: 5,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.0.w, vertical: 15.0.h),
        child: contents,
      ),
    );
  }
}

class ContentTodayGoal extends StatefulWidget {
  ContentTodayGoal({
    super.key,
    required this.weeklyAttendance,
  });

  List<String> weeklyAttendance;

  @override
  State<ContentTodayGoal> createState() => _ContentTodayGoalState();
}

class _ContentTodayGoalState extends State<ContentTodayGoal> {
  Map<DateTime, List<int>> _attendanceDates = {};
  bool isLoading = true;
  // 드롭다운 목록에 사용할 데이터 리스트
  final List<String> _items = ['10', '15', '30'];

  int totalCard = 10; // 선택된 카드 수를 저장할 변수  // 학습한 카드 갯수 변수
  int learnedCardCount = 0;

  bool checkTodayCourse = false;

  @override
  void initState() {
    super.initState();
    _loadTotalCard();
    loadLearnedCardCount();
    _loadcheckTodayCourse();
  }

  // 학습한 카드 갯수 불러오기
  Future<void> loadLearnedCardCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      learnedCardCount = prefs.getInt('learnedCardCount') ?? 0;
    });
  }

  // 앱 시작 시 secure storage에서 totalCard 값을 불러오는 함수
  Future<void> _loadTotalCard() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      totalCard = prefs.getInt('totalCard') ?? 10;
    });
  }

  Future<void> _loadcheckTodayCourse() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      checkTodayCourse = prefs.getBool('checkTodayCourse') ?? false;
    });
  }

  // 선택된 카드 수를 secure storage에 저장하는 함수
  Future<void> _saveTotalCard(int value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalCard', value); // totalCard 저장
  }

  /// 출석 정보 가져오는 함수
  Future<void> fetchAttendanceData() async {
    await getUserAttendanceRequest(onDataReceived: (data) {
      final attendanceByMonth =
          data["attendanceByMonth"] as Map<String, dynamic>;

      Map<DateTime, List<int>> attendanceDates = {};

      attendanceByMonth.forEach((month, days) {
        DateTime monthDate = DateTime.parse("$month-01");
        attendanceDates[monthDate] = List<int>.from(days);
      });
      if (mounted) {
        setState(() {
          _attendanceDates = attendanceDates;
          isLoading = false; // 로딩 중 상태 변환
        });
      }
    });
  }

  bool _isAttendanceDay(DateTime day) {
    final monthDate = DateTime(day.year, day.month, 1);
    final days = _attendanceDates[monthDate] ?? [];

    return days.contains(day.day);
  }

  @override
  Widget build(BuildContext context) {
    List days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Goal",
          style: TextStyle(
            fontSize: 12.h,
          ),
        ),
        Container(
          height: 5.h,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 246.w,
              height: 13.h,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 235, 235, 235),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Container(
                height: 13.h,
                width: checkTodayCourse
                    ? 246.w
                    : learnedCardCount / totalCard * 246.w,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: checkTodayCourse
                      ? BorderRadius.all(Radius.circular(20.r))
                      : BorderRadius.only(
                          topLeft: Radius.circular(20.r),
                          bottomLeft: Radius.circular(20.r),
                        ),
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 60.w),
              child: DropdownButton2<String>(
                isExpanded: true,
                items: _items
                    .map((String item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item, // 메뉴 아이템은 숫자만 표시
                            style: TextStyle(
                              fontSize: 14.w,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ))
                    .toList(),
                value: totalCard.toString(),
                onChanged:
                    !checkTodayCourse // checkTodayCourse가 false면 null을 전달하여 비활성화
                        ? null
                        : (String? value) {
                            if (value != null) {
                              setState(() {
                                totalCard = int.parse(value);
                                _saveTotalCard(int.parse(value));
                                debugPrint("새로 설정된 totalCard 입니다 : $totalCard");
                              });
                            }
                          },

                buttonStyleData: ButtonStyleData(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 1.0.h,
                      ),
                    ),
                  ),
                ),
                // 방법 1: 기본 밑줄 제거
                underline: const SizedBox.shrink(),
                dropdownStyleData: DropdownStyleData(
                  width: 54.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: Colors.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color.fromARGB(255, 157, 169, 204)
                            .withValues(alpha: 0.1),
                        blurRadius: 10.0,
                        spreadRadius: 5.0,
                        offset: const Offset(0.0, 2.0),
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                  elevation: 4,
                ),

                // 선택된 아이템은 카운트 형식으로 표시
                customButton: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        "$learnedCardCount/$totalCard",
                        style: TextStyle(
                          fontSize: 11.w,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (checkTodayCourse)
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 24.w,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14.0),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB(255, 213, 213, 213),
          ),
        ),
        GestureDetector(
          onTap: () async {
            // fetchAttendanceData 가 끝난 뒤에 Dialog 호출
            await fetchAttendanceData();
            showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      height: 434.h,
                      width: 353.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.0.w, vertical: 10.0.h),
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ))
                            : TableCalendar(
                                focusedDay: DateTime.now(),
                                firstDay: DateTime(2024),
                                lastDay: DateTime(2028),
                                headerVisible: true,
                                daysOfWeekStyle: DaysOfWeekStyle(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.primary,
                                        width: 2.w,
                                      ),
                                    ),
                                  ),
                                  dowTextFormatter: (date, locale) {
                                    String dowText = DateFormat("EEE")
                                        .format(date)
                                        .toUpperCase();
                                    return dowText;
                                  },
                                  weekdayStyle: TextStyle(
                                    color: const Color(0xFF666560),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.h,
                                  ),
                                  weekendStyle: TextStyle(
                                    color: const Color(0xFF666560),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.h,
                                  ),
                                ),
                                daysOfWeekHeight: 40,
                                headerStyle: HeaderStyle(
                                  headerMargin: const EdgeInsets.all(0),
                                  headerPadding: const EdgeInsets.all(0),
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextFormatter: (date, locale) {
                                    String title =
                                        DateFormat("MMM, yyyy").format(date);
                                    return title;
                                  },
                                  titleTextStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.h,
                                    fontFamily: "Pretendard",
                                    fontWeight: FontWeight.w600,
                                  ),
                                  leftChevronIcon: Icon(
                                    Icons.arrow_left,
                                    color: Colors.black,
                                    size: 30.h,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.arrow_right,
                                    color: Colors.black,
                                    size: 30.h,
                                  ),
                                ),
                                calendarBuilders: CalendarBuilders(
                                  //디폴트 값 셀 빌더
                                  defaultBuilder: (context, day, focusedDay) {
                                    return _isAttendanceDay(day)
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 30.h,
                                                width: 30.h,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  day.day.toString(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.h,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 30.h,
                                                width: 30.w,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  day.day.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                  },
                                  todayBuilder: (context, day, focusedDay) {
                                    return _isAttendanceDay(day)
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 30.h,
                                                width: 30.h,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFFFDBB5),
                                                      width: 3.w),
                                                ),
                                                child: Text(
                                                  day.day.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 30.h,
                                                width: 30.w,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFFFDBB5),
                                                      width: 3.w),
                                                ),
                                                child: Text(
                                                  day.day.toString(),
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14.h,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                  },
                                  outsideBuilder: (context, day, focusedDay) {
                                    return _isAttendanceDay(day)
                                        ? Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 30.h,
                                                width: 30.w,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  day.day.toString(),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14.h,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                height: 30.h,
                                                width: 30.w,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Text(
                                                  day.day.toString(),
                                                  style: TextStyle(
                                                    color:
                                                        const Color(0xFFC0C0C0),
                                                    fontSize: 14.h,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                  },
                                ),
                              ),
                      ),
                    ),
                  );
                });
          },
          child: Center(
            child: Wrap(
              spacing: 11.0.w,
              children: List.generate(7, (index) {
                return widget.weeklyAttendance[index] == "F" // 출석 안했으면
                    ? NoStamp(
                        days: days,
                        index: index,
                      ) // 스탬프 없음
                    : Stamp(
                        // 출석하면 스탬프
                        days: days,
                        index: index,
                      );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// 스탬프 없는 위젯
class NoStamp extends StatelessWidget {
  NoStamp({
    super.key,
    required this.days,
    required this.index,
  });

  final List days;
  int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: 32.h,
      width: 32.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color.fromARGB(255, 213, 213, 213),
          width: 3.w,
        ),
      ),
      child: Text(
        days[index],
        style: const TextStyle(
          color: Color.fromARGB(255, 213, 213, 213),
        ),
      ),
    );
  }
}

// 스탬프 찍힌 위젯
// ignore: must_be_immutable
class Stamp extends StatelessWidget {
  Stamp({
    super.key,
    required this.days,
    required this.index,
  });

  final List days;
  int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: 32.h,
      width: 32.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.primary,
          width: 3.w,
        ),
      ),
      child: Text(
        days[index],
        style: const TextStyle(color: AppColors.primary),
      ),
    );
  }
}

class ContentTodayCard extends StatelessWidget {
  ContentTodayCard({
    super.key,
    required this.dailyWordId,
    required this.dailyWord,
    required this.dailyWordPronunciation,
  });

  int? dailyWordId;
  String? dailyWord;
  String? dailyWordPronunciation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Card",
              style: TextStyle(
                fontSize: 12.h,
              ),
            ),
            Text(
              dailyWord!,
              style: TextStyle(
                fontSize: 30.h,
                height: 1.16,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 200.w,
                  child: Text(
                    "[$dailyWordPronunciation]",
                    style: TextStyle(
                      fontSize: 18.h,
                    ),
                    softWrap: true,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => TodayLearningCard(
                          cardId: dailyWordId!,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.0.w, vertical: 8.0.h),
                      child: const Text(
                        'Try it →',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ContentCustomCard extends StatelessWidget {
  const ContentCustomCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Say your own\nCustom sentence!",
              style: TextStyle(
                fontSize: 20.h,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const CustomSentenceScreen(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.0.w, vertical: 8.0.h),
                      child: const Text(
                        'Try it →',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ContentLearningCourseCard extends StatelessWidget {
  const ContentLearningCourseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Let's go to study!",
              style: TextStyle(
                fontSize: 21.h,
              ),
            ),
            Text(
              'Learning Course',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18.h,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const LearningCourseScreen(),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.0.w, vertical: 8.0.h),
                      child: const Text(
                        'Try it →',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class ContentTodayMenu extends StatefulWidget {
  ContentTodayMenu({
    super.key,
    required this.level,
    required this.savedCardNumber,
    required this.missedCardNumber,
    required this.customCardNumber,
  });

  int level;
  int savedCardNumber;
  int missedCardNumber;
  int customCardNumber;

  @override
  State<ContentTodayMenu> createState() => _ContentTodayMenuState();
}

class _ContentTodayMenuState extends State<ContentTodayMenu> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Menu",
          style: TextStyle(
            fontSize: 16.h,
          ),
        ),
        MenuItem(
          title: 'Learning Course',
          icon: CustomIcons.learningCourseIcon,
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const LearningCourseScreen(
                    //level: widget.level,
                    ),
              ),
            );
          },
          count: 0,
          showCount: false,
        ),
        MenuItem(
          title: 'Saved Cards',
          icon: CustomIcons.bookmarkIcon,
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const SavedCardScreen(),
              ),
            );
          },
          count: widget.savedCardNumber,
          showCount: true,
        ),
        MenuItem(
          title: 'Missed Cards',
          icon: CustomIcons.missedIcon,
          onTap: () {
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const MissedCardsScreen(),
              ),
            );
          },
          count: widget.missedCardNumber,
          showCount: true,
        ),
        MenuItem(
          title: 'Custom Sentence',
          icon: CustomIcons.customIcon,
          onTap: () async {
            Navigator.push<int>(
              context,
              MaterialPageRoute<int>(
                builder: (BuildContext context) => const CustomSentenceScreen(),
              ),
            ).then((cnt) {
              if (cnt != null) {
                // 반환된 cnt를 이용해 데이터 갱신 작업 수행
                setState(() {
                  widget.customCardNumber = cnt;
                });
              }
            });
          },
          count: widget.customCardNumber,
          showCount: true,
        ),
      ],
    );
  }
}

// Menu 에 목록들
class MenuItem extends StatelessWidget {
  MenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.count,
    required this.showCount,
  });

  String title;
  IconData icon;
  VoidCallback onTap;
  int count;
  bool showCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(
              height: 1.h,
              thickness: 1.w,
              color: const Color.fromARGB(255, 213, 213, 213),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    color: AppColors.icon_001,
                    size: 20.sp,
                  ),
                  Container(
                    width: 8.w,
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.h,
                    ),
                  ),
                ],
              ),
              // 카드 갯수 표시 & 화살표 아이콘
              Row(
                children: [
                  showCount
                      ? Container(
                          width: 26.w,
                          height: 26.h,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.orange_003,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            "$count",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 160, 87, 50),
                              fontSize: 16.h,
                            ),
                          ),
                        )
                      : Container(),
                  Container(
                    width: 15.w,
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.icon_001,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
