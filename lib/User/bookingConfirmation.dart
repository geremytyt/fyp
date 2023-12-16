import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mailer/smtp_server/gmail.dart';
import 'package:flutter_mailer/flutter_mailer.dart';
import 'package:shared_preferences/shared_preferences.dart';



class BookingConfirmation extends StatefulWidget {
  final String poiName;
  final String poiID;
  final String ticketID;
  final String ticketDate;
  final int adultTicketQty;
  final int childTicketQty;
  final double totalPrice;
  final String cardNo;
  final String bookingID;
  final String paymentID;

  BookingConfirmation({
    required this.poiName,
    required this.poiID,
    required this.ticketID,
    required this.ticketDate,
    required this.adultTicketQty,
    required this.childTicketQty,
    required this.totalPrice,
    required this.cardNo,
    required this.bookingID,
    required this.paymentID,
  });

  @override
  _BookingConfirmationState createState() => _BookingConfirmationState();
}

class _BookingConfirmationState extends State<BookingConfirmation> {
  String userId = '';
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
  super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Confirmed'),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    // Fetch and display booking details
                    FutureBuilder<Map<String, dynamic>>(
                      future: fetchBookingDetails(widget.bookingID),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error fetching booking details: ${snapshot.error}');
                        } else {
                          Map<String, dynamic> bookingDetails = snapshot.data ?? {};
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(widget.poiName),
                                subtitle: Text('Booking ID: ${bookingDetails['bookingID']}'),
                              ),
                              ListTile(
                                title: Text('Ticket ID: ${bookingDetails['ticketID']}'),
                                subtitle: Text('Booking Date: ${bookingDetails['bookingDate']}'),
                              ),
                              ListTile(
                                title: Text('Adult Ticket Quantity: ${bookingDetails['bookingAdultQty']}'),
                                subtitle: Text('Child Ticket Quantity: ${bookingDetails['bookingChildQty']}'),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.0),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    // Fetch and display payment details
                    FutureBuilder<Map<String, dynamic>>(
                      future: fetchPaymentDetails(widget.paymentID),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Text('Error fetching payment details: ${snapshot.error}');
                        } else {
                          Map<String, dynamic> paymentDetails = snapshot.data ?? {};
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text('Payment ID: ${paymentDetails['paymentID']}'),
                                subtitle: Text('Payment Date: ${paymentDetails['paymentDateTime']}'),
                              ),
                              ListTile(
                                title: Text('Payment Amount: ${paymentDetails['paymentAmount']}'),
                                subtitle: Text('Card Number: ${paymentDetails['cardNo']}'),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.0),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/viewBookingsPage');
                },
                child: Text('Proceed'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> fetchUserDataFromFirestore(String email) async {
    try {
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('user');

      // Fetch the user data using the user's email
      QuerySnapshot querySnapshot = await usersCollection.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;

        // Convert the data to a Map<String, dynamic>
        Map<String, dynamic> userData = documentSnapshot.data() as Map<String, dynamic>;


        userId = userData['userID']?.toString() ?? '';
        userEmail= email;
        userName=userData['name']?.toString() ?? '';

      } else {
        print('User not found.');
      }
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email') ?? '';

    print('${email}is found');
    if (email.isNotEmpty) {
      await fetchUserDataFromFirestore(email);
      print('User ID: $userId');
    }
  }


  Future<Map<String, dynamic>> fetchBookingDetails(String bookingID) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> bookingSnapshot =
      await FirebaseFirestore.instance.collection('booking').doc(bookingID).get();

      if (bookingSnapshot.exists) {
        return bookingSnapshot.data() ?? {};
      } else {
        // Handle the case where the booking document does not exist
        print('Booking document does not exist for ID: $bookingID');
        return {};
      }
    } catch (e) {
      // Handle any errors that might occur during the process
      print('Error fetching booking details: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchPaymentDetails(String paymentID) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> paymentSnapshot =
      await FirebaseFirestore.instance.collection('payment').doc(paymentID).get();

      if (paymentSnapshot.exists) {
        return paymentSnapshot.data() ?? {};
      } else {
        // Handle the case where the payment document does not exist
        print('Payment document does not exist for ID: $paymentID');
        return {};
      }
    } catch (e) {
      // Handle any errors that might occur during the process
      print('Error fetching payment details: $e');
      return {};
    }
  }

  // Future<void> sendEmailWithInvoice() async {
  //   // Generate the invoice content
  //   String? invoiceContent = await generateInvoice();
  //   if (invoiceContent == null) {
  //     print('Failed to generate invoice.');
  //     return;
  //   }
  //
  //   // Get the temporary directory
  //   Directory tempDir = await getTemporaryDirectory();
  //
  //   // Create a temporary file in the temporary directory
  //   File tempFile = File('${tempDir.path}/temp_invoice.pdf');
  //   await tempFile.writeAsBytes(Uint8List.fromList(utf8.encode(invoiceContent)));
  //
  //   final MailOptions mailOptions = MailOptions(
  //     body: 'Please find the attached invoice.',
  //     subject: 'Invoice from Your Company',
  //     recipients: [email], // User's email
  //     attachments: [tempFile.path],
  //     isHTML: false,
  //   );
  //
  //   try {
  //     await FlutterMailer.send(mailOptions);
  //   } catch (error) {
  //     print('Error sending email: $error');
  //   } finally {
  //     // Delete the temporary file after sending the email
  //     await tempFile.delete();
  //   }
  // }
  //
  // Future<String?> generateInvoice() async {
  //   final apiUrl = 'https://app.useanvil.com/api/v1/generate-pdf';
  //   final apiKey = 'g3eY7xrqMpiPX15zi0vRgDK2gtllcB8g';
  //
  //   // Construct Basic Authorization header
  //   final basicAuth = 'Basic ' + base64Encode(utf8.encode('$apiKey:'));
  //
  //   Map<String, dynamic> requestData = {
  //     'title': 'Hello',
  //     'data': [
  //       {'label': 'Hello World', 'content': 'I like turtles'}
  //     ],
  //   };
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': basicAuth,
  //       },
  //       body: jsonEncode(requestData),
  //     );
  //
  //     if (response.statusCode == 200) {
  //       // Successfully received the PDF
  //       return response.body;
  //     } else {
  //       // Handle errors
  //       print('Failed to generate PDF. Status code: ${response.statusCode}');
  //       print('Response body: ${response.body}');
  //       return null;
  //     }
  //   } catch (error) {
  //     // Handle network or other errors
  //     print('Error generating PDF: $error');
  //     return null;
  //   }
  // }

}

