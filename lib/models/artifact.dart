// Domain model for a museum artifact.
//
// Consolidates data from the backend API with local asset resolution
// (image paths, exhibition/location mapping) so the UI layer never
// needs to hardcode any content.
//
// Bilingual support is provided via the `localized*()` methods, which
// delegate to [ArtifactLocalizer]. Screens should always call these
// methods instead of accessing raw fields directly when displaying text.

import 'package:museamigo/l10n/artifact_localizer.dart';

class Artifact {
  const Artifact({
    required this.id,
    required this.artifactCode,
    required this.title,
    required this.year,
    required this.description,
    required this.is3dAvailable,
    required this.museumId,
    required this.unityPrefabName,
    this.audioAsset = '',
    this.exhibitionLocation = '',
    this.category = '',
    this.historicalContext = '',
  });

  final int id;
  final String artifactCode;
  final String title;
  final String year;
  final String description;
  final bool is3dAvailable;
  final int museumId;
  final String unityPrefabName;
  final String audioAsset;

  /// The physical location within the museum (e.g. "Front Lawn - Main Gate Courtyard").
  final String exhibitionLocation;

  /// Category / exhibition grouping (e.g. "Fall of Saigon: April 30, 1975").
  final String category;

  /// Additional historical context beyond the description.
  final String historicalContext;

  // ── Image resolution ──────────────────────────────────────────────────────

  /// Mapping of artifact codes to their asset filenames.
  /// This avoids hardcoding image paths in any UI file.
  static const Map<String, String> imageAssetMap = {
    'IP-001': 'artifact/IP-001-T390.png',
    'IP-002': 'artifact/IP-001-T843.png',
    'IP-003': 'artifact/IP-003-UH1.png',
    'IP-004': 'artifact/IP-004-W110.png',
    'IP-005': 'artifact/IP-005-BunkeMap.png',
    'IP-006': 'artifact/IP-006-Bombing.png',
    'IP-007': 'artifact/IP-007-M151A2.png',
    'IP-008': 'artifact/IP-008-BNDC.png',
    'IP-009': 'artifact/IP-009-Cabinet.png',
    'IP-010': 'artifact/IP-010-Tapestry.png',
    'IP-011': 'artifact/IP-011-Telecom.png',
    'IP-012': 'artifact/IP-012-Bed.png',
    'IP-013': 'artifact/IP-013-Map.jpg',
    'IP-014': 'artifact/IP-014-Projector.jpg',
    'IP-015': 'artifact/IP-015-Desk.png',
  };

  static const String placeholderImage = 'assets/images/museum.jpg';

  /// Returns the image path for a given artifact code (static utility).
  static String imagePathForCode(String code) =>
      imageAssetMap[code] ?? placeholderImage;

  /// Returns the best-matching local image asset path for this artifact.
  /// Falls back to [placeholderImage] if no specific image exists.
  String get imagePath => imageAssetMap[artifactCode] ?? placeholderImage;

  // ── Location / exhibition lookup ──────────────────────────────────────────

  /// Maps artifact codes to their physical exhibition locations.
  static const Map<String, String> _locationMap = {
    'IP-001': 'Front Lawn — Main Gate Courtyard',
    'IP-002': 'Front Lawn — Side Gate Courtyard',
    'IP-003': 'Rooftop Helipad',
    'IP-004': 'Outdoor Vehicle Display Area',
    'IP-005': 'Basement — War Command Bunker',
    'IP-006': 'Rooftop Terrace',
    'IP-007': 'Front Courtyard — Military Vehicle Display',
    'IP-008': 'First Floor — Credentials Presentation Room',
    'IP-009': 'First Floor — Cabinet Room',
    'IP-010': 'Second Floor — State Banquet Hall',
    'IP-011': 'Basement — Telecommunications Center',
    'IP-012': 'Second Floor — Presidential Private Quarters',
    'IP-013': 'Basement — Tactical Command Room',
    'IP-014': 'Basement — Private Cinema Room',
    'IP-015': 'Second Floor — Vice President Office',
  };

  /// Maps artifact codes to their exhibition / category names.
  static const Map<String, String> _categoryMap = {
    'IP-001': 'Fall of Saigon — April 30, 1975',
    'IP-002': 'Fall of Saigon — April 30, 1975',
    'IP-003': 'Fall of Saigon — April 30, 1975',
    'IP-004': 'Presidential Transport & Lifestyle',
    'IP-005': 'Underground War Command Center',
    'IP-006': 'Fall of Saigon — April 30, 1975',
    'IP-007': 'Fall of Saigon — April 30, 1975',
    'IP-008': 'Art & Diplomatic Heritage',
    'IP-009': 'Presidential Power & Governance',
    'IP-010': 'Art & Diplomatic Heritage',
    'IP-011': 'Underground War Command Center',
    'IP-012': 'Presidential Transport & Lifestyle',
    'IP-013': 'Underground War Command Center',
    'IP-014': 'Presidential Transport & Lifestyle',
    'IP-015': 'Presidential Power & Governance',
  };

  /// Maps artifact codes to historically accurate context paragraphs.
  static const Map<String, String> _historicalContextMap = {
    'IP-001':
        'On the morning of April 30, 1975, Tank 390 — a Chinese-made Type 59 — became the first tank to crash through the main gates of the Independence Palace, a moment captured by photographers and broadcast worldwide. The tank was crewed by soldiers of the 203rd Armored Brigade, with Political Commissar Vũ Đăng Toàn aboard. While Tank 843 actually reached the gates first but became wedged in the smaller side gate, Tank 390 smashed through the central main gate, allowing its crew and soldiers to storm the palace. This event is widely regarded as the defining image of the Fall of Saigon and the reunification of Vietnam.',
    'IP-002':
        'Tank 843, a Soviet-built T-54B, was the first armored vehicle to reach the Independence Palace on April 30, 1975, under the command of Captain Bùi Quang Thận of the 203rd Armored Brigade. After ramming the smaller side gate, the tank stalled momentarily. Bùi Quang Thận then dismounted, sprinted into the palace, climbed to the rooftop, and hoisted the flag of the Provisional Revolutionary Government — an iconic act of liberation. For two decades, Tank 843 was officially credited as the first tank to enter the Palace. In 2012, Tank 843 was officially designated a National Treasure of Vietnam.',
    'IP-003':
        'This UH-1 Huey helicopter, formerly of the Republic of Vietnam Air Force, is displayed on the rooftop helipad alongside the bomb marks from the April 8 attack. It was one of the helicopter models used by President Nguyễn Văn Thiệu for official travel. The rooftop helipad was a critical operational feature of the Palace, designed by architect Ngô Viết Thụ to allow rapid evacuation of the President in emergencies. During the final days of the war, helicopters similar to this one were part of the frantic evacuation effort known as Operation Frequent Wind.',
    'IP-004':
        'This Mercedes-Benz 200 (W110 series), manufactured in the 1960s, served as one of the official presidential motorcade vehicles during the tenure of President Nguyễn Văn Thiệu (1967–1975). The car reflects the diplomatic image the Republic of Vietnam government sought to project, using European luxury vehicles for state functions. It is now preserved in the outdoor vehicle display area alongside other presidential transport artifacts, providing visitors a glimpse into the daily operations and ceremonial functions of the presidential administration.',
    'IP-005':
        'The strategic war maps displayed in the basement command bunker were essential tools for the South Vietnamese military leadership during the Vietnam War. Designed by engineer Lieutenant Colonel Phan Văn Điển, the bunker was constructed with reinforced concrete walls capable of withstanding aerial bombardment up to 2,000 kg. These maps tracked troop movements, tactical positions, and operational zones across South Vietnam. The bunker served as the nerve center of the war effort, where critical military decisions were made under extreme pressure during the final years of the conflict.',
    'IP-006':
        'On the morning of April 8, 1975, First Lieutenant Nguyễn Thành Trung (real name Đinh Khắc Chung) — a covert revolutionary agent embedded within the Republic of Vietnam Air Force — piloted an F-5E Tiger II fighter and broke formation during a bombing mission over Phan Thiết. He turned his aircraft toward Saigon and dropped bombs directly onto the Independence Palace rooftop. Two red circles painted on the terrace mark the exact impact locations. This daring attack was a powerful psychological blow against the Saigon government and signaled the approaching end of the war, just 22 days before the Fall of Saigon.',
    'IP-007':
        'This M151A2 military jeep was used by revolutionary forces on April 30, 1975, to escort General Dương Văn Minh — the last president of the Republic of Vietnam — from the Independence Palace to the Saigon Radio Station. At the radio station, General Minh read the unconditional surrender declaration, officially ending the Vietnam War. The jeep stands as a tangible link to the final hours of the conflict, when political authority transferred from the Republic of Vietnam to the Provisional Revolutionary Government.',
    'IP-008':
        'This monumental lacquer painting, measuring approximately 14 meters wide and 9 meters tall, is assembled from 40 individual lacquer panels. Created by artist Nguyễn Văn Minh in 1966 during the Palace construction, the work depicts the "Bình Ngô Đại Cáo" (Great Proclamation upon the Pacification of the Ngô) — the 15th-century proclamation by national hero Nguyễn Trãi declaring Vietnamese independence after defeating the Ming Chinese occupation. The painting uses traditional Vietnamese lacquer techniques with gold leaf, eggshell inlay, and natural pigments, making it one of the most significant lacquer artworks in Vietnam.',
    'IP-009':
        'The Cabinet Room was the formal meeting chamber where the President of the Republic of Vietnam convened with his ministers and senior officials. The room features a large oval conference table covered in green felt, surrounded by executive chairs. It was in this room on the morning of April 30, 1975, that General Dương Văn Minh and his cabinet assembled to prepare the unconditional surrender. When tanks breached the Palace gates, Colonel Bùi Tín of the North Vietnamese Army entered this room to formally accept the surrender.',
    'IP-010':
        'This large tapestry, prominently displayed in the State Banquet Hall on the second floor, depicts a golden dragon — a traditional Vietnamese imperial symbol representing royal authority, prosperity, and the celestial mandate. The State Banquet Hall was used by the President to host state dinners for visiting foreign dignitaries and ambassadors. The room, designed by architect Ngô Viết Thụ, features a blend of mid-century modernism with Vietnamese decorative traditions, and the tapestry serves as its visual centerpiece.',
    'IP-011':
        'The Telecommunications Center, located deep within the basement bunker complex, housed the vital communications equipment that connected the presidential command center with military field operations, regional commands, and foreign embassies. The preserved collection includes 1960s-era radio transmitters, telephone switchboards, teletype machines, and encrypted communication devices. This room ensured that the President and his military advisors could maintain command and control even during sustained aerial bombardment of the capital.',
    'IP-012':
        'The Presidential Bedroom, located in the private residential quarters on the second floor, has been preserved exactly as it was abandoned when President Nguyễn Văn Thiệu fled Saigon on April 21, 1975 — nine days before the Fall of Saigon. The room contains the original bed, personal furnishings, and period décor, offering visitors a rare and intimate view into the private life of the most powerful figure in the Republic of Vietnam. The preservation of this space reflects the abruptness of the regime change and the chaos of the final days.',
    'IP-013':
        'The National Security Council strategic war maps, mounted on the walls of the Tactical Command Room in the basement, display the military situation across all four military regions of South Vietnam. These maps were actively updated during the war and show force deployments, territorial boundaries, and key strategic positions. The room served as the operational heart of the South Vietnamese defense strategy, where the President, Joint Chiefs, and American military advisors coordinated the war effort. The maps remain frozen in time, showing the military situation in the war\'s final weeks.',
    'IP-014':
        'The private cinema room in the basement level was used by the Presidential family and close associates for private film screenings. The vintage projector and screening equipment date from the 1960s and represent the lifestyle amenities built into the Palace as both a seat of government and a private residence. The cinema room\'s existence within a fortified basement complex illustrates the unique duality of the Independence Palace — a place where the instruments of war command sat alongside the comforts of domestic life.',
    'IP-015':
        'This finely crafted wooden desk served as the primary workspace of the Vice President of the Republic of Vietnam. Located in the Vice President Office on the second floor, the desk exemplifies traditional Vietnamese woodworking techniques with detailed hand-carved ornamentation. The office was one of several key administrative spaces in the Palace, reflecting the hierarchical structure of the South Vietnamese government. The desk and surrounding furnishings have been preserved in their original arrangement since 1975.',
  };

  /// Resolves the exhibition location string.
  /// Uses [exhibitionLocation] if already set; otherwise falls back to the lookup table.
  String get resolvedLocation => exhibitionLocation.isNotEmpty
      ? exhibitionLocation
      : (_locationMap[artifactCode] ?? 'Independence Palace');

  /// Resolves the category string.
  String get resolvedCategory => category.isNotEmpty
      ? category
      : (_categoryMap[artifactCode] ?? 'General Exhibition');

  /// Resolves the historical context string.
  String get resolvedHistoricalContext => historicalContext.isNotEmpty
      ? historicalContext
      : (_historicalContextMap[artifactCode] ?? '');

  // ── Language-aware display getters ───────────────────────────────────────

  /// Returns the title in the requested language.
  /// Falls back to the API-fetched English [title].
  String localizedTitle(String language) =>
      ArtifactLocalizer.title(artifactCode, language, englishFallback: title);

  /// Returns the short description in the requested language.
  /// Falls back to the API-fetched English [description].
  String localizedDescription(String language) => ArtifactLocalizer.description(
    artifactCode,
    language,
    englishFallback: description,
  );

  /// Returns the physical exhibition location in the requested language.
  String localizedLocation(String language) => ArtifactLocalizer.location(
    artifactCode,
    language,
    englishFallback: resolvedLocation,
  );

  /// Returns the category / exhibition group in the requested language.
  String localizedCategory(String language) => ArtifactLocalizer.category(
    artifactCode,
    language,
    englishFallback: resolvedCategory,
  );

  /// Returns the long-form historical context in the requested language.
  String localizedHistoricalContext(String language) =>
      ArtifactLocalizer.historicalContext(
        artifactCode,
        language,
        englishFallback: resolvedHistoricalContext,
      );
}
