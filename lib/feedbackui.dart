import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/feedback_data.dart';
import 'package:flutter_application_1/function.dart';
import 'package:flutter_application_1/ttsservice.dart';

class FeedbackUI extends StatefulWidget {
  final FeedbackData feedbackData;
  final String recordedFilePath;

  FeedbackUI({required this.feedbackData, required this.recordedFilePath});

  @override
  State<FeedbackUI> createState() => _FeedbackUIState();
}

class _FeedbackUIState extends State<FeedbackUI> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playUserRecording() async {
    await _audioPlayer.play(DeviceFileSource(widget.recordedFilePath));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Dialog(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topRight,
            children: <Widget>[
              Container(
                width: constraints.maxWidth * 0.8,
                height: constraints.maxHeight * 0.62,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    SizedBox(height: constraints.maxHeight * 0.05),
                    RichText(
                      text: TextSpan(
                        children: buildTextSpans(
                          widget.feedbackData.userAudioText,
                          widget.feedbackData.mistakenIndexes,
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.025),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: widget.feedbackData.userScore / 100.0,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF26647)),
                                minHeight: constraints.maxHeight * 0.016,
                              ),
                            ),
                          ),
                          SizedBox(width: constraints.maxWidth * 0.025),
                          Text(
                            '${widget.feedbackData.userScore.toString()}%',
                            style: TextStyle(
                              fontSize: constraints.maxHeight * 0.02,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF26647),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    SizedBox(
                      height: constraints.maxHeight * 0.06,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: recommendText(
                            widget.feedbackData.recommendCardId,
                            widget.feedbackData.recommendCardText,
                            widget.feedbackData.recommendCardCategory,
                            widget.feedbackData.recommendCardSubcategory,
                            context,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.02),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/image copy.png',
                            //fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            left: constraints.maxWidth * 0.0468,
                            top: constraints.maxHeight * 0.041,
                            child: Image.memory(
                              widget.feedbackData.userWaveformImage,
                              width: constraints.maxWidth * 0.6,
                              height: constraints.maxHeight * 0.14,
                            ),
                          ),
                          Positioned(
                            left: constraints.maxWidth * 0.0468,
                            bottom: constraints.maxHeight * 0.0363,
                            child: Image.memory(
                              widget.feedbackData.correctWaveformImage,
                              width: constraints.maxWidth * 0.6,
                              height: constraints.maxHeight * 0.14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 14,
                bottom: constraints.maxHeight * 0.27,
                child: IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: Color(0xFF644829),
                  ),
                  iconSize: constraints.maxHeight * 0.03,
                  onPressed: _playUserRecording,
                ),
              ),
              Positioned(
                right: 14,
                bottom: constraints.maxHeight * 0.13,
                child: IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: Color(0xFFF26647),
                  ),
                  iconSize: constraints.maxHeight * 0.03,
                  onPressed: () {
                    TtsService.instance
                        .playCachedAudio(widget.feedbackData.cardId);
                  },
                ),
              ),
              Positioned(
                right: 5,
                top: 5,
                child: IconButton(
                  icon: Icon(Icons.close),
                  iconSize: constraints.maxHeight * 0.034,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
