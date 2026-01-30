# Sign-up flow, gender/age, and “Development mode”

## What the Clerk “Create your account” page does

When users click **Create account** on your landing page, they are sent to **Clerk’s hosted sign-up page** (the “Create your account” screen with UniDate logo, Google, email/password, etc.). That page is **only for identity**:

- Email and password (or “Continue with Google”)
- Optional first name / last name

Clerk does **not** ask for gender, age, or other dating-profile fields. That’s by design: Clerk handles **authentication** (who you are); your app handles **profile** (gender, age, interests, etc.).

---

## Where gender and age are collected

After the user finishes sign-up on Clerk and is redirected back to your app:

1. Your app exchanges the Clerk callback for a Firebase session.
2. **WebAuthGate** (or **AuthGate** on mobile) runs.
3. If the user has no profile or onboarding is not complete, they see **Profile setup** (`ProfileSetupScreen`).

**Gender and age are collected in that Profile setup screen**, inside your app:

- **Age**: slider (18–100)
- **Gender**: male, female, non_binary, other
- Plus: profile photos, “Show me” (discovery preference), bio, interests

So the flow is:

1. **Clerk “Create your account”** → identity only (email/password or Google).
2. **Redirect back to UniDate** → **Profile setup** → gender, age, photos, preferences.

If you want gender/age to feel “part of sign-up,” you can later add a short in-app step right after redirect (e.g. “Almost there – tell us a bit about you”) that still uses `ProfileSetupScreen` or a slimmed-down version of it. The current design is correct: Clerk = identity, UniDate = profile.

---

## “Development mode” on the Clerk page

The **“Development mode”** (or “Secured by Clerk” / orange badge) text is shown **by Clerk** on their hosted pages when you use a **development** Clerk instance (e.g. `*.accounts.dev`). Your Flutter app does not control this.

To remove it:

1. In the **Clerk Dashboard**, use (or switch to) a **production** instance.
2. Or use a **custom domain** for the Account Portal if you have that set up.

There is no code change in UniDate that can hide Clerk’s development badge; it’s a Clerk environment/configuration setting.

---

## Summary

| Topic | Where it lives |
|-------|----------------|
| Email, password, Google, optional name | Clerk “Create your account” page |
| Gender, age, photos, “Show me”, bio, interests | UniDate **Profile setup** screen (after redirect) |
| “Development mode” badge | Clerk; remove by using production instance or custom domain in Clerk Dashboard |
