/// Configuration used to build YouTube InnerTube client requests.
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
  });

  final String clientName;
  final String clientNameId;
  final String clientVersion;
  final String language;
  final String country;
  final String userAgent;
}
