import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ════════════════════════════════════════════════════════════════
//  DOCUMENT UPLOAD PAGE
// ════════════════════════════════════════════════════════════════
class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;

  int? _uploadedDocId;
  String? _aiSummary;

  // ── PICK FILE ────────────────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
        _aiSummary = null;
        _uploadedDocId = null;
      });
    }
  }

  // ── UPLOAD ───────────────────────────────────────────────────
  Future<void> _uploadDocument() async {
    if (_selectedFile == null) {
      Fluttertoast.showToast(msg: "Please select a file first");
      return;
    }
    setState(() => _isUploading = true);
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');
      String? lid = sh.getString('lid');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$url/upload_document_ai_summary/'),
      );
      request.fields['lid'] = lid ?? '';
      request.files.add(
        await http.MultipartFile.fromPath('document', _selectedFile!.path),
      );

      final response =
      await http.Response.fromStream(await request.send());
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          _aiSummary = jsonData['summary'];
          _uploadedDocId = jsonData['doc_id'];
        });
        Fluttertoast.showToast(msg: "Document uploaded successfully");
      } else {
        Fluttertoast.showToast(msg: "Upload failed. Try again.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection Error");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ── NAVIGATE TO PAST SUMMARIES ───────────────────────────────
  void _openPastSummaries() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PastSummariesPage()),
    );
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
              _buildInfoCard(),
              _buildUploadCard(),
              if (_aiSummary != null) SummaryCard(summary: _aiSummary!),
              const SizedBox(height: 24),
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
      actions: [
        IconButton(
          tooltip: 'Past Summaries',
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history_outlined,
                color: Colors.white, size: 18),
          ),
          onPressed: _openPastSummaries,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: const Text(
            'Document Upload',
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
              offset: const Offset(0, 6)),
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
            child: const Icon(Icons.auto_awesome_outlined,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI-Powered Analysis',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                  'Upload a document and get an instant AI summary',
                  style: TextStyle(
                      color: Color(0xFF888888), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── UPLOAD CARD ──────────────────────────────────────────────
  Widget _buildUploadCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Select Document'),
          const SizedBox(height: 16),

          // Drop zone
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedFile != null
                      ? const Color(0xFF0A0A0A)
                      : const Color(0xFFE0E0E0),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _selectedFile != null
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _selectedFile != null
                          ? Icons.insert_drive_file_outlined
                          : Icons.cloud_upload_outlined,
                      color: _selectedFile != null
                          ? Colors.white
                          : const Color(0xFF999999),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFileName ?? 'Tap to select a file',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedFile != null
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: _selectedFile != null
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFFAAAAAA),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'PDF · DOC · DOCX · TXT · JPG · PNG',
                    style:
                    TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Buttons row
          Row(
            children: [
              // Upload & Analyse
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF555555),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_outlined,
                            size: 17, color: Colors.white),
                        SizedBox(width: 7),
                        Text(' Analyse',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // History button
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _openPastSummaries,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A0A0A),
                    side: const BorderSide(
                        color: Color(0xFF0A0A0A), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history_outlined, size: 17),
                      SizedBox(width: 6),
                      Text('History',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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

// ════════════════════════════════════════════════════════════════
//  REUSABLE SUMMARY CARD
// ════════════════════════════════════════════════════════════════
class SummaryCard extends StatelessWidget {
  final String summary;
  const SummaryCard({super.key, required this.summary});

  static const _headings = [
    'Description:',
    'Main Points:',
    'Detailed Explanation:',
    'Final Summary:',
  ];

  static const _icons = {
    'Description:': Icons.description_outlined,
    'Main Points:': Icons.list_alt_outlined,
    'Detailed Explanation:': Icons.analytics_outlined,
    'Final Summary:': Icons.summarize_outlined,
  };

  List<_SummarySection> _parse() {
    final sections = <_SummarySection>[];
    int currentStart = 0;
    String? currentHeading;

    for (int i = 0; i < summary.length; i++) {
      for (final h in _headings) {
        if (summary.startsWith(h, i)) {
          if (currentHeading != null) {
            sections.add(_SummarySection(
              heading: currentHeading,
              content: summary.substring(currentStart, i).trim(),
              icon: _icons[currentHeading] ?? Icons.info_outline,
            ));
          }
          currentHeading = h;
          currentStart = i + h.length;
        }
      }
    }
    if (currentHeading != null) {
      sections.add(_SummarySection(
        heading: currentHeading,
        content: summary.substring(currentStart).trim(),
        icon: _icons[currentHeading] ?? Icons.info_outline,
      ));
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parse();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
          // Dark header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
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
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Document Summary',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Generated by Gemini AI',
                        style: TextStyle(
                            color: Color(0xFF888888), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Sections
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: _RawLines(text: summary),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sections.length,
              separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Color(0xFFF0F0F0),
                  indent: 24,
                  endIndent: 24),
              itemBuilder: (_, i) => _SectionTile(section: sections[i]),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Section tile ─────────────────────────────────────────────
class _SectionTile extends StatelessWidget {
  final _SummarySection section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    final lines = section.content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final isBullet = section.heading == 'Main Points:';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(section.icon,
                    size: 17, color: const Color(0xFF0A0A0A)),
              ),
              const SizedBox(width: 10),
              Text(
                section.heading.replaceAll(':', '').trim(),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: 0.2),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content lines
          ...lines.map((line) {
            final cleanLine =
            line.replaceFirst(RegExp(r'^[•\-]\s*'), '').trim();

            if (isBullet) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(cleanLine,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                              height: 1.55)),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(cleanLine,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF444444),
                      height: 1.6)),
            );
          }),
        ],
      ),
    );
  }
}

// ── Raw lines fallback ────────────────────────────────────────
class _RawLines extends StatelessWidget {
  final String text;
  const _RawLines({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((line) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(line,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF444444),
                      height: 1.55)),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  PAST SUMMARIES LIST PAGE
// ════════════════════════════════════════════════════════════════
class PastSummariesPage extends StatefulWidget {
  const PastSummariesPage({super.key});

  @override
  State<PastSummariesPage> createState() => _PastSummariesPageState();
}

class _PastSummariesPageState extends State<PastSummariesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }
  Future<void> _fetchDocuments() async {
    setState(() => _isLoading = true);

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');
      String? lid = sh.getString('lid');

      final response = await http.post(
        Uri.parse('$url/list_user_documents/'),
        body: {'lid': lid},
      );

      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          _documents =
          List<Map<String, dynamic>>.from(jsonData['documents']);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection Error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openDetail(Map<String, dynamic> doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailPage(
          docId: doc['id'],
          fileName: doc['file_name'] ?? 'Document',
          uploadedAt: doc['uploaded_at'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF0A0A0A), strokeWidth: 2.5))
            : _documents.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
          onRefresh: _fetchDocuments,
          color: const Color(0xFF0A0A0A),
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _documents.length,
            itemBuilder: (_, i) =>
                _buildDocumentTile(_documents[i]),
          ),
        ),
      ),
    );
  }

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
          child: Row(
            children: [
              const Text('Past Summaries',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3)),
              const Spacer(),
              if (_documents.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_documents.length} docs',
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

  Widget _buildDocumentTile(Map<String, dynamic> doc) {
    final name = (doc['file_name'] ?? 'Document').toString();
    final date = (doc['uploaded_at'] ?? '').toString();

    final ext = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    IconData fileIcon = Icons.insert_drive_file_outlined;
    Color iconBg = const Color(0xFF0A0A0A);
    if (ext == 'pdf') {
      fileIcon = Icons.picture_as_pdf_outlined;
      iconBg = const Color(0xFF1A1A1A);
    } else if (['jpg', 'jpeg', 'png'].contains(ext)) {
      fileIcon = Icons.image_outlined;
      iconBg = const Color(0xFF2A2A2A);
    } else if (['doc', 'docx'].contains(ext)) {
      fileIcon = Icons.article_outlined;
    }

    return GestureDetector(
      onTap: () => _openDetail(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // File icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(fileIcon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0A0A0A)),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined,
                          size: 11, color: Color(0xFFAAAAAA)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFAAAAAA))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 10, color: Color(0xFF555555)),
                        SizedBox(width: 4),
                        Text('AI Summary Available',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_outlined,
                color: Color(0xFFCCCCCC), size: 22),
          ],
        ),
      ),
    );
  }

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
            child: const Icon(Icons.folder_open_outlined,
                size: 34, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 16),
          const Text('No documents yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A0A0A))),
          const SizedBox(height: 6),
          const Text('Upload a document to get an AI summary',
              style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  DOCUMENT DETAIL PAGE
// ════════════════════════════════════════════════════════════════
class DocumentDetailPage extends StatefulWidget {
  final int docId;
  final String fileName;
  final String uploadedAt;

  const DocumentDetailPage({
    super.key,
    required this.docId,
    required this.fileName,
    required this.uploadedAt,
  });

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  bool _isLoading = true;
  String? _summary;
  String? _fileUrl;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() => _isLoading = true);
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String? url = sh.getString('url');

      final response = await http.post(
        Uri.parse('$url/view_document_ai_summary/'),
        body: {'doc_id': widget.docId.toString()},
      );

      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] == 'ok') {
        setState(() {
          _summary = jsonData['summary'];
          _fileUrl = jsonData['file'];
        });
      } else {
        Fluttertoast.showToast(msg: "Could not load summary");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection Error");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(
            child: CircularProgressIndicator(
                color: Color(0xFF0A0A0A), strokeWidth: 2.5))
            : SingleChildScrollView(
          child: Column(
            children: [
              _buildFileInfoCard(),
              if (_summary != null) ...[
                const SizedBox(height: 4),
                SummaryCard(summary: _summary!),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

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
          child: const Text('Document Details',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
        ),
      ),
    );
  }

  Widget _buildFileInfoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 6)),
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
            child: const Icon(Icons.insert_drive_file_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        size: 11, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(widget.uploadedAt,
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  DATA MODEL
// ════════════════════════════════════════════════════════════════
class _SummarySection {
  final String heading;
  final String content;
  final IconData icon;
  _SummarySection(
      {required this.heading, required this.content, required this.icon});
}