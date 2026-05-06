import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustify/login.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trustify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: const MyAppPage(title: ''),
    );
  }
}

class MyAppPage extends StatefulWidget {
  const MyAppPage({super.key, required this.title});
  final String title;

  @override
  State<MyAppPage> createState() => _MyAppPageState();
}

class _MyAppPageState extends State<MyAppPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController ipc = TextEditingController();
  String? _ipError;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    ipc.dispose();
    super.dispose();
  }

  bool _validateIp() {
    final val = ipc.text.trim();
    if (val.isEmpty) {
      setState(() => _ipError = 'IP address is required');
      return false;
    }
    // basic IP / hostname check
    final ipRegex = RegExp(
        r'^(\d{1,3}\.){3}\d{1,3}$|^localhost$|^[\w\-]+(\.[\w\-]+)*$');
    if (!ipRegex.hasMatch(val)) {
      setState(() => _ipError = 'Enter a valid IP address');
      return false;
    }
    setState(() => _ipError = null);
    return true;
  }

  void send_data() async {
    if (!_validateIp()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));

    String ipdata = ipc.text.trim();
    SharedPreferences sh = await SharedPreferences.getInstance();
    sh.setString("ip", ipdata);
    sh.setString("url", "http://$ipdata:8000");
    sh.setString("Image_url", "http://$ipdata:8000");

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginPage(title: 'login')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── Top branding area ──────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo mark
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'T',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Brand name
                        const Text(
                          'TRUSTIFY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 5,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Headline
                        const Text(
                          'Connect to\nYour Server',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter your local server IP address\nto get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.38),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Decorative dots grid ───────
                        _buildDotsGrid(),
                      ],
                    ),
                  ),
                ),

                // ── Bottom form sheet ──────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDDDDD),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card
                      Container(
                        width: double.infinity,
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
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            // Section label
                            _sectionLabel('Server Configuration'),
                            const SizedBox(height: 16),

                            // IP Field label
                            const Text(
                              'IP Address',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0A0A0A),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Input
                            _buildIpField(),

                            const SizedBox(height: 8),

                            // Helper text
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 12,
                                  color: Color(0xFFBBBBBB),
                                ),
                                const SizedBox(width: 5),
                                const Expanded(
                                  child: Text(
                                    'e.g. 192.168.1.100',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFBBBBBB),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Connect button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed:
                                _isLoading ? null : send_data,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF0A0A0A),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                  const Color(0xFF555555),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                    : const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        Icons
                                            .wifi_tethering_outlined,
                                        size: 18,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Connect',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                        FontWeight.w600,
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

                      const SizedBox(height: 20),

                      // Footer note
                      Center(
                        child: Text(
                          'Make sure your device and server are\non the same network',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.black.withOpacity(0.3),
                            height: 1.6,
                          ),
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
    );
  }

  // ── IP INPUT FIELD ───────────────────────────────────────────
  Widget _buildIpField() {
    final bool hasError = _ipError != null && _ipError!.isNotEmpty;
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
            controller: ipc,
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (_) => setState(() => _ipError = null),
            onSubmitted: (_) => send_data(),
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            decoration: InputDecoration(
              hintText: '192.168.x.x',
              hintStyle: const TextStyle(
                  color: Color(0xFFBBBBBB), fontSize: 14),
              prefixIcon: const Icon(Icons.router_outlined,
                  color: Color(0xFF999999), size: 20),
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
              Text(
                _ipError!,
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

  // ── DECORATIVE DOTS ──────────────────────────────────────────
  Widget _buildDotsGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(24, (i) {
        final opacity = i % 3 == 0 ? 0.18 : 0.06;
        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // ── SECTION LABEL ────────────────────────────────────────────
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
}