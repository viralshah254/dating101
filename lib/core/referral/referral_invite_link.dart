/// Public invite URL for “Invite friends” — must match the web download page.
String buildReferralInviteDownloadLink(String code) {
  final trimmed = code.trim();
  return Uri(
    scheme: 'https',
    host: 'www.shubhmilan.app',
    path: '/download',
    queryParameters: {if (trimmed.isNotEmpty) 'ref': trimmed},
  ).toString();
}
