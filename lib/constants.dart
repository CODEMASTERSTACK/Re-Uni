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

/// Max profiles an unverified student can see in swipe before being prompted to verify.
const int kMaxProfilesForUnverified = 10;

/// Grace period (hours) before suspension if not verified.
const int kVerificationGraceHours = 72;

/// Discovery batch size.
const int kDiscoveryBatchSize = 20;

/// When true, discovery (in debug builds only) includes profiles that are not yet student-verified, so you can test with multiple accounts without running OTP for each. Production builds always require verification.
const bool kDiscoveryIncludeUnverifiedInDebug = true;

/// Max profile images.
const int kMaxProfileImages = 5;

/// Max times user can change name, gender, or age (each) after profile creation.
const int kMaxNameGenderAgeChanges = 2;

/// Backend API base URL (Vercel). No trailing slash.
/// Override with --dart-define=BACKEND_URL=... for local dev (e.g. http://localhost:3000).
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://re-uni.vercel.app',
);

/// Clerk Account Portal sign-in URL for web redirect flow.
/// Matches your Frontend API slug (working-turtle-74); Account Portal uses accounts.dev.
/// Override with --dart-define=CLERK_WEB_SIGN_IN_URL=... if needed.
const String kClerkWebSignInUrl = String.fromEnvironment(
  'CLERK_WEB_SIGN_IN_URL',
  defaultValue: 'https://working-turtle-74.accounts.dev/sign-in',
);
