import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserViewLoanRequestPage extends StatefulWidget {
  const UserViewLoanRequestPage({super.key});

  @override
  State<UserViewLoanRequestPage> createState() =>
      _UserViewLoanRequestPageState();
}

class _UserViewLoanRequestPageState extends State<UserViewLoanRequestPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _loans = [];

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  // ── FETCH ────────────────────────────────────────────────────
  Future<void> _fetchLoans() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');
      String? lid = sh.getString('lid');

      final response = await http.post(
        Uri.parse('$url/user_view_loan_request/'),
        body: {'lid': lid},
      );

      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          _loans = List<Map<String, dynamic>>.from(jsonData['data']);
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to load loan requests");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection Error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── STATUS COLOR ─────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF27AE60);
      case 'rejected':
        return const Color(0xFFE74C3C);
      case 'pending':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFF888888);
    }
  }

  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFEAF9F0);
      case 'rejected':
        return const Color(0xFFFDECEC);
      case 'pending':
        return const Color(0xFFFEF6E7);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'pending':
        return Icons.hourglass_top_outlined;
      default:
        return Icons.info_outline;
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
          : _loans.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchLoans,
        color: const Color(0xFF0A0A0A),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _loans.length,
          itemBuilder: (_, i) => _buildLoanCard(_loans[i]),
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
          child: Row(
            children: [
              const Text(
                'My Loan Requests',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3),
              ),
              const Spacer(),
              if (_loans.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_loans.length} total',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LOAN CARD ────────────────────────────────────────────────
  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final status = loan['status'] ?? 'Pending';
    final amount = loan['amount'] ?? '0';
    final bank = loan['bank'] ?? '—';
    final loanType = loan['loan_type'] ?? '—';
    final date = loan['date'] ?? '—';
    final id = loan['id']?.toString() ?? '—';

    return GestureDetector(
      onTap: () => _showLoanDetail(loan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // ── Card header ──────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_outlined,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bank,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loanType,
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusBg(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status),
                            size: 12, color: _statusColor(status)),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(status)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Card body ────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Amount row
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.currency_rupee_outlined,
                            size: 17, color: Color(0xFF0A0A0A)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Loan Amount',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFAAAAAA),
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            '₹ $amount',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0A0A0A)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),

                  // Meta row: ID + Date
                  Row(
                    children: [
                      Expanded(
                          child: _metaTile(
                              Icons.tag_outlined, 'Request ID', '#$id')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _metaTile(Icons.calendar_today_outlined,
                              'Submitted', _formatDate(date))),
                    ],
                  ),
                ],
              ),
            ),

            // ── View details footer ───────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F8F8),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Details',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A0A0A))),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_outlined,
                      size: 11, color: Color(0xFF0A0A0A)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF999999)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFAAAAAA),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A0A0A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── DETAIL BOTTOM SHEET ──────────────────────────────────────
  void _showLoanDetail(Map<String, dynamic> loan) {
    final status = loan['status'] ?? 'Pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF0F0F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_outlined,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loan['bank'] ?? '—',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(loan['loan_type'] ?? '—',
                              style: const TextStyle(
                                  color: Color(0xFF888888), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(status))),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _detailCard([
                      _detailRow(Icons.currency_rupee_outlined, 'Loan Amount',
                          '₹ ${loan['amount']}'),
                      _divider(),
                      _detailRow(Icons.tag_outlined, 'Request ID',
                          '#${loan['id']}'),
                      _divider(),
                      _detailRow(Icons.calendar_today_outlined, 'Submitted',
                          _formatDate(loan['date'] ?? '')),
                    ]),
                    const SizedBox(height: 12),
                    _detailCard([
                      _detailRow(
                          Icons.insert_drive_file_outlined,
                          'Document',
                          loan['document'] != null &&
                              loan['document'].toString().isNotEmpty
                              ? 'Uploaded'
                              : 'Not uploaded'),
                      _divider(),
                      _detailRow(
                          Icons.face_outlined,
                          'Face Image',
                          loan['face_image'] != null &&
                              loan['face_image'].toString().isNotEmpty
                              ? 'Uploaded'
                              : 'Not uploaded'),
                    ]),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF0A0A0A)),
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
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A0A0A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: Color(0xFFF5F5F5), indent: 70, endIndent: 20);

  // ── EMPTY STATE ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.account_balance_outlined,
                size: 34, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 16),
          const Text('No loan requests yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A0A0A))),
          const SizedBox(height: 6),
          const Text('Your submitted loan requests will appear here',
              style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────
  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }
}