import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../constants.dart';
import '../models/user_profile.dart';
import '../models/interest.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String clerkId;
  final String email;
  final String fullName;
  /// When non-null, we're editing: load values and on save update and pop.
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
  final _auth = AuthService();

  int _age = 18;
  String _gender = kGenders.first;
  String _discoveryPreference = kDiscoveryPreferences[2]; // everyone
  String _location = '';
  final List<String> _profileImageUrls = [];
  final List<String> _selectedInterestIds = [];
  String? _instagramHandle;
  String? _snapchatHandle;
  String? _spotifyPlaylistUrl;

  List<Interest> _interests = [];
  bool _loading = true;
  bool _saving = false;

  bool get _isEdit => widget.initialProfile != null;

  @override
  void initState() {
    super.initState();
    _loadInterests();
    final p = widget.initialProfile;
    if (p != null) {
      _age = p.age;
      _gender = p.gender;
      _discoveryPreference = p.discoveryPreference;
      _location = p.location;
      _profileImageUrls.addAll(p.profileImageUrls);
      _selectedInterestIds.addAll(p.interestIds);
      _instagramHandle = p.instagramHandle;
      _snapchatHandle = p.snapchatHandle;
      _spotifyPlaylistUrl = p.spotifyPlaylistUrl;
    }
  }

  Future<void> _loadInterests() async {
    final list = await _firestore.getInterests();
    setState(() {
      _interests = list;
      _loading = false;
    });
  }

  Future<void> _pickAndCropImage() async {
    if (_profileImageUrls.length >= kMaxProfileImages) return;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;
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
    } else if (pathToUse != null) {
      bytes = await FlutterImageCompress.compressWithFile(
        pathToUse,
        format: CompressFormat.webp,
        quality: 70,
      );
    }
    if (bytes == null || bytes.isEmpty) return;
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
    try {
      final now = DateTime.now();
      if (_isEdit) {
        await _firestore.updateUserProfile(widget.clerkId, {
          'age': _age,
          'gender': _gender,
          'discoveryPreference': _discoveryPreference,
          'location': _location,
          'profileImageUrls': _profileImageUrls,
          'interestIds': _selectedInterestIds,
          'instagramHandle': _instagramHandle?.isEmpty == true ? null : _instagramHandle,
          'snapchatHandle': _snapchatHandle?.isEmpty == true ? null : _snapchatHandle,
          'spotifyPlaylistUrl': _spotifyPlaylistUrl?.isEmpty == true ? null : _spotifyPlaylistUrl,
        });
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final deadline = now.add(Duration(hours: kVerificationGraceHours));
        final profile = UserProfile(
          clerkId: widget.clerkId,
          email: widget.email,
          fullName: widget.fullName,
          age: _age,
          gender: _gender,
          discoveryPreference: _discoveryPreference,
          location: _location,
          profileImageUrls: _profileImageUrls,
          interestIds: _selectedInterestIds,
          instagramHandle: _instagramHandle?.isEmpty == true ? null : _instagramHandle,
          snapchatHandle: _snapchatHandle?.isEmpty == true ? null : _snapchatHandle,
          spotifyPlaylistUrl: _spotifyPlaylistUrl?.isEmpty == true ? null : _spotifyPlaylistUrl,
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF4458))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile setup', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Profile photos (4:5 ratio, up to 5)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (int i = 0; i < _profileImageUrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _profileImageUrls[i],
                                width: 90,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                onPressed: () => _removeImage(i),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_profileImageUrls.length < kMaxProfileImages)
                      GestureDetector(
                        onTap: _saving ? null : _pickAndCropImage,
                        child: Container(
                          width: 90,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: _saving
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(color: Color(0xFFFF4458)),
                                )
                              : const Icon(Icons.add, color: Colors.white54, size: 32),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Age', style: TextStyle(color: Colors.white70)),
              Slider(
                value: _age.toDouble(),
                min: 18,
                max: 100,
                divisions: 82,
                activeColor: const Color(0xFFFF4458),
                onChanged: (v) => setState(() => _age = v.toInt()),
              ),
              Text('$_age', style: const TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 16),
              const Text('Gender', style: TextStyle(color: Colors.white70)),
              Wrap(
                spacing: 8,
                children: kGenders.map((g) {
                  final selected = _gender == g;
                  return ChoiceChip(
                    label: Text(g.replaceAll('_', ' ')),
                    selected: selected,
                    onSelected: (v) => setState(() => _gender = g),
                    selectedColor: const Color(0xFFFF4458),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Show me', style: TextStyle(color: Colors.white70)),
              Wrap(
                spacing: 8,
                children: kDiscoveryPreferences.map((p) {
                  final selected = _discoveryPreference == p;
                  return ChoiceChip(
                    label: Text(p),
                    selected: selected,
                    onSelected: (v) => setState(() => _discoveryPreference = p),
                    selectedColor: const Color(0xFFFF4458),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Location (city/campus)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                style: const TextStyle(color: Colors.white),
                initialValue: _location,
                onChanged: (v) => _location = v,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter location' : null,
              ),
              const SizedBox(height: 16),
              const Text('Interests', style: TextStyle(color: Colors.white70)),
              Wrap(
                spacing: 8,
                children: _interests.map((i) {
                  final selected = _selectedInterestIds.contains(i.id);
                  return FilterChip(
                    label: Text(i.label),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) _selectedInterestIds.add(i.id);
                        else _selectedInterestIds.remove(i.id);
                      });
                    },
                    selectedColor: const Color(0xFFFF4458),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Instagram (optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => _instagramHandle = v,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Snapchat (optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => _snapchatHandle = v,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Spotify playlist URL (optional)',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => _spotifyPlaylistUrl = v,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4458),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save and continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
