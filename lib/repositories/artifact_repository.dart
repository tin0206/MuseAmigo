import 'package:museamigo/models/artifact.dart';
import 'package:museamigo/services/backend_api.dart';

/// Repository that bridges [BackendApi] data-transfer objects with the
/// domain-level [Artifact] model used by the UI.
///
/// All data enrichment (location, category, image path) happens here so
/// screens never need to resolve or hardcode any artifact content.
class ArtifactRepository {
  ArtifactRepository._();
  static final ArtifactRepository instance = ArtifactRepository._();

  final BackendApi _api = BackendApi.instance;

  /// Converts a backend [ArtifactDto] into a rich [Artifact] model.
  Artifact _fromDto(ArtifactDto dto) {
    return Artifact(
      id: dto.id,
      artifactCode: dto.artifactCode,
      title: dto.title,
      year: dto.year,
      description: dto.description,
      is3dAvailable: dto.is3dAvailable,
      museumId: dto.museumId,
      unityPrefabName: dto.unityPrefabName,
      audioAsset: dto.audioAsset,
    );
  }

  /// Fetches all artifacts for a museum and returns enriched [Artifact] models.
  Future<List<Artifact>> fetchArtifacts(int museumId) async {
    final dtos = await _api.fetchArtifacts(museumId);
    return dtos.map(_fromDto).toList();
  }

  /// Fetches a single artifact by its code (e.g. "IP-001").
  Future<Artifact> fetchByCode(String artifactCode) async {
    final dto = await _api.fetchArtifact(artifactCode);
    return _fromDto(dto);
  }
}
