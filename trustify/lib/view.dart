
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:trustify/user_loan_type.dart';
import 'package:trustify/userhome.dart';

void main() {
  runApp(const Banks());
}

class Banks extends StatelessWidget {
  const Banks({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Bankspage(title: 'Banks'),
    );
  }
}

class Bankspage extends StatefulWidget {
  const Bankspage({super.key, required this.title});
  final String title;

  @override
  State<Bankspage> createState() => _BankspageState();
}

class _BankspageState extends State<Bankspage> {
  // ── State variables (names unchanged) ──────────────────────
  List<String> id_     = [];
  List<String> name_   = [];
  List<String> branch_ = [];
  List<String> email_  = [];
  List<String> phone_  = [];
  List<String> place_  = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBanks();
  }

  // ── FETCH BANKS (logic unchanged) ──────────────────────────
  Future<void> fetchBanks() async {
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? urls = sh.getString('url');
      String? lid  = sh.getString('lid');

      if (urls == null) return;

      var response = await http.post(
        Uri.parse('$urls/user_Banks/'),
        body: {'lid': lid ?? ''},
      );

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {
        var arr = jsondata['data'];

        List<String> id     = [];
        List<String> name   = [];
        List<String> branch = [];
        List<String> email  = [];
        List<String> phone  = [];
        List<String> place  = [];

        for (int i = 0; i < arr.length; i++) {
          id.add(arr[i]['id'].toString());
          name.add(arr[i]['name'].toString());
          branch.add(arr[i]['branch'].toString());
          email.add(arr[i]['email'].toString());
          phone.add(arr[i]['phone'].toString());
          place.add(arr[i]['place'].toString());
        }

        setState(() {
          id_     = id;
          name_   = name;
          branch_ = branch;
          email_  = email;
          phone_  = phone;
          place_  = place;
          isLoading = false;
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
        backgroundColor: const Color(0xFFF0F0F0),
        appBar: _buildAppBar(),
        body: isLoading ? _buildLoader() : _buildContent(),
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
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const Homepage(title: '')),
          );
        },
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
            'Available Banks',
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

  // ── LOADER ──────────────────────────────────────────────────
  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0A0A0A),
        strokeWidth: 2.5,
      ),
    );
  }

  // ── CONTENT ─────────────────────────────────────────────────
  Widget _buildContent() {
    if (id_.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.account_balance_outlined,
                  size: 32, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No banks available',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check back later',
              style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: id_.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildBankCard(index);
      },
    );
  }

  // ── BANK CARD ────────────────────────────────────────────────
  Widget _buildBankCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card header (bank name) ──────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name_[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        branch_[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Card body (details) ──────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow(
                    Icons.email_outlined, 'Email', email_[index]),
                const SizedBox(height: 12),
                _buildDetailRow(
                    Icons.phone_outlined, 'Phone', phone_[index]),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.location_on_outlined,
                    'Location', place_[index]),
                const SizedBox(height: 18),

                // ── View Loan Types button ───────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      SharedPreferences sh =
                      await SharedPreferences.getInstance();
                      sh.setString("bank_id", id_[index]);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoanTypesPage(
                              title: 'Loan Types'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Loan Types',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios,
                            size: 13, color: Colors.white),
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

  // ── DETAIL ROW ───────────────────────────────────────────────
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF555555)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFAAAAAA),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '—',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}