import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserEditProfilePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String place;
  final String photoUrl;

  const UserEditProfilePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.place,
    required this.photoUrl,
  });

  @override
  State<UserEditProfilePage> createState() => _UserEditProfilePageState();
}

class _UserEditProfilePageState extends State<UserEditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _placeController;

  File? _newPhoto;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController  = TextEditingController(text: widget.lastName);
    _emailController     = TextEditingController(text: widget.email);
    _phoneController     = TextEditingController(text: widget.phone);
    _placeController     = TextEditingController(text: widget.place);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  // ── PICK PHOTO ───────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _sheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take a Photo',
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker()
                      .pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (picked != null) {
                    setState(() => _newPhoto = File(picked.path));
                  }
                },
              ),
              const SizedBox(height: 12),
              _sheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await ImagePicker()
                      .pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) {
                    setState(() => _newPhoto = File(picked.path));
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption(
      {required IconData icon,
        required String label,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A0A0A))),
          ],
        ),
      ),
    );
  }

  // ── SAVE ─────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');
      String? lid = sh.getString('lid');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/user_edit_profile/'),
      );

      request.fields['lid']       = lid ?? '';
      request.fields['firstname'] = _firstNameController.text.trim();
      request.fields['lastname']  = _lastNameController.text.trim();
      request.fields['email']     = _emailController.text.trim();
      request.fields['phone']     = _phoneController.text.trim();
      request.fields['place']     = _placeController.text.trim();

      if (_newPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _newPhoto!.path),
        );
      }

      final response =
      await http.Response.fromStream(await request.send());
      final data = jsonDecode(response.body);

      if (data['status'] == 'ok') {
        Fluttertoast.showToast(msg: "Profile updated successfully");
        if (mounted) Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(msg: "Update failed. Try again.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection Error");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── VALIDATORS ───────────────────────────────────────────────
  String? _validateName(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return '$field must contain only letters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Photo picker header
              _buildPhotoSection(),

              // Form card
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
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Personal Details'),
                      const SizedBox(height: 20),

                      _buildField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.person_outline,
                        hint: 'Enter first name',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]'))
                        ],
                        validator: (v) => _validateName(v, 'First name'),
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        icon: Icons.person_outline,
                        hint: 'Enter last name',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z\s]'))
                        ],
                        validator: (v) => _validateName(v, 'Last name'),
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        hint: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        hint: '10-digit number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        controller: _placeController,
                        label: 'Place',
                        icon: Icons.location_on_outlined,
                        hint: 'Your city or town',
                        validator: (v) => _validateRequired(v, 'Place'),
                      ),
                      const SizedBox(height: 28),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A0A0A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            const Color(0xFF555555),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5))
                              : const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_outlined,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Save Changes',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('TRUSTIFY',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 5,
              color: Colors.white)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: const Text('Edit Profile',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
        ),
      ),
    );
  }

  // ── PHOTO SECTION ────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.only(bottom: 28, top: 4),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.15), width: 3),
                ),
                child: ClipOval(
                  child: _newPhoto != null
                      ? Image.file(_newPhoto!, fit: BoxFit.cover)
                      : widget.photoUrl.isNotEmpty
                      ? Image.network(
                    widget.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _avatarFallback(),
                  )
                      : _avatarFallback(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0A0A0A), width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Color(0xFF0A0A0A)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickPhoto,
            child: const Text(
              'Change Photo',
              style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: Colors.white.withOpacity(0.08),
      child: Center(
        child: Text(
          widget.firstName.isNotEmpty
              ? widget.firstName[0].toUpperCase()
              : 'U',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── FIELD BUILDER ────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A0A0A),
                letterSpacing: 0.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0A0A0A),
              fontWeight: FontWeight.w500),
          cursorColor: const Color(0xFF0A0A0A),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 13, color: Color(0xFFBBBBBB)),
            prefixIcon: Icon(icon,
                size: 18, color: const Color(0xFF999999)),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFFE0E0E0), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFFE0E0E0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFF0A0A0A), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFFFF3B30), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
            ),
            errorStyle: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFFFF3B30),
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
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
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFF888888)),
        ),
      ],
    );
  }
}