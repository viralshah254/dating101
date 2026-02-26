/// Block reason codes sent to backend. Labels used in reason picker UI.
const Map<String, String> blockReasonLabels = {
  'spam': 'Spam',
  'harassment': 'Harassment',
  'inappropriate_content': 'Inappropriate content',
  'fake_profile': 'Fake profile',
  'other': 'Other',
};

/// Report reason codes sent to backend. Labels used in reason picker UI.
const Map<String, String> reportReasonLabels = {
  'spam': 'Spam',
  'harassment': 'Harassment',
  'inappropriate_photos': 'Inappropriate photos',
  'fake_profile': 'Fake profile',
  'scam': 'Scam or fraud',
  'other': 'Other',
};

List<String> get blockReasonCodes => blockReasonLabels.keys.toList();
List<String> get reportReasonCodes => reportReasonLabels.keys.toList();
