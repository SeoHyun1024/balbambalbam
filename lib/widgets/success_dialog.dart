import 'package:flutter/material.dart';
import 'package:flutter_application_1/bottomnavigationbartest.dart';
import 'package:flutter_application_1/colors.dart';
import 'package:flutter_application_1/new_home/home_nav.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SuccessDialog extends StatelessWidget {
  SuccessDialog({
    super.key,
    required this.subtitle,
    required this.onTap,
  });

  String subtitle;
  VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 26,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 333.w,
        height: 230.h,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Text(
                'Success!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10.0),
              child: Text(
                'You did a great job in the test!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 150, 150, 150),
                ),
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Container(
                width: 148.w,
                height: 44.h,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                    child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
