
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'login.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeTerms = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Controllers (names unchanged) ──────────────────────────
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Also expose with original names for send_data compatibility
  TextEditingController get firstnamecontroller => _firstNameCtrl;

  TextEditingController get lastnamecontroller => _lastNameCtrl;

  TextEditingController get emailcontroller => _emailCtrl;

  TextEditingController get phonecontroller => _phoneCtrl;

  TextEditingController get placecontroller => _placeCtrl;

  TextEditingController get usernamecontroller => _usernameCtrl;

  TextEditingController get passwordcontroller => _passwordCtrl;

  final _usernameCtrl = TextEditingController();

  String _selectedEmployment = 'Salaried';
  final List<String> _employmentTypes = [
    'Salaried',
    'Self-Employed',
    'Business Owner',
    'Freelancer',
    'Student',
  ];

  // Photo state (unchanged)
  File? _selectedImage;
  String photo = "";
  String? _selectedPhotoLabel;
  final List<String> _photoOptions = [
    'Take Photo',
    'Choose from Gallery',
    'Upload Document',
  ];

  // Validation errors
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _placeError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmError;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _placeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────
  bool _validate() {
    final emailRegex = RegExp(r'^[\w\-.]+@[\w\-]+\.[a-z]{2,}$');
    final phoneRegex = RegExp(r'^\d{7,15}$');

    setState(() {
      _firstNameError = _firstNameCtrl.text
          .trim()
          .isEmpty
          ? 'First name is required'
          : null;
      _lastNameError = _lastNameCtrl.text
          .trim()
          .isEmpty
          ? 'Last name is required'
          : null;
      _emailError = _emailCtrl.text
          .trim()
          .isEmpty
          ? 'Email is required'
          : !emailRegex.hasMatch(_emailCtrl.text.trim())
          ? 'Enter a valid email address'
          : null;
      _phoneError = _phoneCtrl.text
          .trim()
          .isEmpty
          ? 'Phone number is required'
          : !phoneRegex.hasMatch(_phoneCtrl.text.trim())
          ? 'Enter a valid phone number'
          : null;
      _placeError = _placeCtrl.text
          .trim()
          .isEmpty
          ? 'Place / city is required'
          : null;
      _usernameError = _usernameCtrl.text
          .trim()
          .isEmpty
          ? 'Username is required'
          : _usernameCtrl.text
          .trim()
          .length < 3
          ? 'Username must be at least 3 characters'
          : null;
      _passwordError = _passwordCtrl.text
          .trim()
          .isEmpty
          ? 'Password is required'
          : _passwordCtrl.text
          .trim()
          .length < 4
          ? 'Password must be at least 4 characters'
          : null;
      _confirmError = _confirmCtrl.text
          .trim()
          .isEmpty
          ? 'Please confirm your password'
          : _confirmCtrl.text.trim() != _passwordCtrl.text.trim()
          ? 'Passwords do not match'
          : null;
      _photoError = photo.isEmpty ? 'Please upload a profile photo' : null;
    });

    return _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _placeError == null &&
        _usernameError == null &&
        _passwordError == null &&
        _confirmError == null &&
        _photoError == null;
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _PhotoPickerSheet(
            options: _photoOptions,
            onSelected: (label) {
              Navigator.pop(context);
              if (label == 'Take Photo' || label == 'Choose from Gallery') {
                _chooseAndUploadImage(
                  label == 'Take Photo' ? ImageSource.camera : ImageSource
                      .gallery,
                );
              }
              setState(() => _selectedPhotoLabel = label);
            },
          ),
    );
  }

  // ── IMAGE PICKER (logic unchanged) ────────────────────────
  Future<void> _chooseAndUploadImage(
      [ImageSource source = ImageSource.gallery]) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      File imageFile = File(pickedImage.path);
      setState(() {
        _selectedImage = imageFile;
        photo = base64Encode(imageFile.readAsBytesSync());
        _photoError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Black header ─────────────────────────
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF0A0A0A),
                    padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRUSTIFY',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Create\nAccount',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Fill in your details to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Form card ───────────────────────────
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Photo upload ──────────────────
                        _sectionLabel('Profile Photo'),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _showPhotoPicker,
                          child: _PhotoUploadTile(
                            selectedImage: _selectedImage,
                            selectedLabel: _selectedPhotoLabel,
                            errorText: _photoError,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── Personal Info ─────────────────
                        _sectionLabel('Personal Information'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TRUSTIFYInputField(
                                controller: _firstNameCtrl,
                                hintText: 'First Name',
                                errorText: _firstNameError,
                                icon: Icons.person_outline_rounded,
                                onChanged: (_) =>
                                    setState(() => _firstNameError = null),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TRUSTIFYInputField(
                                controller: _lastNameCtrl,
                                hintText: 'Last Name',
                                errorText: _lastNameError,
                                icon: Icons.person_outline_rounded,
                                onChanged: (_) =>
                                    setState(() => _lastNameError = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _TRUSTIFYInputField(
                          controller: _emailCtrl,
                          hintText: 'Email Address',
                          errorText: _emailError,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() => _emailError = null),
                        ),
                        const SizedBox(height: 14),
                        _TRUSTIFYInputField(
                          controller: _phoneCtrl,
                          hintText: 'Phone Number',
                          errorText: _phoneError,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() => _phoneError = null),
                        ),
                        const SizedBox(height: 22),

                        // ── Location ──────────────────────
                        _sectionLabel('Location'),
                        const SizedBox(height: 12),
                        _TRUSTIFYInputField(
                          controller: _placeCtrl,
                          hintText: 'City / Place',
                          errorText: _placeError,
                          icon: Icons.location_on_outlined,
                          onChanged: (_) => setState(() => _placeError = null),
                        ),
                        const SizedBox(height: 22),



                        // ── Account ───────────────────────
                        _sectionLabel('Account Credentials'),
                        const SizedBox(height: 12),
                        _TRUSTIFYInputField(
                          controller: _usernameCtrl,
                          hintText: 'Username',
                          errorText: _usernameError,
                          icon: Icons.badge_outlined,
                          onChanged: (_) =>
                              setState(() => _usernameError = null),
                        ),
                        const SizedBox(height: 14),
                        _TRUSTIFYInputField(
                          controller: _passwordCtrl,
                          hintText: 'Password',
                          errorText: _passwordError,
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          onChanged: (_) =>
                              setState(() => _passwordError = null),
                          suffixWidget: GestureDetector(
                            onTap: () =>
                                setState(
                                        () =>
                                    _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF999999),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _TRUSTIFYInputField(
                          controller: _confirmCtrl,
                          hintText: 'Confirm Password',
                          errorText: _confirmError,
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirm,
                          onChanged: (_) =>
                              setState(() => _confirmError = null),
                          suffixWidget: GestureDetector(
                            onTap: () =>
                                setState(
                                        () =>
                                    _obscureConfirm = !_obscureConfirm),
                            child: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF999999),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        

                        // ── Register button ────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: send_data,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A0A0A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Divider ────────────────────────
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: Color(0xFFE8E8E8))),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'or',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFF999999)),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: Color(0xFFE8E8E8))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Login link ─────────────────────
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                    fontSize: 13, color: Color(0xFF888888)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      const LoginPage(title: ''),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0A0A0A),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: _agreeTerms
                  ? const Color(0xFF0A0A0A)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreeTerms
                    ? const Color(0xFF0A0A0A)
                    : const Color(0xFFCCCCCC),
                width: 1.5,
              ),
            ),
            child: _agreeTerms
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style:
                TextStyle(fontSize: 12.5, color: Color(0xFF666666)),
                children: [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── REGISTER FUNCTION (logic unchanged) ───────────────────
  void send_data() async {

    if (!_validate()) {
      Fluttertoast.showToast(msg: "Please fix errors");
      return;
    }

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url')!;

    var uri = Uri.parse("$url/user_register/");

    var request = http.MultipartRequest('POST', uri);

    request.fields['firstname'] = _firstNameCtrl.text;
    request.fields['lastname'] = _lastNameCtrl.text;
    request.fields['email'] = _emailCtrl.text;
    request.fields['place'] = _placeCtrl.text;
    request.fields['phone'] = _phoneCtrl.text;
    request.fields['username'] = _usernameCtrl.text;
    request.fields['password'] = _passwordCtrl.text;

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        _selectedImage!.path,
      ),
    );

    var response = await request.send();

    var res = await http.Response.fromStream(response);
    var jsonData = jsonDecode(res.body);

    if(jsonData['status']=="ok")
    {
      Fluttertoast.showToast(msg: "Registration Success");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context)=>LoginPage(title: '')),
      );
    }
    else if(jsonData['status']=="exist")
    {
      Fluttertoast.showToast(msg: "Username already exists");
    }
    else
    {
      Fluttertoast.showToast(msg: "Registration Failed");
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  PHOTO UPLOAD TILE
// ═══════════════════════════════════════════════════════════════
class _PhotoUploadTile extends StatelessWidget {
  final File? selectedImage;
  final String? selectedLabel;
  final String? errorText;

  const _PhotoUploadTile({
    this.selectedImage,
    this.selectedLabel,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = selectedImage != null;
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 82,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFFF3B30)
                  : hasPhoto
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFE0E0E0),
              width: hasPhoto ? 1.5 : 1.2,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              // Avatar / icon
              hasPhoto
                  ? CircleAvatar(
                radius: 26,
                backgroundImage: FileImage(selectedImage!),
              )
                  : Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                      color: const Color(0xFFDDDDDD), width: 1),
                ),
                child: const Icon(Icons.add_a_photo_outlined,
                    color: Color(0xFF999999), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPhoto
                          ? (selectedLabel ?? 'Photo Selected')
                          : 'Upload Profile Photo',
                      style: TextStyle(
                        color: hasPhoto
                            ? const Color(0xFF0A0A0A)
                            : const Color(0xFF555555),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasPhoto
                          ? 'Tap to change'
                          : 'JPG, PNG up to 5MB — Tap to select',
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFFBBBBBB)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCCCCCC), size: 20),
              const SizedBox(width: 12),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 13, color: Color(0xFFFF3B30)),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFFFF3B30),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PHOTO PICKER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════
class _PhotoPickerSheet extends StatelessWidget {
  final List<String> options;
  final ValueChanged<String> onSelected;

  const _PhotoPickerSheet(
      {required this.options, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Photo',
            style: TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...options.map((opt) => _PickerOption(
            label: opt,
            icon: opt == 'Take Photo'
                ? Icons.camera_alt_outlined
                : opt == 'Choose from Gallery'
                ? Icons.photo_library_outlined
                : Icons.upload_file_outlined,
            onTap: () => onSelected(opt),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF0A0A0A), size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TRUSTIFY INPUT FIELD
// ═══════════════════════════════════════════════════════════════
class _TRUSTIFYInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String? errorText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixWidget;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _TRUSTIFYInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.errorText,
    this.obscureText = false,
    this.suffixWidget,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFFE0E0E0),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                  color: Color(0xFFBBBBBB), fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFF999999), size: 20),
              suffixIcon: suffixWidget != null
                  ? Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: suffixWidget)
                  : null,
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 15),
            ),
            cursorColor: const Color(0xFF0A0A0A),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 13, color: Color(0xFFFF3B30)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  errorText!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TRUSTIFY DROPDOWN
// ═══════════════════════════════════════════════════════════════
class _TRUSTIFYDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final String hint;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _TRUSTIFYDropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: Colors.white,
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF999999)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF999999), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        style: const TextStyle(color: Color(0xFF0A0A0A), fontSize: 14),
        items: items
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e,
              style: const TextStyle(
                  color: Color(0xFF0A0A0A), fontSize: 14)),
        ))
            .toList(),
      ),
    );
  }
}