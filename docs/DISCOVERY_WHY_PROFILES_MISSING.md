# Why Don’t I See Other Profiles in Swipe?

The swipe feed only shows profiles that pass **all** of these:

1. **Onboarding complete** – They finished profile setup (name, photos, interests, etc.) and reached the Profile Summary screen.  
   - Stored as `onboardingComplete: true` in Firestore `users/{userId}`.

2. **Student verified** – They completed student verification (university email OTP).  
   - Stored as `isStudentVerified: true` in Firestore. New profiles get `isStudentVerified: false` until they complete the verification flow from Profile Summary.

3. **Gender filter** – Discovery is gender-based:
   - If **you** are **male**, you only see **female** profiles.
   - If **you** are **female**, you only see **male** profiles.
   - If you are **non-binary** or **other**, who you see depends on your discovery preference (men / women / everyone / non_binary).

So if you created three test accounts and only one is logged in:

- The **other two** must have **completed profile setup** and **student verification**, and their **gender** must match what your account is allowed to see (e.g. if you’re male, they must be female).

## Testing with Multiple Accounts

**Option A – Debug builds (recommended for local testing)**  
In **debug** mode, the app can include **unverified** profiles in discovery so you don’t need to run OTP for every test account.

- In `lib/constants.dart`, `kDiscoveryIncludeUnverifiedInDebug` is `true` by default.
- When you run in debug (e.g. `flutter run -d chrome`), discovery will show profiles that have `onboardingComplete: true` even if `isStudentVerified` is false.
- **Release/production builds** always require `isStudentVerified: true`; this flag has no effect there.

**Option B – Verify each test account**  
Complete student verification (university email OTP) for each test profile. Then they will appear for accounts that match the gender rule above.

**Option C – Manually set in Firestore**  
In Firebase Console → Firestore → `users` → select each test user document → set:

- `onboardingComplete`: `true`
- `isStudentVerified`: `true`

Also ensure **gender** matches: if the logged-in user is male, test profiles must be female (and vice versa) to appear in swipe.

## Quick checklist

- [ ] Other profiles have finished profile setup (Profile Summary reached).
- [ ] Other profiles are student-verified **or** you’re running a debug build with `kDiscoveryIncludeUnverifiedInDebug: true`.
- [ ] Gender: if you’re male, other profiles are female; if you’re female, other profiles are male.
