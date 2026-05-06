import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:trustify/userhome.dart';

import 'loan_request.dart';

void main() {
  runApp(const LoanTypes());
}

class LoanTypes extends StatelessWidget {
  const LoanTypes({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoanTypesPage(title: 'Loan Types'),
    );
  }
}

class LoanTypesPage extends StatefulWidget {
  const LoanTypesPage({super.key, required this.title});
  final String title;

  @override
  State<LoanTypesPage> createState() => _LoanTypeState();
}

class _LoanTypeState extends State<LoanTypesPage> {
  List<String> loan_id_ = [];
  List<String> loan_type_name_ = [];
  List<String> interest_rate_  = [];
  List<String> duration_       = [];
  List<String> details_        = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLoanTypes();
  }

  Future<void> fetchLoanTypes() async {

    try {

      SharedPreferences sh = await SharedPreferences.getInstance();

      String urls = sh.getString('url')!;
      String bankId = sh.getString('bank_id')!;

      var response = await http.post(

        Uri.parse('$urls/loan_types_by_bank/'),

        body: {
          'bank_id': bankId
        },

      );

      var jsondata = json.decode(response.body);

      if (jsondata['status'] == 'ok') {

        var arr = jsondata['data'];
        List<String> loan_id        = [];
        List<String> loan_type_name = [];
        List<String> interest_rate  = [];
        List<String> duration       = [];
        List<String> details        = [];

        for (int i = 0; i < arr.length; i++) {
          loan_id.add(arr[i]['id'].toString());
          loan_type_name.add(arr[i]['loan_type_name'].toString());
          interest_rate.add(arr[i]['interest_rate'].toString());
          duration.add(arr[i]['duration'].toString());
          details.add(arr[i]['details'].toString());

        }

        setState(() {

          loan_id_        = loan_id;
          loan_type_name_ = loan_type_name;
          interest_rate_  = interest_rate;
          duration_       = duration;
          details_        = details;

          isLoading = false;

        });

      }

    } catch (e) {

      print(e);

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

        appBar: AppBar(

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

                'Loan Types',

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),

              ),

            ),

          ),

        ),

        body: isLoading

            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0A0A0A),
          ),
        )

            : loan_type_name_.isEmpty

            ? const Center(
            child: Text("No Loan Types Available")
        )

            : ListView.builder(

          padding: const EdgeInsets.all(20),

          itemCount: loan_type_name_.length,

          itemBuilder: (context,index){

            return Container(

              margin: const EdgeInsets.only(bottom: 15),

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

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Container(

                    width: double.infinity,

                    padding: const EdgeInsets.all(20),

                    decoration: const BoxDecoration(

                      color: Color(0xFF0A0A0A),

                      borderRadius: BorderRadius.only(

                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),

                      ),

                    ),

                    child: Text(

                      loan_type_name_[index],

                      style: const TextStyle(

                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,

                      ),

                    ),

                  ),

                  Padding(

                    padding: const EdgeInsets.all(20),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(
                          "Interest : ${interest_rate_[index]} %",
                          style: const TextStyle(fontSize: 14),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Duration : ${duration_[index]} months",
                          style: const TextStyle(fontSize: 14),
                        ),

                        const SizedBox(height: 10),

                        Text(details_[index]),

                        const SizedBox(height: 20),

                        SizedBox(

                          width: double.infinity,

                          child: ElevatedButton(

                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black),

                            onPressed: () {

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoanRequestPage(
                                    loanTypeId: loan_id_[index],
                                    loanName: loan_type_name_[index],
                                  ),
                                ),
                              );

                            },

                            child: const Text("Request"),

                          ),

                        )

                      ],

                    ),

                  )

                ],

              ),

            );

          },

        ),

      ),

    );

  }

}