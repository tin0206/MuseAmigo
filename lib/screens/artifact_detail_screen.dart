import 'package:flutter/material.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:museamigo/services/audio_assets.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:museamigo/models/artifact.dart';
import 'package:museamigo/repositories/artifact_repository.dart';
// import 'package:flutter_3d_controller/flutter_3d_controller.dart'; // Temporarily commented

/// Displays full details for a single museum artifact.
///
/// Accepts **only** an [artifactCode] and fetches all data from the backend.
/// No content is hardcoded — images are resolved via [Artifact.imagePath].
class ArtifactDetailScreen extends StatefulWidget {
  const ArtifactDetailScreen({
    super.key,
    required this.artifactCode,
  });

  /// The unique code identifying the artifact (e.g. "IP-001").
  final String artifactCode;

  @override
  State<ArtifactDetailScreen> createState() => _ArtifactDetailScreenState();
}

class _ArtifactDetailScreenState extends State<ArtifactDetailScreen> {
  Artifact? _artifact;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArtifact();
  }

  Future<void> _loadArtifact() async {
    try {
      final artifact =
          await ArtifactRepository.instance.fetchByCode(widget.artifactCode);
      if (mounted) {
        setState(() {
          _artifact = artifact;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: themeNotifier.surfaceColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading artifact...'.tr,
                    style: TextStyle(
                      color: themeNotifier.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (_errorMessage != null || _artifact == null) {
          return Scaffold(
            backgroundColor: themeNotifier.surfaceColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 56,
                        color: themeNotifier.textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load artifact'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Unknown error'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: themeNotifier.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: themeNotifier.borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Go Back'.tr,
                              style: TextStyle(
                                color: themeNotifier.textPrimaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _loadArtifact();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: themeNotifier.surfaceColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('Retry'.tr),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return _buildContent(context, _artifact!);
      },
    );
  }

  Widget _buildContent(BuildContext context, Artifact artifact) {
    // Resolve current language once per build for all localized fields.
    final lang = languageNotifier.currentLanguage;
    return Scaffold(
      backgroundColor: themeNotifier.surfaceColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero image ──────────────────────────────────────────────
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 370,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      child: Image.asset(
                        artifact.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: themeNotifier.isDarkMode
                              ? const Color(0xFF27272A)
                              : Colors.grey.shade300,
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 56,
                              color: themeNotifier.textSecondaryColor,
                            ),
                          ),
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
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 14),
              // 3D Model View Section - Temporarily commented out
              /*
              if (artifact.is3dAvailable && artifact.unityPrefabName.isNotEmpty)
                Container(
                  height: 300,
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: themeNotifier.isDarkMode
                        ? const Color(0xFF27272A)
                        : const Color(0xFFF3F3F3),
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
                              onPressed: () {},
                              icon: Icon(Icons.view_in_ar),
                              color: themeNotifier.textPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Flutter3DViewer(
                          src: 'assets/models/${artifact.unityPrefabName}',
                          controller: Flutter3DController(),
                        ),
                      ),
                    ],
                  ),
                ),
              */
              const SizedBox(height: 14),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  decoration: BoxDecoration(
                    color: themeNotifier.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Audio player ─────────────────────────────────────
                      InlineAudioPlayer(
                        audioAsset: artifact.audioAsset,
                        title: artifact.localizedTitle(lang),
                      ),
                      const SizedBox(height: 12),
                      // ── Info rows from database ──────────────────────────
                      _infoRow('Title:'.tr, artifact.localizedTitle(lang)),
                      _infoRow('Artifact Code:'.tr, artifact.artifactCode),
                      _infoRow('Year:'.tr, artifact.year),
                      _infoRow(
                        'Exhibition Location:'.tr,
                        artifact.localizedLocation(lang),
                      ),
                      _infoRow(
                        'Category:'.tr,
                        artifact.localizedCategory(lang),
                      ),
                      const SizedBox(height: 18),
                      // ── Description ──────────────────────────────────────
                      Text(
                        'Description'.tr,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        artifact.localizedDescription(lang),
                        style: TextStyle(
                          fontSize: 14,
                          color: themeNotifier.textSecondaryColor,
                          height: 1.6,
                        ),
                      ),
                      // ── Historical Context ───────────────────────────────
                      if (artifact.resolvedHistoricalContext.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Historical Context'.tr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: themeNotifier.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          artifact.localizedHistoricalContext(lang),
                          style: TextStyle(
                            fontSize: 14,
                            color: themeNotifier.textSecondaryColor,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: themeNotifier.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: themeNotifier.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// InlineAudioPlayer — unchanged from the original
// ─────────────────────────────────────────────────────────────────────────────

class InlineAudioPlayer extends StatefulWidget {
  final String audioAsset;
  final String title;

  const InlineAudioPlayer(
      {super.key, required this.audioAsset, required this.title});

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
    _initAudioSource();

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
  void didUpdateWidget(InlineAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always re-evaluate the source to handle dynamic language switching
    // for audio, ignoring specific backend paths for now.
    _initAudioSource();
  }

  void _initAudioSource() {
    // For now, always play the localized audio files regardless of backend data.
    final source = AudioAssets.getLocalizedSource();

    _audioPlayer.setSource(source).then((_) {
      _audioPlayer.getDuration().then((d) {
        if (d != null && mounted) setState(() => _duration = d);
      });
    }).catchError((e) {
      // Handle source setting errors
      debugPrint("Error setting audio source: $e");
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
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: themeNotifier.isDarkMode
                ? const Color(0xFF3F3F46)
                : const Color(0xFFB5B5B5),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          ),
          child: Slider(
            min: 0.0,
            max: _duration.inMilliseconds.toDouble() > 0
                ? _duration.inMilliseconds.toDouble()
                : 1.0,
            value: _position.inMilliseconds.toDouble().clamp(
                0.0,
                _duration.inMilliseconds.toDouble() > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0),
            onChanged: (value) {
              final newPosition = Duration(milliseconds: value.toInt());
              _audioPlayer.seek(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Text(
                _formatDuration(_position),
                style: TextStyle(
                    color: themeNotifier.textSecondaryColor, fontSize: 11),
              ),
              const Spacer(),
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                    color: themeNotifier.textSecondaryColor, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
