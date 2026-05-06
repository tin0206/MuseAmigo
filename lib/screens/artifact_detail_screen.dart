import 'package:flutter/material.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:museamigo/services/audio_assets.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/theme_notifier.dart';
// import 'package:flutter_3d_controller/flutter_3d_controller.dart'; // Temporarily commented

class ArtifactDetailScreen extends StatefulWidget {
  const ArtifactDetailScreen({
    super.key,
    required this.title,
    required this.location,
    required this.year,
    required this.currentLocation,
    required this.height,
    required this.weight,
    required this.imageAsset,
    // this.modelAsset = '', // Optional 3D model - Temporarily commented
    required this.audioAsset,
  });

  final String title;
  final String location;
  final String year;
  final String currentLocation;
  final String height;
  final String weight;
  final String imageAsset;
  final String audioAsset;
  // final String modelAsset; // Temporarily commented

  @override
  State<ArtifactDetailScreen> createState() => _ArtifactDetailScreenState();
}

class _ArtifactDetailScreenState extends State<ArtifactDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, _) {
        return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 370,
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      child: Image.asset(
                        widget.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey.shade300,
                          child: Icon(Icons.image, size: 56),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: themeNotifier.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 18,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: themeNotifier.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Navigate'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Old Audio Player Section removed
              SizedBox(height: 14),
              // 3D Model View Section - Temporarily commented out
              /*
              if (modelAsset.isNotEmpty)
                Container(
                  height: 300,
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              '3D Model View'.tr,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: themeNotifier.textPrimaryColor,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                // Toggle 3D view controls
                              },
                              icon: Icon(Icons.view_in_ar),
                              color: themeNotifier.textPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Flutter3DViewer(
                          src: modelAsset.isNotEmpty ? 'assets/models/$modelAsset' : null,
                          controller: Flutter3DController(),
                        ),
                      ),
                    ],
                  ),
                ),
              */
              SizedBox(height: 14),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  padding: EdgeInsets.fromLTRB(14, 14, 14, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InlineAudioPlayer(
                        audioAsset: widget.audioAsset,
                        title: widget.title.tr,
                      ),
                      SizedBox(height: 12),
                      _infoRow('Title:'.tr, widget.title.tr),
                      _infoRow('Year:'.tr, widget.year.tr),
                      _infoRow('Current Location:'.tr, widget.currentLocation.tr),
                      _infoRow('Height:'.tr, widget.height.tr),
                      _infoRow('Weight:'.tr, widget.weight.tr),
                      SizedBox(height: 18),
                      Text(
                        'Detailed Description'.tr,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "T-54B tank No. 843 is a legendary Vietnam People's Army tank that famously breached the Independence Palace gate in Saigon on April 30, 1975, marking the end of the Vietnam War. Led by Captain Bui Quang Than, this Soviet-made tank is celebrated as a National Treasure and symbolizes Vietnam's liberation and reunification."
                            .tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2E2E2E),
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Enhanced Part'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'The First That Was not First'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'While tank 843 is often pictured alongside tank 390, there is a lingering historical race. Tank 843, commanded by Bui Quang Than, reached the Palace gates first. However, after becoming momentarily wedged in the smaller side gate, tank 390 crashed through the main central gate.'
                            .tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2E2E2E),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: themeNotifier.textPrimaryColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: themeNotifier.textPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class InlineAudioPlayer extends StatefulWidget {
  final String audioAsset;
  final String title;

  const InlineAudioPlayer({super.key, required this.audioAsset, required this.title});

  @override
  State<InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<InlineAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    final source = widget.audioAsset.isEmpty || widget.audioAsset == AudioAssets.standardPath 
        ? AudioAssets.getLocalizedSource() 
        : AudioAssets.sourceFor(widget.audioAsset);
    
    _audioPlayer.setSource(source).then((_) {
      _audioPlayer.getDuration().then((d) {
        if (d != null && mounted) setState(() => _duration = d);
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
            _isPlaying = false;
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: themeNotifier.textPrimaryColor,
                ),
              ),
            ),
            GestureDetector(
              onTap: _toggleAudio,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: themeNotifier.surfaceColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: const Color(0xFFB5B5B5),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          ),
          child: Slider(
            min: 0.0,
            max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
            value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
            onChanged: (value) {
              final newPosition = Duration(milliseconds: value.toInt());
              _audioPlayer.seek(newPosition);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(color: themeNotifier.textSecondaryColor, fontSize: 11),
              ),
              const Spacer(),
              Text(
                _formatDuration(_duration),
                style: TextStyle(color: themeNotifier.textSecondaryColor, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
