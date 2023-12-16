import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_travel_mate/User/viewTripHistory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_travel_mate/User/tripDetails.dart';
import 'package:my_travel_mate/User/addTrip.dart';

class TripPage extends StatefulWidget {
  @override
  _TripPageState createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  String userId='1';

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
      final userSnapshot = await firestore.collection('user').where('email', isEqualTo: email).get();

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Trips'),
          backgroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Upcoming Trips Tab
            buildTripList(context, 'upcoming'),
            // History Trips Tab
            buildTripList(context, 'history'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTrip(userId: userId),
              ),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget buildTripList(BuildContext context, String tripStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trip')
          .where('userID', isEqualTo: userId)
          .where('tripStatus', isEqualTo: tripStatus)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator(); // Display loading indicator
        }

        var trips = snapshot.data!.docs.map((doc) {
          return Trip(
            tripID: doc.id,
            tripName: doc['tripName'],
            tripStartDate: doc['tripStartDate'],
            tripEndDate: doc['tripEndDate'],
            tripStatus: doc['tripStatus'],
            tripLocation: doc['tripLocation'],
          );
        }).toList();

        return ListView.builder(
          itemCount: trips.length,
          itemBuilder: (ctx, index) {
            final trip = trips[index];

            // Check if the trip end date has passed the current date
            if (tripStatus == 'upcoming' && isTripOverdue(trip.tripEndDate)) {
              // Update trip status to 'history'
              updateTripStatusToHistory(trip.tripID);
            }

            return buildTripCard(ctx, trip);
          },
        );
      },
    );
  }

  Widget buildTripCard(BuildContext context, Trip trip) {
    String formattedDate = '${trip.tripStartDate} - ${trip.tripEndDate}';
    String locationImage = 'assets/${trip.tripLocation.toLowerCase()}.png';

    return Card(
      margin: EdgeInsets.all(10),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage(locationImage),
        ),
        title: Text(trip.tripName),
        subtitle: Text(formattedDate),
        onTap: () {
          if (trip.tripStatus == 'history') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripHistory(tripId: trip.tripID),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripDetails(tripId: trip.tripID),
              ),
            );
          }
        },
      ),
    );
  }



  bool isTripOverdue(String tripEndDate) {
    DateTime currentDate = DateTime.now();
    DateTime endDate = DateTime.parse(tripEndDate);
    return endDate.isBefore(currentDate);
  }

  Future<void> updateTripStatusToHistory(String tripId) async {
    try {
      await FirebaseFirestore.instance.collection('trip').doc(tripId).update({
        'tripStatus': 'history',
      });
    } catch (e) {
      print('Error updating trip status to history: $e');
    }
  }
}

class Trip {
  final String tripID;
  final String tripName;
  final String tripStartDate;
  final String tripEndDate;
  final String tripStatus;
  final String tripLocation;

  Trip({required this.tripID, required this.tripName, required this.tripStartDate, required this.tripEndDate, required this.tripStatus,required this.tripLocation});
}
