import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../constants.dart';
import '../models/user_profile.dart';
import '../models/interest.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

// Theme inspired by reference: light background, orange-yellow accent.
const Color _kPageBg = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kTextPrimary = Color(0xFF2D2D2D);
const Color _kTextSecondary = Color(0xFF6B6B6B);
const Color _kTextMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFE0E0E0);
const Color _kAccent = Color(0xFFFF9800); // orange
const Color _kAccentLight = Color(0xFFFFB74D);
const int _kBioMaxLength = 500;
const int _kInterestsShowMoreThreshold = 12;

/// Strips HTML-like content to prevent XSS; safe to store and display in Flutter or HTML.
String _sanitizeForXSS(String s) {
  if (s.isEmpty) return s;
  String t = s.replaceAll(RegExp(r'<[^>]*>'), ''); // remove tag-like content
  t = t.replaceAll('<', '').replaceAll('>', '');   // remove any remaining angle brackets
  return t.trim();
}

class ProfileSetupScreen extends StatefulWidget {
  final String clerkId;
  final String email;
  final String fullName;
  final UserProfile? initialProfile;

  const ProfileSetupScreen({
    super.key,
    required this.clerkId,
    required this.email,
    required this.fullName,
    this.initialProfile,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirestoreService();
  final _storage = StorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  late final TextEditingController _instagramController;
  late final TextEditingController _snapchatController;
  late final TextEditingController _spotifyController;
  late final TextEditingController _interestSearchController;
  late final TextEditingController _ageController;

  int _age = 18;
  String _gender = kGenders.first;
  String _discoveryPreference = kDiscoveryPreferences[2];
  int _nameChangeCount = 0;
  int _genderChangeCount = 0;
  int _ageChangeCount = 0;
  final List<String> _profileImageUrls = [];
  final List<String> _selectedInterestIds = [];
  List<Interest> _interests = [];
  bool _loading = true;
  bool _saving = false;
  bool _interestsExpanded = false;
  /// Profile summary background. Null = default white.
  String? _selectedWallpaperUrl;

  bool get _isEdit => widget.initialProfile != null;

  int get _nameChangesLeft => kMaxNameGenderAgeChanges - _nameChangeCount;
  int get _genderChangesLeft => kMaxNameGenderAgeChanges - _genderChangeCount;
  int get _ageChangesLeft => kMaxNameGenderAgeChanges - _ageChangeCount;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p?.fullName ?? widget.fullName);
    _locationController = TextEditingController(text: p?.location ?? '');
    _bioController = TextEditingController(text: p?.bio ?? '');
    _instagramController = TextEditingController(text: p?.instagramHandle ?? '');
    _snapchatController = TextEditingController(text: p?.snapchatHandle ?? '');
    _spotifyController = TextEditingController(text: p?.spotifyPlaylistUrl ?? '');
    _interestSearchController = TextEditingController();
    if (p != null) {
      _age = p.age.clamp(1, 99);
      _gender = p.gender;
      _discoveryPreference = p.discoveryPreference;
      _nameChangeCount = p.nameChangeCount;
      _genderChangeCount = p.genderChangeCount;
      _ageChangeCount = p.ageChangeCount;
      _profileImageUrls.addAll(p.profileImageUrls);
      _selectedInterestIds.addAll(p.interestIds);
      _selectedWallpaperUrl = p.profileWallpaperUrl;
    }
    _ageController = TextEditingController(text: _age.toString());
    _loadInterests();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _snapchatController.dispose();
    _spotifyController.dispose();
    _interestSearchController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadInterests() async {
    final list = await _firestore.getInterests();
    if (mounted) setState(() {
      _interests = list;
      _loading = false;
    });
  }

  /// Returns true if the picked file looks like an image (MIME type).
  bool _isImageMimeType(XFile? xfile) {
    if (xfile == null) return false;
    final mime = xfile.mimeType?.toLowerCase();
    if (mime == null || mime.isEmpty) return true; // allow if unknown (e.g. desktop)
    return mime.startsWith('image/');
  }

  /// Verifies [bytes] decode as an image to reject non-image files.
  Future<bool> _isValidImageBytes(Uint8List bytes) async {
    try {
      await ui.instantiateImageCodec(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Picks, crops, compresses, then uploads as main profile picture (index 0).
  Future<void> _pickAndCropImageAsMainPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    if (!_isImageMimeType(xfile)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image file (e.g. JPG, PNG)')),
        );
      }
      return;
    }
    String? pathToUse = xfile.path;
    if (!kIsWeb) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: xfile.path,
        aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop'),
          IOSUiSettings(title: 'Crop'),
        ],
      );
      if (cropped == null) return;
      pathToUse = cropped.path;
    }
    Uint8List? bytes;
    if (kIsWeb) {
      bytes = await FlutterImageCompress.compressWithList(
        await xfile.readAsBytes(),
        format: CompressFormat.webp,
        quality: 70,
      );
    } else {
      bytes = await FlutterImageCompress.compressWithFile(
        pathToUse,
        format: CompressFormat.webp,
        quality: 70,
      );
    }
    if (bytes == null || bytes.isEmpty) return;
    final validImage = await _isValidImageBytes(bytes);
    if (!validImage) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected file is not a valid image. Please choose a JPG, PNG or similar.')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final url = await _storage.uploadProfileImage(
        widget.clerkId,
        0,
        bytes,
        contentType: 'image/webp',
      );
      setState(() {
        final cacheBusted = url.contains('?')
            ? '$url&_=${DateTime.now().millisecondsSinceEpoch}'
            : '$url?_=${DateTime.now().millisecondsSinceEpoch}';
        if (_profileImageUrls.isEmpty) {
          _profileImageUrls.add(cacheBusted);
        } else {
          _profileImageUrls[0] = cacheBusted;
        }
        _saving = false;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  /// Picks, crops, compresses, then uploads as additional photo (next index).
  Future<void> _pickAndCropImage() async {
    if (_profileImageUrls.length >= kMaxProfileImages) return;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
    if (!_isImageMimeType(xfile)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image file (e.g. JPG, PNG)')),
        );
      }
      return;
    }
    String? pathToUse = xfile.path;
    if (!kIsWeb) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: xfile.path,
        aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop'),
          IOSUiSettings(title: 'Crop'),
        ],
      );
      if (cropped == null) return;
      pathToUse = cropped.path;
    }
    Uint8List? bytes;
    if (kIsWeb) {
      bytes = await FlutterImageCompress.compressWithList(
        await xfile.readAsBytes(),
        format: CompressFormat.webp,
        quality: 70,
      );
    } else {
      bytes = await FlutterImageCompress.compressWithFile(
        pathToUse,
        format: CompressFormat.webp,
        quality: 70,
      );
    }
    if (bytes == null || bytes.isEmpty) return;
    final validImage = await _isValidImageBytes(bytes);
    if (!validImage) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected file is not a valid image. Please choose a JPG, PNG or similar.')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final index = _profileImageUrls.length;
      final url = await _storage.uploadProfileImage(
        widget.clerkId,
        index,
        bytes,
        contentType: 'image/webp',
      );
      setState(() {
        _profileImageUrls.add(url);
        _saving = false;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  void _removeImage(int index) {
    setState(() => _profileImageUrls.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _profileImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one profile image')),
      );
      return;
    }
    setState(() => _saving = true);
    final name = _sanitizeForXSS(_nameController.text.trim());
    final location = _sanitizeForXSS(_locationController.text.trim());
    final bio = _sanitizeForXSS(_bioController.text.trim());
    final instagram = _sanitizeForXSS(_instagramController.text.trim());
    final snapchat = _sanitizeForXSS(_snapchatController.text.trim());
    final spotify = _sanitizeForXSS(_spotifyController.text.trim());
    final ageRaw = int.tryParse(_ageController.text.trim());
    final age = ageRaw != null ? ageRaw.clamp(1, 99) : _age;
    try {
      final now = DateTime.now();
      if (_isEdit) {
        final p = widget.initialProfile!;
        final update = <String, dynamic>{
          'discoveryPreference': _discoveryPreference,
          'location': location,
          'bio': bio.isEmpty ? null : bio,
          'profileImageUrls': _profileImageUrls.map((u) => u.split('?').first).toList(),
          'interestIds': _selectedInterestIds,
          'instagramHandle': instagram.isEmpty ? null : instagram,
          'snapchatHandle': snapchat.isEmpty ? null : snapchat,
          'spotifyPlaylistUrl': spotify.isEmpty ? null : spotify,
          'profileWallpaperUrl': _selectedWallpaperUrl,
        };
        final newName = name.isEmpty ? p.fullName : name;
        if (_nameChangeCount >= kMaxNameGenderAgeChanges) {
          update['fullName'] = p.fullName;
        } else if (newName != p.fullName) {
          update['fullName'] = newName;
          update['nameChangeCount'] = _nameChangeCount + 1;
        } else {
          update['fullName'] = newName;
        }
        if (_genderChangeCount >= kMaxNameGenderAgeChanges) {
          update['gender'] = p.gender;
        } else if (_gender != p.gender) {
          update['gender'] = _gender;
          update['genderChangeCount'] = _genderChangeCount + 1;
        } else {
          update['gender'] = p.gender;
        }
        if (_ageChangeCount >= kMaxNameGenderAgeChanges) {
          update['age'] = p.age;
        } else if (age != p.age) {
          update['age'] = age;
          update['ageChangeCount'] = _ageChangeCount + 1;
        } else {
          update['age'] = age;
        }
        await _firestore.updateUserProfile(widget.clerkId, update);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final deadline = now.add(Duration(hours: kVerificationGraceHours));
        final profile = UserProfile(
          clerkId: widget.clerkId,
          email: widget.email,
          fullName: name.isEmpty ? widget.fullName : name,
          age: age,
          gender: _gender,
          discoveryPreference: _discoveryPreference,
          location: location,
          bio: bio.isEmpty ? null : bio,
          profileImageUrls: _profileImageUrls.map((u) => u.split('?').first).toList(),
          interestIds: _selectedInterestIds,
          instagramHandle: instagram.isEmpty ? null : instagram,
          snapchatHandle: snapchat.isEmpty ? null : snapchat,
          spotifyPlaylistUrl: spotify.isEmpty ? null : spotify,
          profileWallpaperUrl: _selectedWallpaperUrl,
          isStudentVerified: false,
          verificationDeadlineAt: deadline,
          suspendedAt: null,
          swipeCount: 0,
          createdAt: now,
          updatedAt: now,
          onboardingComplete: true,
        );
        await _firestore.setUserProfile(profile);
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/app', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Interest> get _filteredInterests {
    final q = _interestSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return _interests;
    return _interests.where((i) => i.label.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _kPageBg,
        body: Center(child: CircularProgressIndicator(color: _kAccent)),
      );
    }
    return Scaffold(
      backgroundColor: _kPageBg,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        foregroundColor: _kTextPrimary,
        title: Text('Profile setup', style: TextStyle(color: _kTextPrimary, fontSize: 18)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 24),
              _buildAboutYouSection(),
              const SizedBox(height: 24),
              _buildSocialSection(),
              const SizedBox(height: 24),
              _buildWallpaperSection(),
              const SizedBox(height: 24),
              _buildInterestsCard(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    final hasMain = _profileImageUrls.isNotEmpty;
    return Column(
      children: [
        Center(
          child: ClipOval(
            child: SizedBox(
              width: 140,
              height: 140,
              child: hasMain
                  ? Image.network(_profileImageUrls.first, fit: BoxFit.cover)
                  : Container(
                      color: _kBorder,
                      child: Icon(Icons.person, size: 64, color: _kTextMuted),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _pickAndCropImageAsMainPhoto,
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
            label: const Text('Add Main Photo'),
            style: FilledButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Additional Photos',
            style: TextStyle(color: _kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        if (_profileImageUrls.length > 1)
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(_profileImageUrls.length - 1, (i) {
                final idx = i + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _profileImageUrls[idx],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(idx),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey.shade700,
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        if (_profileImageUrls.length > 1) const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickAndCropImage,
          icon: Icon(Icons.add, size: 20, color: _kTextSecondary),
          label: Text('Add More Photos', style: TextStyle(color: _kTextSecondary)),
          style: OutlinedButton.styleFrom(
            backgroundColor: _kCardBg,
            side: const BorderSide(color: _kBorder),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Add up to 5 photos to increase your chances of matching!',
          style: TextStyle(color: _kTextMuted, fontSize: 13),
        ),
      ],
    );
  }

  String _changesLeftTagline(int left) {
    if (left <= 0) return 'No changes left';
    return '$left ${left == 1 ? 'change' : 'changes'} left';
  }

  Widget _buildAboutYouSection() {
    final birthYear = DateTime.now().year - _age;
    final genderLabel = _gender.replaceAll('_', ' ');
    final nameLocked = _isEdit && _nameChangesLeft <= 0;
    final genderLocked = _isEdit && _genderChangesLeft <= 0;
    final ageLocked = _isEdit && _ageChangesLeft <= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About You',
            style: TextStyle(color: _kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _labeledField(
                  'Name',
                  nameLocked
                      ? TextFormField(
                          controller: _nameController,
                          readOnly: true,
                          decoration: _inputDecoration(),
                          style: TextStyle(color: _kTextPrimary),
                        )
                      : TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration(),
                          style: TextStyle(color: _kTextPrimary),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_changesLeftTagline(_nameChangesLeft), style: TextStyle(color: _kTextMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _labeledReadOnly('Gender', genderLabel, genderLocked ? 'No changes left' : _changesLeftTagline(_genderChangesLeft)),
              ),
              if (!genderLocked)
                TextButton(
                  onPressed: _showGenderPicker,
                  child: Text('Change', style: TextStyle(color: _kAccent)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _labeledField(
                  'Age',
                  ageLocked
                      ? TextFormField(
                          controller: _ageController,
                          readOnly: true,
                          decoration: _inputDecoration(),
                          style: TextStyle(color: _kTextPrimary),
                          keyboardType: TextInputType.number,
                        )
                      : TextFormField(
                          controller: _ageController,
                          decoration: _inputDecoration(hint: '1–99'),
                          style: TextStyle(color: _kTextPrimary),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter age';
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 1 || n > 99) return 'Age must be 1–99';
                            return null;
                          },
                          onChanged: (v) {
                            final n = int.tryParse(v.trim());
                            if (n != null && n >= 1 && n <= 99) setState(() => _age = n);
                          },
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Text(_changesLeftTagline(_ageChangesLeft), style: TextStyle(color: _kTextMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Date of Birth: 1/1/$birthYear', style: TextStyle(color: _kTextMuted, fontSize: 12)),
          const SizedBox(height: 16),
          _labeledField('City', TextFormField(
            controller: _locationController,
            decoration: _inputDecoration(hint: 'e.g. Noida'),
            style: TextStyle(color: _kTextPrimary),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter city' : null,
          )),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bio', style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      maxLength: _kBioMaxLength,
                      decoration: _inputDecoration(hint: 'Nothing to describe about me yet.')
                          .copyWith(
                            suffixIcon: Icon(Icons.edit, size: 18, color: _kTextMuted),
                            counterText: '${_bioController.text.length}/$_kBioMaxLength',
                            counterStyle: TextStyle(color: _kTextMuted, fontSize: 12),
                          ),
                      style: TextStyle(color: _kTextPrimary),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Show me', style: TextStyle(color: _kTextSecondary)),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: kDiscoveryPreferences.map((g) {
              final selected = _discoveryPreference == g;
              return ChoiceChip(
                label: Text(g),
                selected: selected,
                onSelected: (v) => setState(() => _discoveryPreference = g),
                selectedColor: _kAccentLight,
                labelStyle: TextStyle(color: selected ? Colors.white : _kTextPrimary),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: kGenders.map((g) {
            return ListTile(
              title: Text(g.replaceAll('_', ' ')),
              selected: _gender == g,
              onTap: () {
                setState(() => _gender = g);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _labeledReadOnly(String label, String value, String helper) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: _kTextPrimary)),
        const SizedBox(height: 4),
        Text(helper, style: TextStyle(color: _kTextMuted, fontSize: 12)),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _kTextMuted),
      filled: true,
      fillColor: _kCardBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 20, color: _kTextPrimary),
              const SizedBox(width: 8),
              Text(
                'Social Media',
                style: TextStyle(color: _kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Add your social media profiles to connect with matches',
            style: TextStyle(color: _kTextMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _instagramController,
            decoration: _inputDecoration(hint: 'Instagram Username').copyWith(labelText: 'Instagram Username'),
            style: TextStyle(color: _kTextPrimary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _snapchatController,
            decoration: _inputDecoration(hint: 'Snapchat Username').copyWith(labelText: 'Snapchat Username'),
            style: TextStyle(color: _kTextPrimary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _spotifyController,
            decoration: _inputDecoration(hint: 'https://open.spotify.com/...').copyWith(labelText: 'Spotify Profile/Playlist'),
            style: TextStyle(color: _kTextPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Paste your Spotify profile or playlist URL here',
            style: TextStyle(color: _kTextMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile background',
            style: TextStyle(color: _kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a background for your profile summary. Others will see it when they view your profile.',
            style: TextStyle(color: _kTextMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 112,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Default (white)
                _WallpaperTile(
                  label: 'Default',
                  isSelected: _selectedWallpaperUrl == null,
                  onTap: () => setState(() => _selectedWallpaperUrl = null),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Icon(Icons.wb_sunny_outlined, color: _kTextMuted, size: 28),
                  ),
                ),
                ...kProfileWallpaperOptions.whereType<String>().map((url) {
                  final selected = _selectedWallpaperUrl == url;
                  return _WallpaperTile(
                    label: null,
                    isSelected: selected,
                    onTap: () => setState(() => _selectedWallpaperUrl = url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsCard() {
    final filtered = _filteredInterests;
    final showCount = _interestsExpanded ? filtered.length : filtered.length.clamp(0, _kInterestsShowMoreThreshold);
    final displayList = filtered.take(showCount).toList();
    final hasMore = filtered.length > _kInterestsShowMoreThreshold && !_interestsExpanded;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Interests',
            style: TextStyle(color: _kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Select hobbies that best describe you',
            style: TextStyle(color: _kTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _interestSearchController,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration(hint: 'Search hobbies...'),
            style: TextStyle(color: _kTextPrimary),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 3;
              const spacing = 8.0;
              final maxW = constraints.maxWidth;
              final itemWidth = maxW.isFinite && maxW > 0
                  ? (maxW - (crossAxisCount - 1) * spacing) / crossAxisCount
                  : 100.0;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  ...displayList.map((i) {
                    final selected = _selectedInterestIds.contains(i.id);
                    return SizedBox(
                      width: itemWidth,
                      child: FilterChip(
                        label: Text(i.label, overflow: TextOverflow.ellipsis),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) _selectedInterestIds.add(i.id);
                            else _selectedInterestIds.remove(i.id);
                          });
                        },
                        selectedColor: _kAccent,
                        backgroundColor: const Color(0xFFF5F5F5),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : _kTextPrimary,
                          fontSize: 13,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          if (hasMore) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _interestsExpanded = true),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _kTextSecondary, style: BorderStyle.solid),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Show More Hobbies', style: TextStyle(color: _kTextPrimary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text('SAVE PROFILE'),
      ),
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _WallpaperTile({
    this.label,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                child,
                if (isSelected)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: _kAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  ),
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kAccent, width: 3),
                      ),
                    ),
                  ),
              ],
            ),
            if (label != null) ...[
              const SizedBox(height: 6),
              Text(
                label!,
                style: TextStyle(color: _kTextSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
