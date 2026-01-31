# UniDate — System Architecture & Design Document

## 1. Introduction

UniDate is a university-focused dating web application built using Flutter Web, designed to connect verified students in a secure, high-performance environment. The platform enforces institutional email verification, optimized media handling, and interest-based profile discovery to ensure authenticity and relevance.

This document describes the end-to-end system architecture, including user flows, core modules, data design, technology stack, and key implementation decisions.

---

## 2. High-Level Application Flow

### 2.1 Entry Point

* The application launches on a Landing Page implemented in `main.dart`.
* Users are presented with two options:

  * Create Account
  * Log In

---

## 3. Authentication & User Onboarding

### 3.1 New User Registration Flow

1. User selects Create Account

2. User is redirected to the registration screen

3. Required details:

   * Full Name
   * Age
   * Gender
   * Email ID
   * Password

4. Authentication and session management are handled by Clerk

5. A verification code is sent to the user’s email by Clerk

6. User enters the verification code to confirm email ownership

7. Upon successful verification, the user is redirected to Profile Setup

---

### 3.2 Profile Setup

#### Profile Picture Upload

* Users can upload up to 5 profile images
* Client-side image enforcement includes:

  * Mandatory cropping to a 4:5 aspect ratio
  * Compression before upload
  * Conversion to WebP format
* Images are uploaded to Cloudflare R2
* After successful upload, the user is redirected to the Profile Summary Page

---

### 3.3 Existing User Login

* Existing users authenticate using Clerk
* Upon successful login, users are redirected directly to the Profile Summary Page

---

## 4. Core Application Structure

The application consists of four primary screens, accessible via a persistent bottom navigation bar:

1. Profile Summary
2. Swipe
3. Matches
4. Chat

---

## 5. Screen-Level Architecture

### 5.1 Profile Summary Page (Home Screen)

This is the primary landing screen after authentication.

Displays:

* Profile images
* Gender and age
* Location
* Interests and hobbies
* Swipe count
* Linked social media handles:

  * Instagram
  * Snapchat
  * Spotify playlist
* Student verification status

#### Profile Editing

Users can:

* Upload or remove profile images (up to 5)
* Update interests and hobbies
* Edit location
* Add or update social media handles

---

### 5.2 Swipe Page

* Displays user profiles in a card-based swipe interface
* Swipe actions:

  * Right Swipe → Like
  * Left Swipe → Dislike
* Each profile card displays:

  * Profile image
  * Age
  * Gender
  * Up to 4–5 interests
* Swipe behavior and UI follow Tinder-style interactions

---

### 5.3 Matches Screen

* Displays users who have liked the current user

User actions:

Accept:

* A mutual match is created
* Both users are notified
* Chat functionality becomes available

Reject:

* The profile is permanently removed from the matches list
* No further interaction is allowed

---

### 5.4 Chat Screen

* Displays all active conversations
* Chat is enabled only after a successful mutual match
* Each chat corresponds to exactly one match

---

## 6. Profile Discovery Algorithm

Profiles are shown to users based on the following priority rules:

1. Interest Matching: Profiles with at least one shared interest are prioritized
2. Fallback Randomization: If no interest-matched profiles are available, random profiles are shown
3. Gender-Based Filtering:


   * Male users are shown female profiles
   * Female users are shown male profiles

Matching logic is implemented at the application or query layer.

---

## 7. Technology Stack

Frontend: Flutter Web
Authentication: Clerk
Database: Firebase
Image Storage: Cloudflare R2
Email & OTP: Brevo Transactional API

---

## 8. Backend & Data Architecture

### 8.1 Firebase

Stores:

* User accounts and profiles
* Interests and preferences
* Swipe actions
* Matches
* Chat metadata

Optimization Strategy:

* Profiles are fetched in batches of 20
* Stored in a Flutter-managed list
* Reduces network overhead while maintaining responsive UI

---

### 8.2 Cloudflare R2

* Used for storing profile images
* Client-side enforcement:

  * Fixed aspect ratio cropping
  * Compression before upload

Packages used:

* image_picker
* image_cropper
* flutter_image_compress

Target optimization:

* Format: WebP
* Quality: ~70%
* Average size: ~50KB per image

---

## 9. Performance Optimization

### 9.1 Rendering

* CanvasKit renderer is enabled in `index.html`
* Ensures smooth swipe animations at ~60fps
* Avoids performance issues seen with the HTML renderer

### 9.2 Image Pre-caching

* Uses Flutter’s precacheImage
* While one profile is viewed, the next profile image is preloaded
* Eliminates visible loading delays

---

## 10. Student Verification System

### 10.1 Verification Policy

* Initial signup uses a personal email via Clerk
* Users must verify a valid @lpu.in email to confirm student status

---

### 10.2 Verification Flow

1. User adds university email
2. A secure 6-digit OTP is generated
3. OTP is sent via Brevo Transactional Email API
4. User submits OTP for verification

---

### 10.3 Access Enforcement

* A 72-hour grace period is granted after account creation
* Verification deadlines are tracked using server timestamps
* If is_student_verified is false after 72 hours:

  * Account access is automatically suspended
* Access is restored immediately after successful verification

---

## 11. Security & Integrity Notes

* Swipe actions are uniquely constrained per user pair
* Matches are explicitly stored to avoid inferred relationships
* Media uploads are sanitized and compressed client-side

---

## 12. Conclusion

UniDate’s architecture prioritizes authenticated users, performance-optimized UI, and clean separation of concerns across authentication, profile management, discovery, and messaging. The system is suitable for MVP deployment and scalable for future enhancements such as advanced matching, moderation, and analytics.
