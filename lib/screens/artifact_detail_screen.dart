import 'package:flutter/material.dart';

class ArtifactDetailScreen extends StatelessWidget {
  const ArtifactDetailScreen({
    super.key,
    required this.title,
    required this.location,
    required this.year,
    required this.currentLocation,
    required this.height,
    required this.weight,
    required this.imageAsset,
  });

  final String title;
  final String location;
  final String year;
  final String currentLocation;
  final String height;
  final String weight;
  final String imageAsset;

  static const Color _brandRed = Color(0xFFCC353A);

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
                        imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
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
                      child: const Text(
                        'Navigate',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171A21),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                              title,
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
                            decoration: const BoxDecoration(
                              color: _brandRed,
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
                              activeTrackColor: _brandRed,
                              inactiveTrackColor: const Color(0xFFB5B5B5),
                              thumbColor: _brandRed,
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
                      _infoRow('Title:', title),
                      _infoRow('Year:', year),
                      _infoRow('Current Location:', currentLocation),
                      _infoRow('Height:', height),
                      _infoRow('Weight:', weight),
                      const SizedBox(height: 18),
                      const Text(
                        'Detailed Description',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171A21),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "T-54B tank No. 843 is a legendary Vietnam People's Army tank that famously breached the Independence Palace gate in Saigon on April 30, 1975, marking the end of the Vietnam War. Led by Captain Bui Quang Than, this Soviet-made tank is celebrated as a National Treasure and symbolizes Vietnam's liberation and reunification.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2E2E2E),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Enhanced Part',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171A21),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'The First That Was not First',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171A21),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'While tank 843 is often pictured alongside tank 390, there is a lingering historical race. Tank 843, commanded by Bui Quang Than, reached the Palace gates first. However, after becoming momentarily wedged in the smaller side gate, tank 390 crashed through the main central gate.',
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
