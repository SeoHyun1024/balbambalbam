import 'package:flutter/material.dart';
import 'package:flutter_application_1/new/models/app_colors.dart';
import 'package:flutter_application_1/dismisskeyboard.dart';
import 'package:flutter_application_1/new/models/user_info.dart';
import 'package:flutter_application_1/new/services/api/profile_api.dart';
import 'package:flutter_application_1/signup/textfield_decoration.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 회원정보 수정 페이지
class ProfileUpdatePage extends StatefulWidget {
  const ProfileUpdatePage({
    Key? key,
  }) : super(key: key);

  @override
  ProfileUpdatePageState createState() => ProfileUpdatePageState();
}

class ProfileUpdatePageState extends State<ProfileUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final _fieldKey_1 = GlobalKey<FormFieldState>();
  final _fieldKey_2 = GlobalKey<FormFieldState>();
  final _fieldKey_3 = GlobalKey<FormFieldState>();

  TextEditingController? _nicknameController;
  TextEditingController? _birthYearController;

  int? _selectedGender;
  int? currentbirthyear;

  var isButtonEnabled = List<bool>.filled(3, false);
  var isTapped = List<bool>.filled(3, false);

  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _buttonKey = GlobalKey();
  double _buttonTop = 0.0; // 버튼의 y 위치 저장

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatButtonPosition();
    });

    initUserData(); // 초기화
  }

  /// 유저 정보 초기화
  Future<void> initUserData() async {
    // 유저 정보 불러옴
    await UserInfo().loadUserInfo();

    setState(() {
      currentbirthyear = DateTime.now().year - UserInfo().age + 1;
      _nicknameController = TextEditingController(text: UserInfo().name);
      _birthYearController =
          TextEditingController(text: currentbirthyear.toString());
      _selectedGender = UserInfo().gender;
    });
  }

  /// 버튼 위치 계산
  void _calculatButtonPosition() {
    final RenderBox renderBoxContainer =
        _containerKey.currentContext?.findRenderObject() as RenderBox;
    final RenderBox renderBoxButton =
        _buttonKey.currentContext?.findRenderObject() as RenderBox;
    setState(() {
      _buttonTop = renderBoxContainer.size.height -
          renderBoxButton.size.height / 2; // 컨테이너 아래 10px 여백
    });
  }

  /// 사용자 정보 업데이트
  Future<void> _updateProfile() async {
    // 유효성 검사 성공 후 사용자 정보 업데이트
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _saveUserInfo();

    // 유저 정보 업데이트 api 요청
    // ignore: use_build_context_synchronously
    await updateUserDataRequest(context);
  }

  /// 사용자 정보 저장
  Future<void> _saveUserInfo() async {
    await UserInfo().saveUserInfo(
      name: _nicknameController!.text,
      age: DateTime.now().year - int.parse(_birthYearController!.text) + 1,
      gender: _selectedGender!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(
            'Edit Profile',
            style: TextStyle(
              color: bam,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: background,
        ),
        backgroundColor: primary,
        body: Form(
          key: _formKey,
          child: Stack(
            children: [
              Container(
                key: _containerKey,
                height: 600.h,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: const BorderRadiusDirectional.only(
                    bottomStart: Radius.circular(40),
                    bottomEnd: Radius.circular(40),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(30.0.h),
                child: Column(
                  children: [
                    SizedBox(height: 30.0.h),
                    Text(
                      'You can edit your Profile!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primary,
                        fontSize: 18.0.sp,
                      ),
                    ),
                    SizedBox(height: 80.0.h),
                    Wrap(
                      runSpacing: 25.0.h, // 각 항목 사이 간격
                      children: [
                        TextFormField(
                          controller: _birthYearController,
                          key: _fieldKey_1,
                          decoration: textfieldDecoration(
                              isTapped[0], isButtonEnabled[0], 'Birth Year'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            isTapped[0] = true;
                            setState(() {
                              if (_fieldKey_1.currentState != null) {
                                _fieldKey_1.currentState!.validate()
                                    ? isButtonEnabled[0] = true
                                    : isButtonEnabled[0] = false;
                              }
                            });
                          },
                          validator: (value) {
                            int? year = int.tryParse(value!);
                            debugPrint("$year");
                            if (year == null) {
                              return 'Please enter a valid year.';
                            } else if (year < 1924 ||
                                year > DateTime.now().year) {
                              return 'Please enter your birth year.';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<int>(
                          value: _selectedGender,
                          key: _fieldKey_2,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color.fromARGB(255, 195, 185, 182),
                          ),
                          dropdownColor:
                              const Color.fromARGB(255, 223, 234, 251),
                          style: TextStyle(
                            color: bam,
                            fontSize: 20.sp,
                          ),
                          elevation: 16,
                          items: <int>[0, 1].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value == 0 ? 'Male' : 'Female'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          decoration: textfieldDecoration(
                              isTapped[1], isButtonEnabled[1], 'Gender'),
                        ),
                        TextFormField(
                          controller: _nicknameController,
                          key: _fieldKey_3,
                          decoration: textfieldDecoration(
                              isTapped[2], isButtonEnabled[2], 'Nickname'),
                          onChanged: (value) {
                            isTapped[2] = true;
                            setState(() {
                              if (_fieldKey_3.currentState != null) {
                                _fieldKey_3.currentState!.validate()
                                    ? isButtonEnabled[2] = true
                                    : isButtonEnabled[2] = false;
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your nickname.';
                            } else if (value.length < 3) {
                              return 'Nickname must be at least 3 characters.';
                            } else if (value.length > 8) {
                              return 'Nickname must be at most 8 characters.';
                            } else if (value.contains(' ')) {
                              return 'Nickname cannot contain spaces.';
                            }
                            return null;
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Positioned(
                top: _buttonTop,
                right: 40,
                left: 40,
                child: Center(
                  child: ElevatedButton(
                    key: _buttonKey,
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 232, 120, 71),
                      elevation: 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Edit Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25.sp,
                          color: Colors.white,
                          height: 2.6.h,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
