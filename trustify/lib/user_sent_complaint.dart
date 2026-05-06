
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:trustify/user_view_reply.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  // ── Controllers & state (names unchanged) ──────────────────
  final TextEditingController complaintController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Validation error
  String? _complaintError;

  @override
  void dispose() {
    complaintController.dispose();
    super.dispose();
  }

  // ── SUBMIT COMPLAINT (logic unchanged) ─────────────────────
  void submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    setState(() => isLoading = false);

    Fluttertoast.showToast(msg: "Complaint Sent Successfully");

    complaintController.clear();
  }

  // ── VALIDATE ───────────────────────────────────────────────
  bool _validate() {
    setState(() {
      final text = complaintController.text.trim();
      _complaintError = text.isEmpty
          ? 'Please enter your complaint'
          : text.length < 10
          ? 'Complaint must be at least 10 characters'
          : null;
    });
    return _complaintError == null;
  }

  // ── SEND DATA (logic unchanged) ────────────────────────────
  void send_data() async {

    if (!_validate()) return;

    SharedPreferences sh = await SharedPreferences.getInstance();

    String? url = sh.getString('url');
    String? lid = sh.getString('lid');

    final Uri urls = Uri.parse('$url/user_send_compaint/');

    try {

      final response = await http.post(
        urls,
        body: {
          'lid': lid,
          "complaint": complaintController.text,
        },
      );

      var jsonData = jsonDecode(response.body);

      if(jsonData['status']=="ok")
      {
        Fluttertoast.showToast(msg: "Complaint Sent Successfully");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => view_replypage(title: '',)),
        );
      }

    }
    catch(e)
    {
      Fluttertoast.showToast(msg: "Connection Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info card ──────────────────────────────
              _buildInfoCard(),

              // ── Form card ──────────────────────────────
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Complaint Details'),
                      const SizedBox(height: 16),

                      // ── Complaint field ────────────────
                      _buildLabel('Your Complaint'),
                      const SizedBox(height: 8),
                      _buildComplaintField(),
                      const SizedBox(height: 6),

                      // ── Character counter ──────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${complaintController.text.length} characters',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFBBBBBB),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Submit button ──────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : send_data,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A0A0A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            const Color(0xFF555555),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_outlined,
                                  size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Submit Complaint',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── APP BAR ─────────────────────────────────────────────────
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
          color: Colors.white,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: const Text(
            'Send Complaint',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }

  // ── INFO CARD ────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.report_problem_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'re Here to Help',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Describe your issue and we\'ll respond shortly',
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── COMPLAINT TEXTAREA ───────────────────────────────────────
  Widget _buildComplaintField() {
    final bool hasError =
        _complaintError != null && _complaintError!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
          child: TextFormField(
            controller: complaintController,
            maxLines: 6,
            onChanged: (_) {
              setState(() => _complaintError = null);
            },
            validator: (value) =>
            value!.isEmpty ? 'Please enter complaint' : null,
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 14,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText:
              'Describe your complaint in detail...',
              hintStyle: TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 80),
                child: Icon(Icons.edit_note_outlined,
                    color: Color(0xFF999999), size: 20),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(0, 16, 16, 16),
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
                  _complaintError!,
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0A0A0A),
        letterSpacing: 0.3,
      ),
    );
  }
}