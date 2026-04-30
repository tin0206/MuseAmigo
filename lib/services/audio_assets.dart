import 'package:audioplayers/audioplayers.dart';
import 'package:museamigo/language_notifier.dart';

class AudioAssets {
  AudioAssets._();

  static const String standardPath = 'assets/audio/sample.wav';

  static const String standardSourceKey = 'audio/sample.wav';

  static final AssetSource engAudioSource = AssetSource('audio/Eng_audio.mp3');
  static final AssetSource vieAudioSource = AssetSource('audio/Vie_audio.mp3');

  static AssetSource get standardSource => AssetSource(standardSourceKey);

  static AssetSource getLocalizedSource() {
    return languageNotifier.currentLanguage == 'Vietnamese'
        ? vieAudioSource
        : engAudioSource;
  }

  static AssetSource sourceFor(String assetPath) {
    if (assetPath.isEmpty) return standardSource;
    final key = assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;
    return AssetSource(key);
  }
}
