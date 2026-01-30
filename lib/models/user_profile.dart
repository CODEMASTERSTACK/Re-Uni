import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile stored in Firestore `users/{clerkId}`.
/// Clerk holds auth; this holds app profile and state.
class UserProfile {
  final String clerkId;
  final String email;
  final String fullName;
  final int age;
  final String gender; // male | female | non_binary | other
  final String discoveryPreference; // men | women | everyone | non_binary
  final String location;
  final List<String> profileImageUrls;
  final List<String> interestIds;
  final String? instagramHandle;
  final String? snapchatHandle;
  final String? spotifyPlaylistUrl;
  final bool isStudentVerified;
  final String? universityEmail;
  final DateTime? verificationDeadlineAt;
  final DateTime? suspendedAt;
  final int swipeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool onboardingComplete;

  const UserProfile({
    required this.clerkId,
    required this.email,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.discoveryPreference,
    required this.location,
    required this.profileImageUrls,
    required this.interestIds,
    this.instagramHandle,
    this.snapchatHandle,
    this.spotifyPlaylistUrl,
    this.isStudentVerified = false,
    this.universityEmail,
    this.verificationDeadlineAt,
    this.suspendedAt,
    this.swipeCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.onboardingComplete = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'clerkId': clerkId,
      'email': email,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'discoveryPreference': discoveryPreference,
      'location': location,
      'profileImageUrls': profileImageUrls,
      'interestIds': interestIds,
      if (instagramHandle != null) 'instagramHandle': instagramHandle,
      if (snapchatHandle != null) 'snapchatHandle': snapchatHandle,
      if (spotifyPlaylistUrl != null) 'spotifyPlaylistUrl': spotifyPlaylistUrl,
      'isStudentVerified': isStudentVerified,
      if (universityEmail != null) 'universityEmail': universityEmail,
      if (verificationDeadlineAt != null)
        'verificationDeadlineAt': Timestamp.fromDate(verificationDeadlineAt!),
      if (suspendedAt != null) 'suspendedAt': Timestamp.fromDate(suspendedAt!),
      'swipeCount': swipeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'onboardingComplete': onboardingComplete,
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      clerkId: map['clerkId'] as String? ?? id,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      gender: map['gender'] as String? ?? 'other',
      discoveryPreference: map['discoveryPreference'] as String? ?? 'everyone',
      location: map['location'] as String? ?? '',
      profileImageUrls:
          List<String>.from(map['profileImageUrls'] as List<dynamic>? ?? []),
      interestIds:
          List<String>.from(map['interestIds'] as List<dynamic>? ?? []),
      instagramHandle: map['instagramHandle'] as String?,
      snapchatHandle: map['snapchatHandle'] as String?,
      spotifyPlaylistUrl: map['spotifyPlaylistUrl'] as String?,
      isStudentVerified: map['isStudentVerified'] as bool? ?? false,
      universityEmail: map['universityEmail'] as String?,
      verificationDeadlineAt: (map['verificationDeadlineAt'] as Timestamp?)
          ?.toDate(),
      suspendedAt: (map['suspendedAt'] as Timestamp?)?.toDate(),
      swipeCount: (map['swipeCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
    );
  }

  UserProfile copyWith({
    String? email,
    String? fullName,
    int? age,
    String? gender,
    String? discoveryPreference,
    String? location,
    List<String>? profileImageUrls,
    List<String>? interestIds,
    String? instagramHandle,
    String? snapchatHandle,
    String? spotifyPlaylistUrl,
    bool? isStudentVerified,
    String? universityEmail,
    DateTime? verificationDeadlineAt,
    DateTime? suspendedAt,
    int? swipeCount,
    DateTime? updatedAt,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      clerkId: clerkId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      discoveryPreference: discoveryPreference ?? this.discoveryPreference,
      location: location ?? this.location,
      profileImageUrls: profileImageUrls ?? this.profileImageUrls,
      interestIds: interestIds ?? this.interestIds,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      snapchatHandle: snapchatHandle ?? this.snapchatHandle,
      spotifyPlaylistUrl: spotifyPlaylistUrl ?? this.spotifyPlaylistUrl,
      isStudentVerified: isStudentVerified ?? this.isStudentVerified,
      universityEmail: universityEmail ?? this.universityEmail,
      verificationDeadlineAt:
          verificationDeadlineAt ?? this.verificationDeadlineAt,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      swipeCount: swipeCount ?? this.swipeCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  bool get isSuspended =>
      suspendedAt != null || (!isStudentVerified && verificationDeadlineAt != null && DateTime.now().isAfter(verificationDeadlineAt!));
}
