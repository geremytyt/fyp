import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_travel_mate/Staff/staffViewBookingDetails.dart';

class ManageBooking extends StatefulWidget {
  @override
  _ManageBookingState createState() => _ManageBookingState();
}

class _ManageBookingState extends State<ManageBooking> {
  late CollectionReference booking;

  @override
  void initState() {
    super.initState();
    booking = FirebaseFirestore.instance.collection('booking');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage Bookings'),
          backgroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Refund Requests'),
              Tab(text: 'Refunded'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Active Bookings Tab
            BookingList(status: 'active'),

            // Refund Requests Tab
            BookingList(status: 'refund'),

            // Refunded Tab
            BookingList(status: 'refunded'),
          ],
        ),
      ),
    );
  }
}

class BookingList extends StatelessWidget {
  final String status;

  BookingList({required this.status});

  Future<String> fetchPoiID(String tripID) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> ticketSnapshot =
      await FirebaseFirestore.instance.collection('ticket').doc(tripID).get();

      if (ticketSnapshot.exists) {
        return ticketSnapshot['poiID'] ?? '';
      } else {
        print('Ticket document does not exist for tripID: $tripID');
        return '';
      }
    } catch (e) {
      print('Error fetching poiID from ticket: $e');
      return '';
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchBookings(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error fetching bookings: ${snapshot.error}'));
        } else {
          // Display the booking list
          return ListView.builder(
            itemCount: snapshot.data?.length,
            itemBuilder: (context, index) {
              var bookingData = snapshot.data?[index];

              return GestureDetector(
                onTap: () async {
                  // Retrieve poiID based on the tripID in the ticket collection
                  String tripID = bookingData?['ticketID'] ?? '';
                  String poiID = await fetchPoiID(tripID);

                  // Navigate to StaffViewBookingDetailsPage when a booking is tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StaffViewBookingDetailsPage(
                        bookingID: bookingData?['bookingID'],
                        poiID: poiID,
                      ),
                    ),
                  );
                },
                child: ListTile(
                  title: Text('Booking ID: ${bookingData?['bookingID']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${bookingData?['bookingDate']}'),
                      Text('Ticket ID: ${bookingData?['ticketID']}'),
                      Text('User ID: ${bookingData?['userID']}'),
                    ],
                  ),
                  // Additional UI components or actions based on your requirements
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchBookings(String status) async {
    try {
      // Fetch booking data from Firestore based on status
      QuerySnapshot bookingSnapshot =
      await FirebaseFirestore.instance.collection('booking').where('bookingStatus', isEqualTo: status).get();

      // Process booking data
      List<Map<String, dynamic>> bookingData = bookingSnapshot.docs
          .map((DocumentSnapshot document) => document.data() as Map<String, dynamic>)
          .toList();

      return bookingData;
    } catch (e) {
      // Handle errors
      print('Error fetching bookings: $e');
      return [];
    }
  }
}
