import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════
//  FEEDBACK PAGE  –  list view + FAB → inline send form
// ═══════════════════════════════════════════════════════════════
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // ── List state ──────────────────────────────────────────────
  List<String> message_ = [];
  List<String> date_    = [];
  bool isLoading = true;

  // ── Form state ──────────────────────────────────────────────
  bool _showForm       = false;
  bool _formSubmitting = false;
  String? _feedbackError;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  // ── FETCH all feedback ──────────────────────────────────────
  Future<void> _fetchFeedback() async {
    setState(() => isLoading = true);
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? urls = sh.getString('url');
      String? lid  = sh.getString('lid');
      if (urls == null) { setState(() => isLoading = false); return; }

      var response = await http.post(
        Uri.parse('$urls/user_view_feedback/'),
        body: {'lid': lid ?? ''},
      );

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        var arr = jsondata['data'];
        List<String> msgs  = [];
        List<String> dates = [];
        for (int i = 0; i < arr.length; i++) {
          msgs.add(arr[i]['message'].toString());
          dates.add(arr[i]['date'].toString());
        }
        setState(() {
          message_ = msgs;
          date_    = dates;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('ERROR: $e');
      setState(() => isLoading = false);
    }
  }

  // ── VALIDATE form ───────────────────────────────────────────
  bool _validate() {
    final text = _feedbackController.text.trim();
    setState(() {
      _feedbackError = text.isEmpty
          ? 'Please enter your feedback'
          : text.length < 10
          ? 'Feedback must be at least 10 characters'
          : null;
    });
    return _feedbackError == null;
  }

  // ── SUBMIT feedback ─────────────────────────────────────────
  Future<void> _submitFeedback() async {
    if (!_validate()) return;

    setState(() => _formSubmitting = true);

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? urls = sh.getString('url');
      String? lid  = sh.getString('lid');

      if (urls == null) {
        Fluttertoast.showToast(msg: 'Server URL not found');
        setState(() => _formSubmitting = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$urls/user_send_feedback/'),
        body: {'lid': lid ?? '', 'message': _feedbackController.text.trim()},
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['status'] == 'ok') {
          Fluttertoast.showToast(msg: 'Feedback submitted successfully');
          _feedbackController.clear();
          setState(() {
            _showForm       = false;
            _formSubmitting = false;
            _feedbackError  = null;
          });
          _fetchFeedback(); // refresh list
        } else {
          Fluttertoast.showToast(msg: jsonData['message'] ?? 'Error');
          setState(() => _formSubmitting = false);
        }
      } else {
        Fluttertoast.showToast(msg: 'Server error');
        setState(() => _formSubmitting = false);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Connection error');
      setState(() => _formSubmitting = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showForm) {
          setState(() {
            _showForm      = false;
            _feedbackError = null;
            _feedbackController.clear();
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: _buildAppBar(),
        body: isLoading
            ? _buildLoader()
            : _showForm
            ? _buildFormView()
            : _buildListView(),
        floatingActionButton: _showForm ? null : _buildFAB(),
      ),
    );
  }

  // ── APP BAR ─────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            color: Color(0xFF0A0A0A), size: 18),
        onPressed: () {
          if (_showForm) {
            setState(() {
              _showForm      = false;
              _feedbackError = null;
              _feedbackController.clear();
            });
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        _showForm ? 'Send Feedback' : 'My Feedback',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0A0A0A),
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFEEEEEE), height: 1),
      ),
    );
  }

  // ── LOADER ──────────────────────────────────────────────────
  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0A0A0A),
        strokeWidth: 2,
      ),
    );
  }

  // ── FAB ─────────────────────────────────────────────────────
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {
        setState(() => _showForm = true);
      },
      backgroundColor: const Color(0xFF0A0A0A),
      elevation: 2,
      child: const Icon(Icons.add, color: Colors.white, size: 26),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  LIST VIEW
  // ═══════════════════════════════════════════════════════════
  Widget _buildListView() {
    if (message_.isEmpty) return _buildEmpty();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: message_.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, int index) => _buildFeedbackCard(index),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.feedback_outlined, size: 48, color: Color(0xFFCCCCCC)),
          SizedBox(height: 14),
          Text(
            'No feedback yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap + to share your thoughts with us',
            style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
        ],
      ),
    );
  }

  // ── FEEDBACK CARD ────────────────────────────────────────────
  Widget _buildFeedbackCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.feedback_outlined,
                      size: 13, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Your Feedback',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFDDDDDD), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0A0A0A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Submitted',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Message ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                message_[index],
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF333333),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Date ───────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.schedule_outlined,
                    size: 12, color: Color(0xFFBBBBBB)),
                const SizedBox(width: 4),
                Text(
                  date_[index],
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFBBBBBB)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  FORM VIEW  (same style as list — no new AppBar, inline)
  // ═══════════════════════════════════════════════════════════
  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info banner ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.feedback_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Your Thoughts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Your feedback helps us improve our services',
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
          ),
          const SizedBox(height: 16),

          // ── Form card ──────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
            ),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section label
                Row(
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
                    const Text(
                      'YOUR FEEDBACK',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Field label
                const Text(
                  'Feedback Message',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Textarea
                _buildFeedbackField(),
                const SizedBox(height: 6),

                // Char counter
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_feedbackController.text.length} characters',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFBBBBBB)),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _formSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF555555),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _formSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_outlined,
                            size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Submit Feedback',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FEEDBACK TEXTAREA ────────────────────────────────────────
  Widget _buildFeedbackField() {
    final bool hasError =
        _feedbackError != null && _feedbackError!.isNotEmpty;
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
          child: TextField(
            controller: _feedbackController,
            maxLines: 6,
            onChanged: (_) {
              setState(() => _feedbackError = null);
            },
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 14,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText: 'Share your experience or suggestions...',
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
                  _feedbackError!,
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