/// Configuration used to build YouTube InnerTube client requests.
///
/// Different InnerTube clients expose different response shapes. The default
/// [YoutubeClientConfig.web] keeps the existing search/browse behavior, while
/// [YoutubeClientConfig.ios] returns direct adaptive stream URLs from the
/// player endpoint and is therefore the default player client.
final class YoutubeClientConfig {
  const YoutubeClientConfig({
    this.clientName = 'WEB',
    this.clientNameId = '1',
    this.clientVersion = '2.20230818.00.00',
    this.language = 'en',
    this.country = 'US',
    this.userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
    this.osName,
    this.osVersion,
    this.androidSdkVersion,
    this.deviceMake,
    this.deviceModel,
  });

  const YoutubeClientConfig.web() : this();

  /// YouTube Music (`music.youtube.com`) InnerTube client. Music search and
  /// search suggestions only answer with list items for `WEB_REMIX`; the WEB
  /// client returns an empty catalog for the same query.
  const YoutubeClientConfig.music()
    : this(
        clientName: 'WEB_REMIX',
        clientNameId: '67',
        clientVersion: '1.20230818.01.00',
      );

  /// Android InnerTube client. Current responses use SABR
  /// (`serverAbrStreamingUrl`) instead of per-format URLs, so this preset is
  /// exposed for callers that understand SABR, not as the default player.
  const YoutubeClientConfig.android()
    : this(
        clientName: 'ANDROID',
        clientNameId: '3',
        clientVersion: '21.03.36',
        userAgent:
            'com.google.android.youtube/21.03.36 (Linux; U; Android 16) gzip',
        osName: 'Android',
        osVersion: '16',
        androidSdkVersion: 36,
        deviceMake: 'Google',
        deviceModel: 'Pixel 7',
      );

  /// iOS InnerTube client. The player response carries direct `url` values in
  /// `adaptiveFormats` plus an `hlsManifestUrl`, which the package can return
  /// without a signature-deciphering step.
  const YoutubeClientConfig.ios()
    : this(
        clientName: 'IOS',
        clientNameId: '5',
        clientVersion: '20.10.4',
        userAgent:
            'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 '
            'like Mac OS X;)',
        osName: 'iPhone',
        osVersion: '18.3.2.22D82',
        deviceMake: 'Apple',
        deviceModel: 'iPhone16,2',
      );

  final String clientName;
  final String clientNameId;
  final String clientVersion;
  final String language;
  final String country;
  final String userAgent;

  /// Mobile client context fields. They are omitted from the request context
  /// when null, keeping the WEB context unchanged.
  final String? osName;
  final String? osVersion;
  final int? androidSdkVersion;
  final String? deviceMake;
  final String? deviceModel;
}
