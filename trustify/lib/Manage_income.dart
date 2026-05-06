//
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
//
// class ManageIncomePage extends StatefulWidget {
//   const ManageIncomePage({super.key});
//
//   @override
//   State<ManageIncomePage> createState() => _ManageIncomePageState();
// }
//
// class _ManageIncomePageState extends State<ManageIncomePage> {
//   final _formKey = GlobalKey<FormState>();
//
//   // ── Controllers (names unchanged) ──────────────────────────
//   final TextEditingController sourceController = TextEditingController();
//   final TextEditingController amountController = TextEditingController();
//   final TextEditingController dateController   = TextEditingController();
//
//   bool isLoading = false;
//
//   // Validation error strings
//   String? _sourceError;
//   String? _amountError;
//   String? _dateError;
//
//   @override
//   void dispose() {
//     sourceController.dispose();
//     amountController.dispose();
//     dateController.dispose();
//     super.dispose();
//   }
//
//   // ── PICK DATE (logic unchanged) ────────────────────────────
//   Future<void> pickDate() async {
//     DateTime? pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//       builder: (context, child) {
//         return Theme(
//           data: ThemeData.light().copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFF0A0A0A),
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Color(0xFF0A0A0A),
//             ),
//             dialogBackgroundColor: Colors.white,
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (pickedDate != null) {
//       dateController.text =
//       "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
//       setState(() => _dateError = null);
//     }
//   }
//
//   // ── VALIDATE ───────────────────────────────────────────────
//   bool _validate() {
//     setState(() {
//       _sourceError = sourceController.text.trim().isEmpty
//           ? 'Income source is required'
//           : null;
//       _amountError = amountController.text.trim().isEmpty
//           ? 'Amount is required'
//           : double.tryParse(amountController.text.trim()) == null
//           ? 'Enter a valid number'
//           : double.parse(amountController.text.trim()) <= 0
//           ? 'Amount must be greater than 0'
//           : null;
//       _dateError = dateController.text.trim().isEmpty
//           ? 'Please select a date'
//           : null;
//     });
//     return _sourceError == null &&
//         _amountError == null &&
//         _dateError == null;
//   }
//
//   // ── SUBMIT INCOME (logic unchanged) ───────────────────────
//   void submitIncome() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => isLoading = true);
//
//     await Future.delayed(const Duration(seconds: 2));
//
//     setState(() => isLoading = false);
//
//     Fluttertoast.showToast(msg: "Income Added Successfully");
//
//     sourceController.clear();
//     amountController.clear();
//     dateController.clear();
//   }
//   void send_data() async {
//
//     if (!_validate()) return;
//
//     SharedPreferences sh = await SharedPreferences.getInstance();
//
//     String? url = sh.getString('url');
//     String? lid = sh.getString('lid');
//
//     if (url == null || lid == null) {
//       Fluttertoast.showToast(msg: "Server URL not found");
//       return;
//     }
//
//     final Uri urls = Uri.parse('$url/user_manage_income/');
//
//     try {
//
//       final response = await http.post(
//         urls,
//         body: {
//           'lid': lid,
//           "source": sourceController.text,
//           "amount": amountController.text,
//           "date": dateController.text,
//         },
//       );
//
//       print(response.body);
//
//       if (response.statusCode == 200) {
//
//         var jsonData = jsonDecode(response.body);
//
//         if (jsonData['status'] == 'ok') {
//
//           Fluttertoast.showToast(msg: "Income Added Successfully");
//
//           Navigator.pop(context);
//
//         } else {
//
//           Fluttertoast.showToast(msg: "Failed");
//
//         }
//
//       }
//
//     } catch (e) {
//
//       print(e);
//
//       Fluttertoast.showToast(msg: "Connection Error");
//
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF0F0F0),
//       appBar: _buildAppBar(),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ── Summary card ─────────────────────────────
//               _buildSummaryCard(),
//
//               // ── Form ─────────────────────────────────────
//               Container(
//                 margin: const EdgeInsets.all(20),
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.06),
//                       blurRadius: 20,
//                       offset: const Offset(0, 6),
//                     ),
//                   ],
//                 ),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _sectionLabel('Income Details'),
//                       const SizedBox(height: 16),
//
//                       // ── Source ──────────────────────────
//                       _buildLabel('Income Source'),
//                       const SizedBox(height: 8),
//                       _TRUSTIFYInputField(
//                         controller: sourceController,
//                         hintText: 'e.g. Salary, Freelance, Business',
//                         icon: Icons.work_outline_rounded,
//                         errorText: _sourceError,
//                         onChanged: (_) =>
//                             setState(() => _sourceError = null),
//                         validator: (value) =>
//                         value == null || value.isEmpty
//                             ? 'Enter income source'
//                             : null,
//                       ),
//                       const SizedBox(height: 18),
//
//                       // ── Amount ──────────────────────────
//                       _buildLabel('Amount'),
//                       const SizedBox(height: 8),
//                       _TRUSTIFYInputField(
//                         controller: amountController,
//                         hintText: 'Enter amount',
//                         icon: Icons.attach_money_rounded,
//                         keyboardType: TextInputType.number,
//                         errorText: _amountError,
//                         onChanged: (_) =>
//                             setState(() => _amountError = null),
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Enter amount';
//                           }
//                           if (double.tryParse(value) == null) {
//                             return 'Enter valid number';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 18),
//
//                       // ── Date ────────────────────────────
//                       _buildLabel('Date'),
//                       const SizedBox(height: 8),
//                       _TRUSTIFYInputField(
//                         controller: dateController,
//                         hintText: 'Select date',
//                         icon: Icons.calendar_today_outlined,
//                         readOnly: true,
//                         errorText: _dateError,
//                         onTap: pickDate,
//                         validator: (value) =>
//                         value == null || value.isEmpty
//                             ? 'Select date'
//                             : null,
//                       ),
//                       const SizedBox(height: 28),
//
//                       // ── Submit button ────────────────────
//                       SizedBox(
//                         width: double.infinity,
//                         height: 54,
//                         child: ElevatedButton(
//                           onPressed: isLoading ? null : send_data,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF0A0A0A),
//                             foregroundColor: Colors.white,
//                             disabledBackgroundColor:
//                             const Color(0xFF555555),
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                           ),
//                           child: isLoading
//                               ? const SizedBox(
//                             width: 22,
//                             height: 22,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2.5,
//                             ),
//                           )
//                               : const Text(
//                             'Add Income',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               letterSpacing: 0.4,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ── APP BAR ─────────────────────────────────────────────────
//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       backgroundColor: const Color(0xFF0A0A0A),
//       elevation: 0,
//       centerTitle: true,
//       leading: IconButton(
//         icon: Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(Icons.arrow_back_ios_new,
//               color: Colors.white, size: 16),
//         ),
//         onPressed: () => Navigator.pop(context),
//       ),
//       title: const Text(
//         'TRUSTIFY',
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.w800,
//           letterSpacing: 5,
//           color: Colors.white,
//         ),
//       ),
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(48),
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
//           child: const Text(
//             'Manage Income',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//               letterSpacing: -0.3,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // ── SUMMARY CARD ─────────────────────────────────────────────
//   Widget _buildSummaryCard() {
//     return Container(
//       width: double.infinity,
//       margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0A0A0A),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.18),
//             blurRadius: 20,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 52,
//             height: 52,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Icon(
//               Icons.account_balance_wallet_outlined,
//               color: Colors.white,
//               size: 26,
//             ),
//           ),
//           const SizedBox(width: 16),
//           const Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Track Your Income',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 15,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               SizedBox(height: 4),
//               Text(
//                 'Add a new income entry below',
//                 style: TextStyle(
//                   color: Color(0xFF888888),
//                   fontSize: 12,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _sectionLabel(String text) {
//     return Row(
//       children: [
//         Container(
//           width: 3,
//           height: 13,
//           decoration: BoxDecoration(
//             color: const Color(0xFF0A0A0A),
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           text.toUpperCase(),
//           style: const TextStyle(
//             fontSize: 10.5,
//             fontWeight: FontWeight.w700,
//             letterSpacing: 1.2,
//             color: Color(0xFF888888),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildLabel(String text) {
//     return Text(
//       text,
//       style: const TextStyle(
//         fontSize: 13,
//         fontWeight: FontWeight.w600,
//         color: Color(0xFF0A0A0A),
//         letterSpacing: 0.3,
//       ),
//     );
//   }
// }
//
// // ─── TRUSTIFY Input Field ─────────────────────────────────────────
// class _TRUSTIFYInputField extends StatelessWidget {
//   final TextEditingController controller;
//   final String hintText;
//   final IconData icon;
//   final String? errorText;
//   final bool obscureText;
//   final bool readOnly;
//   final Widget? suffixWidget;
//   final TextInputType? keyboardType;
//   final ValueChanged<String>? onChanged;
//   final VoidCallback? onTap;
//   final FormFieldValidator<String>? validator;
//
//   const _TRUSTIFYInputField({
//     required this.controller,
//     required this.hintText,
//     required this.icon,
//     this.errorText,
//     this.obscureText = false,
//     this.readOnly = false,
//     this.suffixWidget,
//     this.keyboardType,
//     this.onChanged,
//     this.onTap,
//     this.validator,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final bool hasError = errorText != null && errorText!.isNotEmpty;
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           height: 52,
//           decoration: BoxDecoration(
//             color: const Color(0xFFF8F8F8),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: hasError
//                   ? const Color(0xFFFF3B30)
//                   : const Color(0xFFE0E0E0),
//               width: 1.2,
//             ),
//           ),
//           child: TextFormField(
//             controller: controller,
//             obscureText: obscureText,
//             readOnly: readOnly,
//             keyboardType: keyboardType,
//             onChanged: onChanged,
//             onTap: onTap,
//             validator: validator,
//             style: const TextStyle(
//               color: Color(0xFF0A0A0A),
//               fontSize: 14,
//               fontWeight: FontWeight.w400,
//             ),
//             decoration: InputDecoration(
//               hintText: hintText,
//               hintStyle: const TextStyle(
//                   color: Color(0xFFBBBBBB), fontSize: 14),
//               prefixIcon:
//               Icon(icon, color: const Color(0xFF999999), size: 20),
//               suffixIcon: suffixWidget != null
//                   ? Padding(
//                   padding: const EdgeInsets.only(right: 4),
//                   child: suffixWidget)
//                   : null,
//               border: InputBorder.none,
//               contentPadding:
//               const EdgeInsets.symmetric(vertical: 15),
//               errorStyle: const TextStyle(height: 0),
//             ),
//             cursorColor: const Color(0xFF0A0A0A),
//           ),
//         ),
//         if (hasError) ...[
//           const SizedBox(height: 5),
//           Row(
//             children: [
//               const Icon(Icons.error_outline,
//                   size: 13, color: Color(0xFFFF3B30)),
//               const SizedBox(width: 4),
//               Flexible(
//                 child: Text(
//                   errorText!,
//                   style: const TextStyle(
//                     fontSize: 11.5,
//                     color: Color(0xFFFF3B30),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ],
//     );
//   }
// }



import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ManageIncomePage extends StatefulWidget {
  const ManageIncomePage({super.key});

  @override
  State<ManageIncomePage> createState() => _ManageIncomePageState();
}

class _ManageIncomePageState extends State<ManageIncomePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController   = TextEditingController();

  // ── Dropdown ───────────────────────────────────────────────
  String? selectedSource;
  String? _sourceError;
  String? _amountError;
  String? _dateError;

  bool isLoading  = false;
  bool isFetching = false;

  List<Map<String, dynamic>> incomeList = [];

  final List<String> incomeSources = [
    'Salary',
    'Part-time Job',
    'Freelance',
    'Contract Work',
    'Business Income',
    'Self-employed',
    'Commission',
    'Rental Income',
    'Dividends',
    'Interest Income',
    'Stock / Trading',
    'Pension / Retirement',
    'Government Benefits',
    'Gifts / Inheritance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    fetchIncome();
  }

  @override
  void dispose() {
    amountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  // ── PICK DATE ──────────────────────────────────────────────
  Future<void> pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A0A0A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0A0A0A),
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      dateController.text =
      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      setState(() => _dateError = null);
    }
  }

  // ── VALIDATE ───────────────────────────────────────────────
  bool _validate() {
    setState(() {
      _sourceError = selectedSource == null ? 'Please select income source' : null;
      _amountError = amountController.text.trim().isEmpty
          ? 'Amount is required'
          : double.tryParse(amountController.text.trim()) == null
          ? 'Enter a valid number'
          : double.parse(amountController.text.trim()) <= 0
          ? 'Amount must be greater than 0'
          : null;
      _dateError = dateController.text.trim().isEmpty ? 'Please select a date' : null;
    });
    return _sourceError == null && _amountError == null && _dateError == null;
  }

  // ── SEND DATA ──────────────────────────────────────────────
  void send_data() async {
    if (!_validate()) return;

    setState(() => isLoading = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');
    String? lid = sh.getString('lid');

    if (url == null || lid == null) {
      Fluttertoast.showToast(msg: "Server URL not found");
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$url/user_manage_income/'),
        body: {
          'lid': lid,
          'source': selectedSource!,
          'amount': amountController.text,
          'date': dateController.text,
        },
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          Fluttertoast.showToast(msg: "Income Added Successfully");
          setState(() {
            selectedSource = null;
          });
          amountController.clear();
          dateController.clear();
          fetchIncome();
        } else {
          Fluttertoast.showToast(msg: "Failed to add income");
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection Error");
    }

    setState(() => isLoading = false);
  }

  // ── FETCH INCOME ───────────────────────────────────────────
  Future<void> fetchIncome() async {
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
        Uri.parse('$url/user_view_income/'),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          setState(() {
            incomeList = List<Map<String, dynamic>>.from(jsonData['data']);
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to load income");
    }

    setState(() => isFetching = false);
  }

  // ── DELETE INCOME ──────────────────────────────────────────
  Future<void> deleteIncome(String id) async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String? url = sh.getString('url');

    if (url == null) return;

    try {
      final response = await http.post(
        Uri.parse('$url/user_delete_income/'),
        body: {'id': id},
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == 'ok') {
          Fluttertoast.showToast(msg: "Income deleted");
          fetchIncome();
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Delete failed");
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
              // ── Summary card ─────────────────────────────
              _buildSummaryCard(),

              // ── Form ─────────────────────────────────────
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
                      _sectionLabel('Income Details'),
                      const SizedBox(height: 16),

                      // ── Source Dropdown ──────────────────
                      _buildLabel('Income Source'),
                      const SizedBox(height: 8),
                      _buildDropdown(),
                      const SizedBox(height: 18),

                      // ── Amount ──────────────────────────
                      _buildLabel('Amount'),
                      const SizedBox(height: 8),
                      _TRUSTIFYInputField(
                        controller: amountController,
                        hintText: 'Enter amount',
                        icon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                        errorText: _amountError,
                        onChanged: (_) => setState(() => _amountError = null),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter amount';
                          if (double.tryParse(value) == null) return 'Enter valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // ── Date ────────────────────────────
                      _buildLabel('Date'),
                      const SizedBox(height: 8),
                      _TRUSTIFYInputField(
                        controller: dateController,
                        hintText: 'Select date',
                        icon: Icons.calendar_today_outlined,
                        readOnly: true,
                        errorText: _dateError,
                        onTap: pickDate,
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Select date' : null,
                      ),
                      const SizedBox(height: 28),

                      // ── Submit button ────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : send_data,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A0A0A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF555555),
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
                              : const Text(
                            'Add Income',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Income List ───────────────────────────────
              _buildIncomeList(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── DROPDOWN ────────────────────────────────────────────────
  Widget _buildDropdown() {
    final bool hasError = _sourceError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? const Color(0xFFFF3B30) : const Color(0xFFE0E0E0),
              width: 1.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSource,
              isExpanded: true,
              hint: Row(
                children: const [
                  Icon(Icons.work_outline_rounded, color: Color(0xFF999999), size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Select income source',
                    style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                  ),
                ],
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF999999)),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              items: incomeSources.map((String source) {
                return DropdownMenuItem<String>(
                  value: source,
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline_rounded,
                          color: Color(0xFF999999), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        source,
                        style: const TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSource = value;
                  _sourceError = null;
                });
              },
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 13, color: Color(0xFFFF3B30)),
              const SizedBox(width: 4),
              Text(
                _sourceError!,
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

  // ── INCOME LIST ──────────────────────────────────────────────
  Widget _buildIncomeList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('Income History'),
              if (isFetching)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (!isFetching && incomeList.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incomeList.length,
              itemBuilder: (context, index) {
                return _buildIncomeCard(incomeList[index]);
              },
            ),
        ],
      ),
    );
  }

  // ── INCOME CARD ──────────────────────────────────────────────
  Widget _buildIncomeCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Color(0xFF0A0A0A), size: 22),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['source'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['date'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          ),

          // Amount + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹ ${item['amount']}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A0A0A),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _confirmDelete(item['id'].toString()),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFFF3B30), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CONFIRM DELETE ───────────────────────────────────────────
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Income',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text('Are you sure you want to delete this entry?',
            style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF555555))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteIncome(id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.inbox_outlined,
                  size: 28, color: Color(0xFFAAAAAA)),
            ),
            const SizedBox(height: 12),
            const Text(
              'No income records yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add your first income above',
              style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
          ],
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
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
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
            'Manage Income',
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

  // ── SUMMARY CARD ─────────────────────────────────────────────
  Widget _buildSummaryCard() {
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
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track Your Income',
                style: TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Add a new income entry below',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12),
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

// ─── TRUSTIFY Input Field ─────────────────────────────────────────
class _TRUSTIFYInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? errorText;
  final bool obscureText;
  final bool readOnly;
  final Widget? suffixWidget;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;

  const _TRUSTIFYInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.suffixWidget,
    this.keyboardType,
    this.onChanged,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? const Color(0xFFFF3B30) : const Color(0xFFE0E0E0),
              width: 1.2,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            readOnly: readOnly,
            keyboardType: keyboardType,
            onChanged: onChanged,
            onTap: onTap,
            validator: validator,
            style: const TextStyle(
                color: Color(0xFF0A0A0A), fontSize: 14, fontWeight: FontWeight.w400),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
              prefixIcon: Icon(icon, color: const Color(0xFF999999), size: 20),
              suffixIcon: suffixWidget != null
                  ? Padding(
                  padding: const EdgeInsets.only(right: 4), child: suffixWidget)
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              errorStyle: const TextStyle(height: 0),
            ),
            cursorColor: const Color(0xFF0A0A0A),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 13, color: Color(0xFFFF3B30)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  errorText!,
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