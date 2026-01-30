const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { verifyToken } = require('@clerk/backend');

admin.initializeApp();

/**
 * Exchanges Clerk session token for Firebase custom token.
 * Flutter calls this after Clerk sign-in; then signs in to Firebase with the returned token.
 * Set CLERK_SECRET_KEY in Firebase config. Optionally set authorizedParties to your app origin.
 */
exports.getCustomToken = functions.https.onCall(async (data, context) => {
  const clerkToken = data?.token;
  if (!clerkToken || typeof clerkToken !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing token');
  }
  const secretKey = process.env.CLERK_SECRET_KEY;
  if (!secretKey) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'CLERK_SECRET_KEY not configured'
    );
  }
  try {
    const result = await verifyToken(clerkToken, {
      secretKey,
      authorizedParties: process.env.CLERK_AUTHORIZED_PARTIES
        ? process.env.CLERK_AUTHORIZED_PARTIES.split(',')
        : ['http://localhost', 'https://localhost'],
    });
    const payload = result.data ?? result;
    const clerkUserId = payload?.sub;
    if (!clerkUserId) {
      throw new Error('No sub in token');
    }
    const customToken = await admin.auth().createCustomToken(clerkUserId);
    return { token: customToken };
  } catch (e) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Invalid Clerk token'
    );
  }
});

/**
 * Sends OTP to university email via Brevo. Set BREVO_API_KEY in config.
 */
exports.sendVerificationOtp = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Not signed in');
  }
  const email = data?.email;
  if (!email || typeof email !== 'string' || !email.endsWith('@lpu.in')) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Valid @lpu.in email required'
    );
  }
  const otp = String(Math.floor(100000 + Math.random() * 900000));
  const db = admin.firestore();
  await db.collection('verification_otps').doc(context.auth.uid).set({
    email,
    otp,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 10 * 60 * 1000),
  });
  const apiKey = process.env.BREVO_API_KEY;
  if (!apiKey) {
    console.warn('BREVO_API_KEY not set; OTP not sent:', otp);
    return { ok: true };
  }
  const res = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'accept': 'application/json',
      'content-type': 'application/json',
      'api-key': apiKey,
    },
    body: JSON.stringify({
      sender: { name: 'UniDate', email: 'noreply@unidate.app' },
      to: [{ email }],
      subject: 'UniDate – Your verification code',
      htmlContent: `<p>Your code is: <strong>${otp}</strong>. It expires in 10 minutes.</p>`,
    }),
  });
  if (!res.ok) {
    throw new functions.https.HttpsError('internal', 'Failed to send email');
  }
  return { ok: true };
});

/**
 * Verifies OTP and sets isStudentVerified on user profile.
 */
exports.verifyUniversityEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Not signed in');
  }
  const otp = data?.otp;
  if (!otp || typeof otp !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing OTP');
  }
  const db = admin.firestore();
  const ref = db.collection('verification_otps').doc(context.auth.uid);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError('not-found', 'No OTP sent');
  }
  const d = snap.data();
  if (d.otp !== otp) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid OTP');
  }
  const expiresAt = d.expiresAt?.toDate?.() || new Date(0);
  if (new Date() > expiresAt) {
    await ref.delete();
    throw new functions.https.HttpsError('failed-precondition', 'OTP expired');
  }
  await ref.delete();
  await db.collection('users').doc(context.auth.uid).update({
    isStudentVerified: true,
    universityEmail: d.email,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
