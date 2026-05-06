
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:trustify/userhome.dart';

void main() {
  runApp(const view_reply());
}

class view_reply extends StatelessWidget {
  const view_reply({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: view_replypage(title: 'view_reply'),
    );
  }
}

class view_replypage extends StatefulWidget {
  const view_replypage({super.key, required this.title});
  final String title;

  @override
  State<view_replypage> createState() => _view_replypageState();
}

class _view_replypageState extends State<view_replypage> {
  List<String> user_         = [];
  List<String> message_      = [];
  List<String> date_         = [];
  List<String> replied_date_ = [];
  List<String> reply_        = [];
  List<String> status_       = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBanks();
  }

  Future<void> fetchBanks() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? urls = sh.getString('url');
      String? lid  = sh.getString('lid');

      if (urls == null) return;

      var response = await http.post(
        Uri.parse('$urls/user_view_reply/'),
        body: {'lid': lid ?? ''},
      );

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        var arr = jsondata['data'];

        List<String> user         = [];
        List<String> message      = [];
        List<String> date         = [];
        List<String> replied_date = [];
        List<String> reply        = [];
        List<String> status       = [];

        for (int i = 0; i < arr.length; i++) {
          user.add(arr[i]['user'].toString());
          message.add(arr[i]['message'].toString());
          date.add(arr[i]['date'].toString());
          replied_date.add(arr[i]['replied_date'].toString());
          reply.add(arr[i]['reply'].toString());
          status.add(arr[i]['status'].toString());
        }

        setState(() {
          user_         = user;
          message_      = message;
          date_         = date;
          replied_date_ = replied_date;
          reply_        = reply;
          status_       = status;
          isLoading     = false;
        });
      }
    } catch (e) {
      print("ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const Homepage(title: '')),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: _buildAppBar(),
        body: isLoading
            ? _buildLoader()
            : user_.isEmpty
            ? _buildEmpty()
            : _buildList(),
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
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const Homepage(title: '')),
        ),
      ),
      title: const Text(
        'Complaint Replies',
        style: TextStyle(
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

  // ── EMPTY ────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCCCCCC)),
          SizedBox(height: 14),
          Text(
            'No replies yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Your complaint replies will show up here',
            style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
          ),
        ],
      ),
    );
  }

  // ── LIST ─────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: user_.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, int index) => _buildCard(index),
    );
  }

  // ── CARD ─────────────────────────────────────────────────────
  Widget _buildCard(int index) {
    final bool isReplied =
        reply_[index].trim().isNotEmpty ||
            status_[index].toLowerCase() == 'replied';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
            child: Row(
              children: [
                const Text(
                  'Your Complaint',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                _StatusChip(isReplied: isReplied, label: status_[index]),
              ],
            ),
          ),

          // ── Complaint text ───────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              message_[index],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              date_[index],
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFFBBBBBB)),
            ),
          ),

          // ── Divider ──────────────────────────────────
          const Divider(height: 1, color: Color(0xFFF2F2F2)),

          // ── Reply section ─────────────────────────────
          if (isReplied) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.support_agent_outlined,
                            size: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Support Team',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A0A0A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        replied_date_[index],
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFBBBBBB)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      reply_[index],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF333333),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: const [
                  Icon(Icons.schedule_outlined,
                      size: 14, color: Color(0xFFCCCCCC)),
                  SizedBox(width: 6),
                  Text(
                    'Awaiting reply from support team',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFBBBBBB),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── STATUS CHIP ───────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final bool isReplied;
  final String label;

  const _StatusChip({required this.isReplied, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isReplied
            ? const Color(0xFFF0F0F0)
            : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReplied
              ? const Color(0xFFDDDDDD)
              : const Color(0xFFEEEEEE),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isReplied
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFCCCCCC),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isReplied
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}