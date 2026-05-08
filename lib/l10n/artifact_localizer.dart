// ArtifactLocalizer
//
// Single source of truth for translating artifact-specific content
// (title, description, location, category, historical context) by
// artifact code + language.
//
// This approach uses artifact CODES as keys rather than long English
// strings, making it robust against API wording changes and scalable
// for adding more languages.
//
// Usage:
//   ArtifactLocalizer.title('IP-001', lang)
//   ArtifactLocalizer.description('IP-001', lang)
//   ArtifactLocalizer.location('IP-001', lang)
//   ArtifactLocalizer.category('IP-001', lang)
//   ArtifactLocalizer.historicalContext('IP-001', lang)

import 'package:museamigo/l10n/artifact_translations.dart';

class ArtifactLocalizer {
  ArtifactLocalizer._();

  // ── Vietnamese Titles ───────────────────────────────────────────────────────
  static const Map<String, String> _titlesVi = {
    'IP-001': 'Xe tăng 390',
    'IP-002': 'Xe tăng T-54 Số 843',
    'IP-003': 'Trực thăng UH-1 Iroquois',
    'IP-004': 'Mercedes-Benz 200 W110',
    'IP-005': 'Bản đồ Hầm Chỉ huy Chiến tranh',
    'IP-006': 'Dấu tích Ném bom F-5E',
    'IP-007': 'Xe Jeep M151A2',
    'IP-008': 'Tranh sơn mài Bình Ngô Đại Cáo',
    'IP-009': 'Bàn Phòng Nội các',
    'IP-010': 'Thảm Rồng Vàng',
    'IP-011': 'Trung tâm Viễn thông',
    'IP-012': 'Giường Tổng thống',
    'IP-013': 'Bản đồ Hội đồng An ninh Quốc gia',
    'IP-014': 'Máy chiếu Phòng Chiếu phim Tầng hầm',
    'IP-015': 'Bàn làm việc Phó Tổng thống',
  };

  // ── Vietnamese Descriptions (short, from API equivalent) ───────────────────
  static const Map<String, String> _descriptionsVi = {
    'IP-001':
        'Xe tăng Type 59 do Trung Quốc sản xuất, nổi tiếng là chiếc xe tăng đầu tiên húc đổ cổng chính Dinh Độc Lập vào ngày 30 tháng 4 năm 1975, đánh dấu sự kết thúc của Chiến tranh Việt Nam. Chiếc xe tăng này đã trở thành biểu tượng mang tính lịch sử của ngày thống nhất đất nước.',
    'IP-002':
        'Xe tăng T-54B do Liên Xô sản xuất mang số hiệu 843, là phương tiện bọc thép đầu tiên tiến đến Dinh Độc Lập vào ngày 30 tháng 4 năm 1975. Dưới sự chỉ huy của Đại úy Bùi Quang Thận, xe được công nhận là Bảo vật Quốc gia của Việt Nam.',
    'IP-003':
        'Trực thăng UH-1 Huey nguyên thuộc Không quân Việt Nam Cộng hòa, được trưng bày trên sân bay trực thăng sân thượng cùng với các dấu tích bom từ vụ tấn công ngày 8 tháng 4. Đây là loại trực thăng được Tổng thống Nguyễn Văn Thiệu sử dụng cho các chuyến công du chính thức.',
    'IP-004':
        'Xe Mercedes-Benz 200 dòng W110 sản xuất thập niên 1960, từng là một trong những phương tiện đoàn xe hộ tống chính thức của Tổng thống Nguyễn Văn Thiệu trong nhiệm kỳ 1967–1975. Chiếc xe thể hiện hình ảnh ngoại giao của chính quyền Việt Nam Cộng hòa.',
    'IP-005':
        'Bộ bản đồ chiến tranh chiến lược được trưng bày trong hầm chỉ huy tầng hầm, là công cụ thiết yếu cho giới lãnh đạo quân sự miền Nam Việt Nam trong Chiến tranh Việt Nam. Hầm ngầm được xây dựng với tường bê tông cốt thép chịu được bom đạn lên tới 2.000 kg.',
    'IP-006':
        'Hai vòng tròn đỏ trên sân thượng Dinh Độc Lập đánh dấu vị trí hai quả bom rơi xuống vào sáng ngày 8 tháng 4 năm 1975. Cuộc ném bom được thực hiện bởi Trung úy Nguyễn Thành Trung, một điệp viên cách mạng hoạt động bí mật trong Không quân Việt Nam Cộng hòa.',
    'IP-007':
        'Xe jeep quân sự M151A2 được lực lượng cách mạng sử dụng vào ngày 30 tháng 4 năm 1975 để hộ tống Tổng thống Dương Văn Minh từ Dinh Độc Lập đến Đài Phát thanh Sài Gòn, nơi ông đọc tuyên bố đầu hàng vô điều kiện.',
    'IP-008':
        'Bức tranh sơn mài hoành tráng ghép từ 40 tấm sơn mài, kích thước khoảng 14m × 9m, do họa sĩ Nguyễn Văn Minh sáng tác năm 1966. Tác phẩm mô tả "Bình Ngô Đại Cáo" — bản tuyên cáo độc lập thế kỷ 15 của Nguyễn Trãi.',
    'IP-009':
        'Phòng Nội các là phòng họp chính thức nơi Tổng thống Việt Nam Cộng hòa họp với các bộ trưởng. Chính tại đây, vào sáng ngày 30 tháng 4 năm 1975, Tổng thống Dương Văn Minh đã chuẩn bị tuyên bố đầu hàng vô điều kiện.',
    'IP-010':
        'Tấm thảm lớn trưng bày tại Phòng Yến tiệc Quốc gia tầng hai mô tả hình rồng vàng — biểu tượng hoàng gia truyền thống Việt Nam tượng trưng cho quyền lực vương triều và sự thịnh vượng. Phòng do kiến trúc sư Ngô Viết Thụ thiết kế.',
    'IP-011':
        'Trung tâm Viễn thông nằm sâu trong tổ hợp hầm ngầm tầng hầm, chứa các thiết bị liên lạc quan trọng kết nối trung tâm chỉ huy tổng thống với các chiến dịch quân sự thực địa và các đại sứ quán nước ngoài.',
    'IP-012':
        'Phòng ngủ Tổng thống được bảo tồn nguyên trạng kể từ khi Tổng thống Nguyễn Văn Thiệu rời Sài Gòn vào ngày 21 tháng 4 năm 1975. Phòng chứa chiếc giường nguyên bản và đồ nội thất cá nhân, mang đến cái nhìn hiếm hoi vào đời sống riêng tư của tổng thống.',
    'IP-013':
        'Bản đồ chiến lược của Hội đồng An ninh Quốc gia gắn trên tường Phòng Chỉ huy Tác chiến, thể hiện tình hình quân sự trên cả bốn vùng chiến thuật của miền Nam Việt Nam trong những tuần cuối của cuộc chiến.',
    'IP-014':
        'Phòng chiếu phim riêng ở tầng hầm được gia đình Tổng thống sử dụng để xem phim. Máy chiếu và thiết bị từ thập niên 1960 thể hiện sự song hành độc đáo giữa trụ sở chính phủ và nơi ở gia đình trong Dinh Độc Lập.',
    'IP-015':
        'Chiếc bàn gỗ chế tác tinh xảo là nơi làm việc chính của Phó Tổng thống Việt Nam Cộng hòa tại Văn phòng Phó Tổng thống tầng hai. Bàn thể hiện kỹ thuật chế tác gỗ truyền thống Việt Nam với hoa văn chạm khắc tay chi tiết.',
  };

  // ── Vietnamese Locations (by artifact code) ─────────────────────────────────
  static const Map<String, String> _locationsVi = {
    'IP-001': 'Sân trước — Sân cổng chính',
    'IP-002': 'Sân trước — Sân cổng phụ',
    'IP-003': 'Sân bay trực thăng',
    'IP-004': 'Khu trưng bày phương tiện ngoài trời',
    'IP-005': 'Tầng hầm — Hầm Chỉ huy Chiến tranh',
    'IP-006': 'Sân thượng',
    'IP-007': 'Sân trước — Trưng bày Phương tiện Quân sự',
    'IP-008': 'Tầng 1 — Phòng Trình Quốc thư',
    'IP-009': 'Tầng 1 — Phòng Nội các',
    'IP-010': 'Tầng 2 — Phòng Yến tiệc Quốc gia',
    'IP-011': 'Tầng hầm — Trung tâm Viễn thông',
    'IP-012': 'Tầng 2 — Khu nhà ở riêng Tổng thống',
    'IP-013': 'Tầng hầm — Phòng Chỉ huy Tác chiến',
    'IP-014': 'Tầng hầm — Phòng Chiếu phim Riêng',
    'IP-015': 'Tầng 2 — Văn phòng Phó Tổng thống',
  };

  // ── Vietnamese Categories (by artifact code) ────────────────────────────────
  static const Map<String, String> _categoriesVi = {
    'IP-001': 'Giải phóng Sài Gòn — 30 tháng 4, 1975',
    'IP-002': 'Giải phóng Sài Gòn — 30 tháng 4, 1975',
    'IP-003': 'Giải phóng Sài Gòn — 30 tháng 4, 1975',
    'IP-004': 'Phương tiện & Đời sống Tổng thống',
    'IP-005': 'Trung tâm Chỉ huy Chiến tranh Ngầm',
    'IP-006': 'Giải phóng Sài Gòn — 30 tháng 4, 1975',
    'IP-007': 'Giải phóng Sài Gòn — 30 tháng 4, 1975',
    'IP-008': 'Di sản Nghệ thuật & Ngoại giao',
    'IP-009': 'Quyền lực & Quản trị Tổng thống',
    'IP-010': 'Di sản Nghệ thuật & Ngoại giao',
    'IP-011': 'Trung tâm Chỉ huy Chiến tranh Ngầm',
    'IP-012': 'Phương tiện & Đời sống Tổng thống',
    'IP-013': 'Trung tâm Chỉ huy Chiến tranh Ngầm',
    'IP-014': 'Phương tiện & Đời sống Tổng thống',
    'IP-015': 'Quyền lực & Quản trị Tổng thống',
  };

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns the localized artifact title.
  /// Falls back to [englishFallback] if no Vietnamese translation exists.
  static String title(
    String artifactCode,
    String language, {
    required String englishFallback,
  }) {
    if (language != 'Vietnamese') return englishFallback;
    return _titlesVi[artifactCode] ?? englishFallback;
  }

  /// Returns the localized artifact description.
  /// Falls back to [englishFallback] (API-provided English) if unavailable.
  static String description(
    String artifactCode,
    String language, {
    required String englishFallback,
  }) {
    if (language != 'Vietnamese') return englishFallback;
    return _descriptionsVi[artifactCode] ?? englishFallback;
  }

  /// Returns the localized exhibition location string.
  static String location(
    String artifactCode,
    String language, {
    required String englishFallback,
  }) {
    if (language != 'Vietnamese') return englishFallback;
    return _locationsVi[artifactCode] ?? englishFallback;
  }

  /// Returns the localized category / exhibition group name.
  static String category(
    String artifactCode,
    String language, {
    required String englishFallback,
  }) {
    if (language != 'Vietnamese') return englishFallback;
    return _categoriesVi[artifactCode] ?? englishFallback;
  }

  /// Returns the localized long-form historical context paragraph.
  /// Uses [artifactHistoricalContextVi] from [artifact_translations.dart].
  static String historicalContext(
    String artifactCode,
    String language, {
    required String englishFallback,
  }) {
    if (language != 'Vietnamese') return englishFallback;
    // The artifact_translations map uses the English paragraph as key.
    return artifactHistoricalContextVi[englishFallback] ?? englishFallback;
  }
}
