import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../navigation/app_shell_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uidController = TextEditingController();
  final _gameNameController = TextEditingController();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isFormReady =>
      _uidController.text.trim().length >= 7 &&
      _uidController.text.trim().length <= 10 &&
      _gameNameController.text.trim().length >= 3;

  @override
  void initState() {
    super.initState();
    _uidController.addListener(_handleInputChanged);
    _gameNameController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _uidController.removeListener(_handleInputChanged);
    _gameNameController.removeListener(_handleInputChanged);
    _uidController.dispose();
    _gameNameController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        CroppedFile? cropped;
        try {
          cropped = await ImageCropper().cropImage(
            sourcePath: picked.path,
            compressFormat: ImageCompressFormat.jpg,
            compressQuality: 90,
            uiSettings: [
              AndroidUiSettings(
                toolbarTitle: 'Crop Profile Image',
                toolbarColor: Colors.black,
                toolbarWidgetColor: Colors.white,
                hideBottomControls: true,
                lockAspectRatio: true,
                aspectRatioPresets: [CropAspectRatioPreset.square],
              ),
              IOSUiSettings(
                title: 'Crop Profile Image',
                aspectRatioLockEnabled: true,
              ),
            ],
          );
        } catch (_) {
          // Fallback: continue with original selected image if crop fails.
        }

        final selected = XFile(cropped?.path ?? picked.path);
        final bytes = await selected.readAsBytes();
        setState(() {
          _selectedImage = selected;
          _selectedImageBytes = bytes;
        });
        if (cropped == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Crop failed. Using original image instead.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final userProvider = context.read<UserProvider>();
    setState(() => _isUploading = true);

    try {
      // Upload avatar if selected
      if (_selectedImage != null) {
        final result = await ApiService.uploadAvatar(
          imagePath: kIsWeb ? null : _selectedImage!.path,
          imageBytes: _selectedImageBytes,
          filename: _selectedImage!.name,
        );
        if (result['error'] != null) {
          throw Exception(result['error']);
        }
      }

      final setupRes = await ApiService.completeProfileSetup(
        gameName: 'Free Fire',
        gameId: _uidController.text.trim(),
        inGameName: _gameNameController.text.trim(),
      );
      if (setupRes['error'] != null) {
        throw Exception(setupRes['error'].toString());
      }

      if (!mounted) return;
      await userProvider.loadProfile();

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Profile Setup Complete'),
            content: const Text(
              'Welcome! Your setup is complete. Enjoy and play game.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppShellScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Setup failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon, color: Colors.grey[700]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.yellow[700]!, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.grey[700]),
      hintStyle: TextStyle(color: Colors.grey[400]),
      helperStyle: TextStyle(color: Colors.grey[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = screenWidth > 700 ? 560.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Complete Profile',
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.yellow[50]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.yellow[100],
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          'Step 2 of 2',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange[800],
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Almost there',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Set up your player profile',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add your UID and in-game name so we can match you correctly in rooms and tournaments.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Column(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        width: 122,
                                        height: 122,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: _selectedImage != null
                                                ? [
                                                    Colors.yellow[200]!,
                                                    Colors.orange[200]!,
                                                  ]
                                                : [
                                                    Colors.white,
                                                    Colors.grey[100]!,
                                                  ],
                                          ),
                                          border: Border.all(
                                            color: _selectedImage != null
                                                ? Colors.yellow[700]!
                                                : Colors.grey[300]!,
                                            width: 2.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 14,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                          image: _selectedImage != null
                                              ? DecorationImage(
                                                  image: MemoryImage(
                                                    _selectedImageBytes!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: _selectedImage == null
                                            ? Icon(
                                                Icons.person_outline,
                                                size: 62,
                                                color: Colors.grey[700],
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            customBorder: const CircleBorder(),
                                            onTap: _pickImage,
                                            child: Ink(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: Colors.yellow[700],
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedImage != null
                                        ? 'Profile photo selected'
                                        : 'Add profile photo (optional)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap the camera icon to update',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.asset(
                                        'assets/freefire.jpg',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                Icons.sports_esports,
                                                size: 36,
                                                color: Colors.orange[700],
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Selected Game',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Free Fire',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[900],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Use the same UID and nickname as your game account',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Player Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'These details help verify match entries and payouts.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _uidController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: _inputDecoration(
                                      label: 'Free Fire UID',
                                      hint: 'Enter your game UID',
                                      icon: Icons.badge_outlined,
                                      helper:
                                          'Numbers only (7 to 10 digits)',
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'UID is required';
                                      }
                                      if (!RegExp(r'^\d{7,10}$').hasMatch(text)) {
                                        return 'Enter valid 7-10 digit UID';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _gameNameController,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: _inputDecoration(
                                      label: 'In-Game Name',
                                      hint: 'Enter your nickname',
                                      icon: Icons.person_outline,
                                      helper:
                                          'This should match your Free Fire profile',
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return 'Game name is required';
                                      }
                                      if (text.length < 3) {
                                        return 'Name must be at least 3 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: (_isFormReady && !_isUploading)
                                  ? _submit
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[700],
                                disabledBackgroundColor: Colors.grey[300],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can update these details later from your profile settings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

