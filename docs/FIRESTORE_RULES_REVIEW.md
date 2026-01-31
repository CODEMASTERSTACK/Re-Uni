# Firestore Security Rules Review

This document reviews Firestore rules against the UniDate webapp’s actual usage and recommends minimal changes for correctness and least privilege.

---

## Summary

| Collection / Path | Current rule | App usage | Verdict |
|------------------|--------------|-----------|---------|
| `users/{userId}` | read: auth; write: auth + own doc | Profile CRUD, discovery batch, swipe count | ✅ Correct |
| `config/interests` | read: auth; create: auth + !exists | getInterests, seed when missing | ✅ Correct |
| `config/{doc}` | read: auth; write: false | Future config docs | ✅ Correct |
| `swipes/{swipeId}` | read: auth; create: auth + actorId | recordSwipe, getSwipedTargetIds | ✅ Tightened (see below) |
| `matches/{matchId}` | create/read/update/delete: participant | upsert, reject, getMatches, createChat | ✅ Correct |
| `chats/{chatId}` + `messages` | participant-only; message create requires isStudentVerified | createChat, getChats, sendMessage, watchMessages | ✅ Correct |
| `verification_otps/{doc}` | read, write: false | Server-only (Vercel API) | ✅ Correct |

---

## 1. `users/{userId}`

- **Rules:** `allow read: if request.auth != null;` and `allow write: if request.auth != null && request.auth.uid == userId;`
- **Usage:**
  - **Read:** Own profile (profile summary, auth gate, profile setup), other users’ profiles (discovery batch, matches list, chat list, chat thread). Doc ID = Clerk ID = Firebase Auth UID after custom token.
  - **Write:** setUserProfile (create/overwrite), updateUserProfile, setSuspendedIfPastDeadline, incrementSwipeCount, incrementProfilesViewedWhileUnverified. All use the current user’s doc.
- **Verdict:** Correct. Any authenticated user may read any profile (needed for discovery and match/chat UIs). Only the profile owner can write.

---

## 2. `config/interests`

- **Rules:** read if auth; create if auth and `!exists(/databases/$(database)/documents/config/interests)`; update/delete false.
- **Usage:** getInterests() calls ensureInterestsConfig(): get doc, then set only when doc does not exist (first-time seed).
- **Verdict:** Correct. First caller creates the doc; others only read. No client updates.

---

## 3. `config/{doc}`

- **Rules:** read if auth; write false.
- **Usage:** Only `config/interests` is used; this is a catch-all for other config.
- **Verdict:** Correct.

---

## 4. `swipes/{swipeId}`

- **Rules (before):** read if auth; create if auth and `request.resource.data.actorId == request.auth.uid`.
- **Usage:**
  - **Create:** recordSwipe(actorId, targetId, action) — actor is current user.
  - **Read:** getSwipedTargetIds(actorId) — query `where('actorId', isEqualTo: actorId)` (current user). Future “who liked me” would read by targetId.
- **Change:** Restrict read to documents where the current user is actor or target (least privilege). That still allows:
  - Queries where `actorId == request.auth.uid` (only docs where user is actor).
  - Queries where `targetId == request.auth.uid` (only docs where user is target).
- **Rule applied:** `allow read: if request.auth != null && (resource.data.actorId == request.auth.uid || resource.data.targetId == request.auth.uid);`

---

## 5. `matches/{matchId}`

- **Rules:** create if auth and uid is user1Id or user2Id; read/update/delete if auth and uid is user1Id or user2Id.
- **Usage:** upsertMatchOnLike (set or update), rejectMatch (update), getMatchesForUser (query by user1Id/user2Id), createChatIfMatched (read then create chat). Doc ID = sorted `user1Id_user2Id`.
- **Verdict:** Correct. Only participants can create, read, or update matches.

---

## 6. `chats/{chatId}` and `chats/{chatId}/messages/{msgId}`

- **Rules:** create/read/update/delete chat if participant. Messages: read if participant; create only if participant **and** `users/$(request.auth.uid)` exists and `isStudentVerified == true`; update/delete false.
- **Usage:** createChatIfMatched (set chat), getChatsForUser (query by user1Id/user2Id), sendMessage (add message + update chat lastMessageAt/lastMessagePreview), watchMessages (stream). chatId = matchId.
- **Verdict:** Correct. Only participants can access a chat; only verified students can create messages. The `exists()` check avoids rule failure when the user doc is missing.

---

## 7. `verification_otps/{doc}`

- **Rules:** read, write: false.
- **Usage:** Vercel API (send-verification-otp.js, verify-university-email.js) uses Admin SDK. Client never reads or writes this collection.
- **Verdict:** Correct. Client has no access.

---

## 8. Auth UID vs document IDs

- Web auth: Clerk session is exchanged for a Firebase custom token; Firebase Auth UID is set to the Clerk user ID.
- Firestore `users/{userId}` uses the same ID (clerkId). So `request.auth.uid == userId` correctly identifies the profile owner. All rules that compare `request.auth.uid` to user1Id/user2Id/actorId are correct.

---

## 9. Composite queries

- **users:** Discovery uses `where('onboardingComplete', ...).where('isStudentVerified', ...).where('gender', whereIn: ...)`. Rules allow any authenticated read; query restricts results. ✅
- **swipes:** getSwipedTargetIds uses `where('actorId', isEqualTo: actorId)`. With the tightened rule, returned docs have actorId == auth.uid, so read is allowed. ✅
- **matches:** getMatchesForUser uses `Filter.or(user1Id, user2Id)`. Returned docs always have auth.uid as user1Id or user2Id. ✅
- **chats:** getChatsForUser uses two queries (user1Id, user2Id). Returned docs always have auth.uid as user1Id or user2Id. ✅

---

## 10. Rule change applied

- **File:** `firestore.rules`
- **Change:** Swipes read restricted from “any authenticated user” to “actor or target of the swipe document”:

```diff
-     allow read: if request.auth != null;
+     allow read: if request.auth != null
+       && (resource.data.actorId == request.auth.uid || resource.data.targetId == request.auth.uid);
```

This keeps all current app behavior (actor-based swipe list; future “who liked me” by targetId) while preventing arbitrary users from reading other users’ swipe records.

---

## Deploying rules

After editing `firestore.rules`:

```bash
firebase deploy --only firestore:rules
```

Ensure Firebase CLI is logged in and the project is correct (`firebase use`).
