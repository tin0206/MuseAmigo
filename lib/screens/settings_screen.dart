import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _themeLight = true;
  bool _audioGuide = true;
  bool _autoPlay = false;
  bool _indoorNavigation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF171A21),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Customize your museum experience',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCC353A)),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/model.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Justin Nguyen',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'justin@museum.com',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SectionLabel(text: 'APPEARANCE'),
              const SizedBox(height: 8),
              _ToggleTile(
                icon: Icons.wb_sunny_outlined,
                title: 'Theme',
                subtitle: _themeLight ? 'Light' : 'Dark',
                value: _themeLight,
                onChanged: (v) => setState(() => _themeLight = v),
              ),
              const SizedBox(height: 8),
              const _ArrowTile(
                icon: Icons.palette_outlined,
                title: 'Color Scheme',
                subtitle: 'Gold',
                trailingDot: true,
              ),
              const SizedBox(height: 8),
              const _ArrowTile(
                icon: Icons.text_fields_rounded,
                title: 'Font Size',
                subtitle: 'Medium',
              ),
              const SizedBox(height: 16),
              const _SectionLabel(text: 'MUSEUM EXPERIENCE'),
              const SizedBox(height: 8),
              const _ArrowTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English',
              ),
              const SizedBox(height: 8),
              _ToggleTile(
                icon: Icons.record_voice_over_outlined,
                title: 'Audio Guide',
                subtitle: 'Narrated tours',
                value: _audioGuide,
                onChanged: (v) => setState(() => _audioGuide = v),
              ),
              const SizedBox(height: 8),
              _ToggleTile(
                icon: Icons.play_circle_outline,
                title: 'Auto-Play Tours',
                subtitle: 'Automatic playback',
                value: _autoPlay,
                onChanged: (v) => setState(() => _autoPlay = v),
              ),
              const SizedBox(height: 8),
              _ToggleTile(
                icon: Icons.location_on_outlined,
                title: 'Indoor Navigation',
                subtitle: 'Track your location',
                value: _indoorNavigation,
                onChanged: (v) => setState(() => _indoorNavigation = v),
              ),
              const SizedBox(height: 16),
              const _SectionLabel(text: 'ACCOUNT & PRIVACY'),
              const SizedBox(height: 8),
              const _ArrowTile(
                icon: Icons.shield_outlined,
                title: 'Privacy & Security',
                subtitle: 'Data preferences',
              ),
              const SizedBox(height: 8),
              const _ArrowTile(
                icon: Icons.confirmation_number_outlined,
                title: 'My Tickets',
                subtitle: 'View bookings',
              ),
              const SizedBox(height: 8),
              const _ArrowTile(
                icon: Icons.emoji_events_outlined,
                title: 'Achievements',
                subtitle: 'View badges',
              ),
              const SizedBox(height: 16),
              const _SectionLabel(text: 'SUPPORT'),
              const SizedBox(height: 8),
              const _ArrowTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'FAQs & guides',
              ),
              const SizedBox(height: 8),
              const _ArrowTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version 2.4.3',
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCC353A),
                    side: const BorderSide(color: Color(0xFFEFCDD0)),
                    backgroundColor: const Color(0xFFFFF5F5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'MuseAmigo · MobileDev252HCMUT',
                  style: TextStyle(fontSize: 10, color: Color(0xFFB4BAC5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF8A93A3),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ArrowTile extends StatelessWidget {
  const _ArrowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingDot = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool trailingDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFCC353A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171A21),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (trailingDot)
            const CircleAvatar(radius: 9, backgroundColor: Color(0xFFCC353A))
          else
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFCC353A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171A21),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFCC353A),
          ),
        ],
      ),
    );
  }
}
