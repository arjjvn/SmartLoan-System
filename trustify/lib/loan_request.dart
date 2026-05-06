
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class LoanRequestPage extends StatefulWidget {
  final String loanTypeId;
  final String loanName;

  const LoanRequestPage({
    super.key,
    required this.loanTypeId,
    required this.loanName,
  });

  @override
  State<LoanRequestPage> createState() => _LoanRequestPageState();
}

class _LoanRequestPageState extends State<LoanRequestPage> {
  final TextEditingController amountController = TextEditingController();

  File? documentFile;
  File? faceImage;

  bool loading = false;
  bool isFetching = true;
  // bool _hasShownInitialSheet = false; // Track if initial sheet was shown

  String? _amountError;

  List<Map<String, dynamic>> loanRequests = [];

  @override
  void initState() {
    super.initState();
    fetchLoanRequests();
    // Open form immediately on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openRequestSheet();
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  // ── FETCH LOAN REQUESTS ────────────────────────────────────
  Future<void> fetchLoanRequests() async {
    setState(() => isFetching = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');
    String? lid = sh.getString('lid');

    if (url == null || lid == null) {
      setState(() => isFetching = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$url/user_view_loan_request/'),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          setState(() {
            loanRequests = List<Map<String, dynamic>>.from(jsonData['data']);
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load requests");
    }

    setState(() => isFetching = false);

    // Always open bottom sheet on first load (regardless of list content)
    // if (!_hasShownInitialSheet) {
    //   _hasShownInitialSheet = true;
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _openRequestSheet();
    //   });
    // }
  }

  // ── PICK DOCUMENT ──────────────────────────────────────────
  Future<void> pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => documentFile = File(result.files.single.path!));
    }
  }

  // ── PICK IMAGE ─────────────────────────────────────────────
  Future<void> pickImage() async {
    final picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => faceImage = File(file.path));
  }

  // ── TAKE PHOTO ─────────────────────────────────────────────
  Future<void> takePhoto() async {
    final picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) setState(() => faceImage = File(file.path));
  }

  // ── IMAGE SOURCE PICKER ────────────────────────────────────
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              'Select Face Image',
              style: TextStyle(
                color: Color(0xFF0A0A0A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _PickerOption(
              label: 'Take Photo',
              icon: Icons.camera_alt_outlined,
              onTap: () {
                Navigator.pop(context);
                takePhoto();
              },
            ),
            _PickerOption(
              label: 'Choose from Gallery',
              icon: Icons.photo_library_outlined,
              onTap: () {
                Navigator.pop(context);
                pickImage();
              },
            ),
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
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEND REQUEST ───────────────────────────────────────────
  Future<void> sendRequest() async {
    setState(() {
      _amountError = amountController.text.trim().isEmpty
          ? 'Please enter loan amount'
          : double.tryParse(amountController.text.trim()) == null
          ? 'Enter a valid number'
          : double.parse(amountController.text.trim()) <= 0
          ? 'Amount must be greater than 0'
          : null;
    });

    if (_amountError != null) return;

    if (documentFile == null) {
      Fluttertoast.showToast(msg: "Please upload a document");
      return;
    }

    if (faceImage == null) {
      Fluttertoast.showToast(msg: "Please upload a face image");
      return;
    }

    setState(() => loading = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url')!;
    String lid = sh.getString('lid')!;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$url/user_send_loan_request/'),
    );

    request.fields['lid'] = lid;
    request.fields['loan_id'] = widget.loanTypeId;
    request.fields['amount'] = amountController.text;

    request.files.add(
      await http.MultipartFile.fromPath('documents', documentFile!.path),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'face_image',
        faceImage!.path,
        contentType: MediaType('image', 'jpg'),
      ),
    );

    var response = await request.send();

    setState(() => loading = false);

    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: "Loan Request Sent Successfully");

      // Reset form
      amountController.clear();
      setState(() {
        documentFile = null;
        faceImage = null;
        _amountError = null;
      });

      Navigator.pop(context); // close bottom sheet
      fetchLoanRequests(); // refresh list
    } else {
      Fluttertoast.showToast(msg: "Failed to send request");
    }
  }

  // ── OPEN REQUEST BOTTOM SHEET ──────────────────────────────
  void _openRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Handle ──────────────────────────
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
                      const SizedBox(height: 20),

                      // ── Header ───────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0A0A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.credit_score_outlined,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'New Loan Request',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0A0A0A),
                                  ),
                                ),
                                Text(
                                  widget.loanName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFAAAAAA),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Amount ───────────────────────────
                      _sheetLabel('Requested Amount'),
                      const SizedBox(height: 8),
                      _buildAmountField(setSheetState),
                      const SizedBox(height: 20),

                      // ── Document ─────────────────────────
                      _sheetLabel('Supporting Document'),
                      const SizedBox(height: 8),
                      _buildUploadTile(
                        label: documentFile != null
                            ? documentFile!.path.split('/').last
                            : 'Upload Document',
                        subtitle: documentFile != null
                            ? 'Tap to change'
                            : 'PDF, DOC, JPG up to 10MB',
                        icon: Icons.upload_file_outlined,
                        isSelected: documentFile != null,
                        onTap: () async {
                          await pickDocument();
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Face Image ───────────────────────
                      _sheetLabel('Face / Identity Image'),
                      const SizedBox(height: 8),
                      _buildFaceImageTile(setSheetState),
                      const SizedBox(height: 28),

                      // ── Submit ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () async {
                            await sendRequest();
                            setSheetState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A0A0A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF555555),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios,
                                  size: 13, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── AMOUNT FIELD ─────────────────────────────────────────────
  Widget _buildAmountField(StateSetter setSheetState) {
    final bool hasError = _amountError != null;
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
            controller: amountController,
            keyboardType: TextInputType.number,
            onChanged: (_) {
              setState(() => _amountError = null);
              setSheetState(() {});
            },
            style: const TextStyle(
                color: Color(0xFF0A0A0A),
                fontSize: 14,
                fontWeight: FontWeight.w400),
            decoration: const InputDecoration(
              hintText: 'Enter requested amount',
              hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
              prefixIcon: Icon(Icons.attach_money_rounded,
                  color: Color(0xFF999999), size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
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
                _amountError!,
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

  // ── UPLOAD TILE ──────────────────────────────────────────────
  Widget _buildUploadTile({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0A0A0A)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 1.5 : 1.2,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0A0A0A)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : const Color(0xFF999999),
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFF555555),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFFBBBBBB))),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_outline_rounded
                  : Icons.chevron_right_rounded,
              color: isSelected
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFCCCCCC),
              size: 20,
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }

  // ── FACE IMAGE TILE ──────────────────────────────────────────
  Widget _buildFaceImageTile(StateSetter setSheetState) {
    return GestureDetector(
      onTap: () {
        _showImageSourcePicker();
        setSheetState(() {});
      },
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: faceImage != null
                ? const Color(0xFF0A0A0A)
                : const Color(0xFFE0E0E0),
            width: faceImage != null ? 1.5 : 1.2,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            faceImage != null
                ? CircleAvatar(
              radius: 26,
              backgroundImage: FileImage(faceImage!),
            )
                : Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(Icons.face_outlined,
                  color: Color(0xFF999999), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faceImage != null
                        ? 'Image Selected'
                        : 'Upload Face Image',
                    style: TextStyle(
                      color: faceImage != null
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFF555555),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    faceImage != null
                        ? 'Tap to change'
                        : 'Camera or Gallery — Clear face required',
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
    );
  }

  // ── STATUS BADGE ─────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = const Color(0xFFE6F4EA);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'rejected':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        icon = Icons.cancel_outlined;
        break;
      default:
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFF57F17);
        icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── LOAN REQUEST CARD ────────────────────────────────────────
  Widget _buildLoanCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_score_outlined,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['loan_type'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['bank'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(item['status'] ?? 'pending'),
              ],
            ),
          ),

          // ── Card body ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    icon: Icons.attach_money_rounded,
                    label: 'Amount',
                    value: '₹ ${item['amount']}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: item['date'] ?? '',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF999999)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFAAAAAA),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A0A0A),
              ),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

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
            child: const Icon(Icons.credit_card_off_outlined,
                size: 32, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Loan Requests Yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the + button to apply for a loan',
            style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      floatingActionButton: isFetching
          ? null
          : FloatingActionButton(
        onPressed: _openRequestSheet,
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
      body: isFetching
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0A0A0A),
          strokeWidth: 2.5,
        ),
      )
          : loanRequests.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: loanRequests.length,
        itemBuilder: (context, index) {
          return _buildLoanCard(loanRequests[index]);
        },
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
          child: Text(
            widget.loanName,
            style: const TextStyle(
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

  Widget _sheetLabel(String text) {
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

// ═══════════════════════════════════════════════════════════════
//  PICKER OPTION
// ═══════════════════════════════════════════════════════════════
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
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }
}