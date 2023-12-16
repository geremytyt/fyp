import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'bookingDetailsPage.dart';

class POI {
  final String poiID;
  final String poiType;
  final String poiName;
  final String poiAddress;
  final String poiLocation;
  final String poiUrl;
  final String poiPriceRange;
  final String poiPrice;
  final String poiPhone;
  final String poiTag;
  final String poiOperatingHours;
  final String poiRating;
  final String poiNoOfReviews;
  final String poiDescription;
  final double poiLatitude;
  final double poiLongitude;

  POI({
    required this.poiID,
    required this.poiType,
    required this.poiName,
    required this.poiAddress,
    required this.poiLocation,
    required this.poiUrl,
    required this.poiPriceRange,
    required this.poiPrice,
    required this.poiPhone,
    required this.poiTag,
    required this.poiOperatingHours,
    required this.poiRating,
    required this.poiNoOfReviews,
    required this.poiDescription,
    required this.poiLatitude,
    required this.poiLongitude,
  });
}

class ViewBookingsPage extends StatefulWidget {
  @override
  _ViewBookingsState createState() => _ViewBookingsState();
}

class _ViewBookingsState extends State<ViewBookingsPage> {
  late String userId;
  late String bookingID;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    // Fetch additional user data from Firestore based on the stored email
    if (email.isNotEmpty) {
      await fetchUserDataFromFirestore(email);
    }
  }

  Future<void> fetchUserDataFromFirestore(String email) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final userSnapshot = await firestore
          .collection('user')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        final userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        final fetchedUserId = userData['userID'] ?? '';

        setState(() {
          userId = fetchedUserId;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchBookingsByUserId(String userId) async {
    try {
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('booking')
          .where('userID', isEqualTo: userId)
          .get();

      if (bookingsSnapshot.docs.isNotEmpty) {
        return bookingsSnapshot.docs.map((doc) => doc.data()).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> filterBookingsByDate(
      List<Map<String, dynamic>> bookings, bool upcoming) {
    final currentDate = DateTime.now();

    return bookings.where((booking) {
      final bookingDate = DateTime.parse(booking['bookingDate']);
      return upcoming
          ? bookingDate.isAfter(currentDate)
          : bookingDate.isBefore(currentDate);
    }).toList();
  }

  Widget buildBookingsList(BuildContext context, bool upcoming) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchBookingsByUserId(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error fetching bookings: ${snapshot.error}');
        } else {
          final allBookings = snapshot.data ?? [];
          final filteredBookings = filterBookingsByDate(allBookings, upcoming);

          return ListView.builder(
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];

              // Fetch ticket details to get the poiID
              return FutureBuilder<Map<String, dynamic>>(
                future: fetchTicketDetails(booking['ticketID']),
                builder: (context, ticketSnapshot) {
                  if (ticketSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (ticketSnapshot.hasError) {
                    return Text('Error fetching ticket details: ${ticketSnapshot.error}');
                  } else {
                    final ticketDetails = ticketSnapshot.data ?? {};

                    // Fetch POI details using the retrieved poiID
                    return FutureBuilder<POI>(
                      future: fetchPoiDetails(ticketDetails['poiID']),
                      builder: (context, poiSnapshot) {
                        if (poiSnapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (poiSnapshot.hasError) {
                          return Text('Error fetching POI details: ${poiSnapshot.error}');
                        } else {
                          final poiDetails = poiSnapshot.data;
                          bookingID=booking['bookingID'];

                          // Check if the bookingDate is less than a week away
                          final bookingDate = DateTime.parse(booking['bookingDate']);
                          final now = DateTime.now();
                          final difference = bookingDate.difference(now);

                          // Build your UI with booking and POI details
                          return GestureDetector(
                            onTap: () {
                              // Navigate to ViewBookingDetailsPage with bookingID and poiID
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewBookingDetailsPage(
                                    bookingID: booking['bookingID'],
                                    poiID: ticketDetails['poiID'],
                                  ),
                                ),
                              );
                            },
                            child: ListTile(
                              title: Text('POI Name: ${poiDetails!.poiName}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Booking ID: ${booking['bookingID']}'),
                                  Text('Booking Date: ${booking['bookingDate']}'),
                                ],
                              ),
                              // Add a condition to disable the refund button
                              trailing: difference.inDays < 7
                                  ? null // Enable the refund button
                                  : IconButton(
                                icon: Icon(Icons.money_off),
                                onPressed: () {
                                  // Show refund request dialog when the button is pressed
                                  requestRefund(booking['bookingID']);
                                },
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }


  Future<Map<String, dynamic>> fetchTicketDetails(String ticketID) async {
    try {
      final ticketSnapshot = await FirebaseFirestore.instance
          .collection('ticket')
          .doc(ticketID)
          .get();

      if (ticketSnapshot.exists) {
        return ticketSnapshot.data() ?? {};
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching ticket details: $e');
      return {};
    }
  }

  String getRefundStatus(String bookingStatus) {
    if (bookingStatus == 'refund') {
      return 'Pending';
    } else if (bookingStatus == 'refunded') {
      return 'Approved';
    } else {
      return '';
    }
  }

  Widget buildRefundList(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchRefundBookingsByUserId(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error fetching refund bookings: ${snapshot.error}');
        } else {
          final refundBookings = snapshot.data ?? [];

          return ListView.builder(
            itemCount: refundBookings.length,
            itemBuilder: (context, index) {
              final refundBooking = refundBookings[index];

              // Fetch ticket details to get the poiID
              return FutureBuilder<Map<String, dynamic>>(
                future: fetchTicketDetails(refundBooking['ticketID']),
                builder: (context, ticketSnapshot) {
                  if (ticketSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (ticketSnapshot.hasError) {
                    return Text('Error fetching ticket details: ${ticketSnapshot.error}');
                  } else {
                    final ticketDetails = ticketSnapshot.data ?? {};

                    // Fetch POI details using the retrieved poiID
                    return FutureBuilder<POI>(
                      future: fetchPoiDetails(ticketDetails['poiID']),
                      builder: (context, poiSnapshot) {
                        if (poiSnapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (poiSnapshot.hasError) {
                          return Text('Error fetching POI details: ${poiSnapshot.error}');
                        } else {
                          final poiDetails = poiSnapshot.data;

                          return ListTile(
                            title: Text('POI Name: ${poiDetails!.poiName}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Booking ID: ${refundBooking['bookingID']}'),
                                Text('Booking Date: ${refundBooking['bookingDate']}'),
                                Text('Refund Status: ${getRefundStatus(refundBooking['bookingStatus'])}'),
                              ],
                            ),
                          );
                        }
                      },
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchRefundBookingsByUserId(String userId) async {
    try {
      final refundBookingsSnapshot = await FirebaseFirestore.instance
          .collection('booking')
          .where('userID', isEqualTo: userId)
          .where('bookingStatus', whereIn: ['refund', 'refunded'])
          .get();

      if (refundBookingsSnapshot.docs.isNotEmpty) {
        return refundBookingsSnapshot.docs.map((doc) => doc.data()).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching refund bookings: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bookings'),
          backgroundColor: Theme.of(context).primaryColor,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
              Tab(text: 'Refund'),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushNamed(context, '/home');
            },
          ),
        ),
        body: TabBarView(
          children: [
            buildBookingsList(context, true),
            buildBookingsList(context, false),
            buildRefundList(context),
          ],
        ),
      ),
    );
  }

  Future<void> requestRefund(String bookingID) async {
    String refundReason = ''; // Initialize with an empty string

    // Show a dialog to get refund reason
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Request Refund'),
          content: TextField(
            maxLength: 100,
            onChanged: (value) {
              refundReason = value;
            },
            decoration: InputDecoration(labelText: 'Reason (Max 100 characters)'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update refundRequest and bookingStatus in Firestore
                await updateRefundRequestAndStatus(bookingID, refundReason);
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<POI> fetchPoiDetails(String poiID) async {
    try {
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_based_on_id?query=$poiID'));

      if (response.statusCode == 200) {
        // Parse the response body
        List<dynamic> responseDataList = json.decode(response.body);

        if (responseDataList.isNotEmpty) {
          // Extract the first element from the list
          dynamic responseData = responseDataList[0];

          if (responseData is Map<String, dynamic>) {
            // If the response is a map, create a POI instance
            return POI(
              poiID: responseData['poiID']?.toString() ?? '',
              poiName: responseData['poiName']?.toString() ?? '',
              poiAddress: responseData['poiAddress']?.toString() ?? '',
              poiLocation: responseData['poiLocation']?.toString() ?? '',
              poiPrice: responseData['poiPrice']?.toString() ?? '',
              poiRating: responseData['poiRating']?.toString() ?? '',
              poiTag: responseData['poiTag']?.toString() ?? '',
              poiNoOfReviews: responseData['poiNoOfReviews']?.toString() ?? '',
              poiType: responseData['poiType']?.toString() ?? '',
              poiUrl: responseData['poiUrl']?.toString() ?? '',
              poiPhone: responseData['poiPhone']?.toString() ?? '',
              poiOperatingHours: responseData['poiOperatingHours']?.toString() ?? '',
              poiDescription: responseData['poiDescription']?.toString() ?? '',
              poiPriceRange: responseData['poiPriceRange']?.toString() ?? '',
              poiLatitude: responseData['poiLatitude']?.toDouble() ?? 0.0,
              poiLongitude: responseData['poiLongitude']?.toDouble() ?? 0.0,
            );
          } else {
            // Handle the case where the first element is not a map, if needed
            print('Unexpected response format. First element is not a map: $responseData');
          }
        } else {
          // Handle the case where the list is empty
          print('Unexpected response format. Empty list.');
        }
      } else {
        // Handle the case where the response status code is not 200
        print('Failed to fetch POI data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any exceptions that might occur during the process
      print('Error fetching POI data: $e');
    }

    // Return an empty POI instance if there's an error
    return POI(
      poiID: '',
      poiType: '',
      poiName: '',
      poiAddress: '',
      poiLocation: '',
      poiPrice: '',
      poiRating: '',
      poiTag: '',
      poiNoOfReviews: '',
      poiUrl: '',
      poiPhone: '',
      poiOperatingHours: '',
      poiDescription: '',
      poiPriceRange: '',
      poiLatitude: 0.0,
      poiLongitude: 0.0,
    );
  }

  Future<void> updateRefundRequestAndStatus(
      String bookingID, String refundReason) async {
    try {
      // Update refundRequest and bookingStatus in Firestore
      await FirebaseFirestore.instance
          .collection('booking')
          .doc(bookingID)
          .update({
        'refundRequest': refundReason,
        'bookingStatus': 'refund',
      });

      print('Refund request submitted successfully.');
    } catch (e) {
      print('Error submitting refund request: $e');
    }
  }

}
