import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'edit_profile.dart';

class UserViewProfilePage extends StatefulWidget {
  const UserViewProfilePage({super.key});

  @override
  State<UserViewProfilePage> createState() => _UserViewProfilePageState();
}

class _UserViewProfilePageState extends State<UserViewProfilePage> {
  bool _isLoading = true;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _place = '';
  String _photoUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');
      String? lid = sh.getString('lid');

      final response = await http.post(
        Uri.parse('$url/user_view_profile/'),
        body: {'lid': lid},
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'ok') {
        setState(() {
          _firstName = data['firstname'] ?? '';
          _lastName = data['lastname'] ?? '';
          _email = data['email'] ?? '';
          _phone = data['phone'] ?? '';
          _place = data['place'] ?? '';
          _photoUrl = data['photo'] ?? '';
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection Error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToEdit() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserEditProfilePage(
          firstName: _firstName,
          lastName: _lastName,
          email: _email,
          phone: _phone,
          place: _place,
          photoUrl: _photoUrl,
        ),
      ),
    );

    if (updated == true) {
      _fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF0A0A0A), strokeWidth: 2.5))
          : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildAvatarSection(),
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildEditButton(),
              const SizedBox(height: 30),
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
      title: const Text(
        'TRUSTIFY',
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 5,
            color: Colors.white),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: const Text(
            'My Profile',
            style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3),
          ),
        ),
      ),
    );
  }

  // ── AVATAR SECTION ───────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.only(bottom: 32, top: 8),
      child: Column(
        children: [
          // Avatar circle
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 3),
            ),
            child: ClipOval(
              child: _photoUrl.isNotEmpty
                  ? Image.network(
                _photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(),
              )
                  : _avatarFallback(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$_firstName $_lastName'.trim().isEmpty
                ? 'User'
                : '$_firstName $_lastName',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _email,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
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
          _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'U',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── INFO CARD ────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
            child: _sectionLabel('Personal Information'),
          ),
          const SizedBox(height: 4),
          _infoTile(Icons.person_outline, 'First Name', _firstName),
          _divider(),
          _infoTile(Icons.person_outline, 'Last Name', _lastName),
          _divider(),
          _infoTile(Icons.email_outlined, 'Email', _email),
          _divider(),
          _infoTile(Icons.phone_outlined, 'Phone', _phone),
          _divider(),
          _infoTile(Icons.location_on_outlined, 'Place', _place),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF0A0A0A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFAAAAAA),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value.isEmpty
                        ? const Color(0xFFCCCCCC)
                        : const Color(0xFF0A0A0A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, color: Color(0xFFF5F5F5), indent: 76, endIndent: 24);

  // ── EDIT BUTTON ──────────────────────────────────────────────
  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _goToEdit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A0A0A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_outlined, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Text('Edit Profile',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
            ],
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