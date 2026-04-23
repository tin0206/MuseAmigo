import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController(text: 'Sarah Johnson');
  final _dobCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _interestsCtrl = TextEditingController(
    text: 'Ancient Egypt, Mythology, Archaeology',
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _bioCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171A21),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 22),
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/model.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFCC353A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Click camera icon to change avatar',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _fieldLabel('Full Name'),
                    _textField(_nameCtrl),
                    const SizedBox(height: 8),
                    _fieldLabel('Email (Read-only)'),
                    _textField(
                      null,
                      hint: 'sarah.johnson@email.com',
                      enabled: false,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Email cannot be changed',
                      style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 8),
                    _fieldLabel('Date of Birth'),
                    _textField(_dobCtrl),
                    const SizedBox(height: 8),
                    _fieldLabel('Bio'),
                    _textField(
                      _bioCtrl,
                      hint: 'Tell us about yourself',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Help AI personalize your experience',
                      style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 8),
                    _fieldLabel('Interests'),
                    _textField(_interestsCtrl),
                    const SizedBox(height: 2),
                    const Text(
                      'Separate interests with commas',
                      style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCC353A),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: const Color(0x44CC353A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  static Widget _textField(
    TextEditingController? controller, {
    String? hint,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: enabled ? const Color(0xFF171A21) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}
