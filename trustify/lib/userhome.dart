

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:trustify/upload_document.dart';
import 'package:trustify/user_sent_complaint.dart';
import 'package:trustify/user_sent_feedback.dart';
import 'package:trustify/user_view_reply.dart';
import 'package:trustify/view.dart';
import 'package:trustify/view_profile.dart';
import 'Manage_income.dart';
import 'MonthlyReportPage.dart';
import 'loan_status.dart';
import 'login.dart';
import 'manage_expense.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key, required this.title});
  final String title;

  @override
  State<Homepage> createState() => _State();
}

class _State extends State<Homepage> with TickerProviderStateMixin {
  late SharedPreferences prefs;

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _place = '';
  String _photoBase64 = '';
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fetchProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');
      String? lid = sh.getString('lid');

      // Basic validation
      if (url == null || url.isEmpty) {
        Fluttertoast.showToast(msg: "Server URL not configured");
        setState(() => _isLoading = false);
        return;
      }
      if (lid == null || lid.isEmpty) {
        Fluttertoast.showToast(msg: "Session expired. Please login again.");
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$url/user_view_profile/'),
        body: {'lid': lid},
      );

      if (response.statusCode != 200) {
        Fluttertoast.showToast(msg: "Server error. Please try again.");
        setState(() => _isLoading = false);
        return;
      }

      final data = jsonDecode(response.body);

      if (data['status'] == 'ok') {
        setState(() {
          _firstName   = data['firstname'] ?? '';
          _lastName    = data['lastname']  ?? '';
          _email       = data['email']     ?? '';
          _phone       = data['phone']     ?? '';
          _place       = data['place']     ?? '';
          _photoBase64 = data['photo']     ?? '';
        });
        _fadeController.forward();
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to load profile");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection Error. Check your internet.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Sidebar items data ──────────────────────────────────────
  List<_SidebarItem> get _sidebarItems => [
    _SidebarItem(
      icon: Icons.account_balance_outlined,
      label: 'View Banks',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Bankspage(title: '')),
      ),
    ),
    _SidebarItem(
      icon: Icons.pending_actions_outlined,
      label: 'View Request Status',
      onTap: () {},
    ),
    _SidebarItem(
      icon: Icons.trending_up_outlined,
      label: 'Manage Income',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ManageIncomePage()),
      ),
    ),
    _SidebarItem(
      icon: Icons.trending_down_outlined,
      label: 'Manage Expense',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ManageExpensePage(title: '')),
      ),
    ),
    _SidebarItem(
      icon: Icons.summarize_outlined,
      label: 'Smart Summary',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DocumentUploadPage()),
      ),
    ),
    _SidebarItem(
      icon: Icons.report_problem_outlined,
      label: 'Sent Complaints',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ComplaintPage()),
      ),
    ),
    _SidebarItem(
      icon: Icons.mark_email_read_outlined,
      label: 'View Reply',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => view_reply()),
      ),
    ),
    _SidebarItem(
      icon: Icons.feedback_outlined,
      label: 'Sent Feedback',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FeedbackPage()),
      ),
    ),
  ];

  int _selectedSidebarIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
    );
  }

  // ── LOADING STATE ───────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF1A1AFF),
        strokeWidth: 2,
      ),
    );
  }

  // ── APP BAR ─────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF5F6FA),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'TRUSTIFY',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 6,
          color: Color(0xFF0A0A0A),
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.menu_rounded, color: Color(0xFF0A0A0A), size: 18),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.person_outline_rounded, color: Color(0xFF0A0A0A), size: 18),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserViewProfilePage(),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  // ── DRAWER ──────────────────────────────────────────────────
  Widget _buildDrawer() {
    final String initials = [
      _firstName.isNotEmpty ? _firstName[0] : '',
      _lastName.isNotEmpty ? _lastName[0] : '',
    ].join().toUpperCase();

    return Drawer(
      backgroundColor: const Color(0xFF080810),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TRUSTIFY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: const Color(0xFF1A1A2E)),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1AFF), Color(0xFF6644FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials.isNotEmpty ? initials : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_firstName $_lastName'.trim().isEmpty
                              ? 'User'
                              : '$_firstName $_lastName'.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_email.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            _email,
                            style: const TextStyle(
                              color: Color(0xFF555577),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: const Color(0xFF1A1A2E)),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _sidebarItems.length,
                itemBuilder: (ctx, i) {
                  final item = _sidebarItems[i];
                  final isSelected = _selectedSidebarIndex == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedSidebarIndex = i);
                      Navigator.pop(context);
                      item.onTap();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1A1AFF).withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF1A1AFF).withOpacity(0.35), width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isSelected ? const Color(0xFF6677FF) : const Color(0xFF444466),
                            size: 18,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF777799),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(height: 1, color: const Color(0xFF1A1A2E)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(title: 'Login'),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Icon(Icons.logout_rounded, color: Color(0xFF444466), size: 18),
                    SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Color(0xFF555577),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BODY ────────────────────────────────────────────────────
  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHomeHeader(),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  Text(
                    '${_buildServicesData().length} features',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildServicesGrid(),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ── HOME HEADER ──────────────────────────────────────────────
  Widget _buildHomeHeader() {
    final String initials = [
      _firstName.isNotEmpty ? _firstName[0] : '',
      _lastName.isNotEmpty ? _lastName[0] : '',
    ].join().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting row ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _firstName.isNotEmpty
                          ? 'Hello, $_firstName 👋'
                          : 'Hello! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _place.isNotEmpty
                          ? '📍 $_place'
                          : 'Welcome back to Trustify',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1AFF), Color(0xFF6644FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF222222), width: 2),
                ),
                child: Center(
                  child: Text(
                    initials.isNotEmpty ? initials : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Info chips ───────────────────────────────────
          Row(
            children: [
              if (_email.isNotEmpty)
                _buildInfoChip(Icons.email_outlined, _email),
              if (_email.isNotEmpty && _phone.isNotEmpty)
                const SizedBox(width: 8),
              if (_phone.isNotEmpty)
                _buildInfoChip(Icons.phone_outlined, _phone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF666666)),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SERVICES GRID DATA ─────────────────────────────────────────
  List<_ServiceItem> _buildServicesData() {
    return [
      _ServiceItem(
        icon: Icons.account_balance_outlined,
        label: 'View Banks',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Bankspage(title: '')),
        ),
      ),
      _ServiceItem(
        icon: Icons.pending_actions_outlined,
        label: 'Request Status',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserViewLoanRequestPage(),
            ),
          );
        },
      ),
      _ServiceItem(
        icon: Icons.trending_up_outlined,
        label: 'Manage Income',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ManageIncomePage()),
        ),
      ),
      _ServiceItem(
        icon: Icons.trending_down_outlined,
        label: 'Manage Expense',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ManageExpensePage(title: '')),
        ),
      ),
      _ServiceItem(
        icon: Icons.bar_chart_rounded,
        label: 'Monthly Report',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MonthlyReportPage()),
        ),
      ),
      _ServiceItem(
        icon: Icons.report_problem_outlined,
        label: 'Sent Complaints',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ComplaintPage()),
        ),
      ),
      _ServiceItem(
        icon: Icons.mark_email_read_outlined,
        label: 'View Reply',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => view_reply()),
        ),
      ),
      _ServiceItem(
        icon: Icons.feedback_outlined,
        label: 'Sent Feedback',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FeedbackPage()),
        ),
      ),
    ];
  }

  // ── SERVICES GRID ─────────────────────────────────────────────
  Widget _buildServicesGrid() {
    final services = _buildServicesData();

    // Icon accent colors per service
    final List<Color> accentColors = [
      const Color(0xFF1A1AFF),
      const Color(0xFFFF8800),
      const Color(0xFF00C26F),
      const Color(0xFFFF4466),
      const Color(0xFF8844FF),
      const Color(0xFFFF2255),
      const Color(0xFF0099FF),
      const Color(0xFF00BBAA),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: services.length,
      itemBuilder: (ctx, i) {
        final s = services[i];
        final color = accentColors[i % accentColors.length];
        return GestureDetector(
          onTap: s.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(s.icon, size: 19, color: color),
                ),
                const SizedBox(height: 7),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    s.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── DATA MODELS ─────────────────────────────────────────────────
class _SidebarItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _SidebarItem({required this.icon, required this.label, required this.onTap});
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ActionItem({required this.icon, required this.label, required this.onTap});
}

class _ServiceItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ServiceItem({required this.icon, required this.label, required this.onTap});
}