import 'package:flutter/material.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:audioplayers/audioplayers.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_isLoading) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isLoading = true);
      try {
        if (widget.audioAsset.isNotEmpty) {
          await _audioPlayer.play(AssetSource(widget.audioAsset));
          setState(() {
            _isPlaying = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to play audio: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      child: Image.asset(
                        widget.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, size: 56),
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Navigate'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171A21),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Audio Player Section
              if (widget.audioAsset.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Audio Guide'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF171A21),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _toggleAudio,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: CircularProgressIndicator(),
                        ),
                      if (!_isLoading && _isPlaying)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              // 3D Model View Section - Temporarily commented out
              /*
              if (modelAsset.isNotEmpty)
                Container(
                  height: 300,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              '3D Model View'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF171A21),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                // Toggle 3D view controls
                              },
                              icon: const Icon(Icons.view_in_ar),
                              color: Color(0xFF171A21),
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
              const SizedBox(height: 14),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title.tr,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF171A21),
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pause,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5,
                              ),
                              activeTrackColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              inactiveTrackColor: const Color(0xFFB5B5B5),
                              thumbColor: Theme.of(context).colorScheme.primary,
                            ),
                            child: Slider(value: 0.55, onChanged: (_) {}),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Row(
                              children: [
                                Text(
                                  '00:48',
                                  style: TextStyle(
                                    color: Color(0xFF6D7785),
                                    fontSize: 11,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '01:30',
                                  style: TextStyle(
                                    color: Color(0xFF6D7785),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Title:'.tr, widget.title.tr),
                      _infoRow('Year:'.tr, widget.year.tr),
                      _infoRow('Current Location:'.tr, widget.currentLocation.tr),
                      _infoRow('Height:'.tr, widget.height.tr),
                      _infoRow('Weight:'.tr, widget.weight.tr),
                      const SizedBox(height: 18),
                      Text(
                        'Detailed Description'.tr,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171A21),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "T-54B tank No. 843 is a legendary Vietnam People's Army tank that famously breached the Independence Palace gate in Saigon on April 30, 1975, marking the end of the Vietnam War. Led by Captain Bui Quang Than, this Soviet-made tank is celebrated as a National Treasure and symbolizes Vietnam's liberation and reunification."
                            .tr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2E2E2E),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Enhanced Part'.tr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171A21),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'The First That Was not First'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171A21),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'While tank 843 is often pictured alongside tank 390, there is a lingering historical race. Tank 843, commanded by Bui Quang Than, reached the Palace gates first. However, after becoming momentarily wedged in the smaller side gate, tank 390 crashed through the main central gate.'
                            .tr,
                        style: const TextStyle(
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
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF171A21)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Color(0xFF171A21)),
            ),
          ),
        ],
      ),
    );
  }
}
