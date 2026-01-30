/// Predefined interests for discovery and profile (config/interests).
const List<Map<String, dynamic>> kInterestsList = [
  {'id': 'music', 'label': 'Music', 'order': 0},
  {'id': 'sports', 'label': 'Sports', 'order': 1},
  {'id': 'gaming', 'label': 'Gaming', 'order': 2},
  {'id': 'movies', 'label': 'Movies', 'order': 3},
  {'id': 'travel', 'label': 'Travel', 'order': 4},
  {'id': 'reading', 'label': 'Reading', 'order': 5},
  {'id': 'fitness', 'label': 'Fitness', 'order': 6},
  {'id': 'cooking', 'label': 'Cooking', 'order': 7},
  {'id': 'art', 'label': 'Art', 'order': 8},
  {'id': 'tech', 'label': 'Tech', 'order': 9},
];

/// Gender identity options.
const List<String> kGenders = ['male', 'female', 'non_binary', 'other'];

/// Discovery preference: who the user wants to see.
const List<String> kDiscoveryPreferences = ['men', 'women', 'everyone', 'non_binary'];

/// University email domain for student verification.
const String kUniversityEmailDomain = '@lpu.in';

/// Grace period (hours) before suspension if not verified.
const int kVerificationGraceHours = 72;

/// Discovery batch size.
const int kDiscoveryBatchSize = 20;

/// Max profile images.
const int kMaxProfileImages = 5;

/// Backend API base URL (Vercel or any serverless). No trailing slash.
/// Set via --dart-define=BACKEND_URL=... or use this default for local Vercel dev.
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:3000',
);
