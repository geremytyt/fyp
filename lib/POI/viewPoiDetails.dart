import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_travel_mate/Widget/viewMap.dart';

import '../User/bookingSummary.dart';
import '../Widget/widgets.dart';


class ViewPoiDetailsPage extends StatefulWidget {
  final String poiID;

  ViewPoiDetailsPage({required this.poiID});

  @override
  _ViewPoiDetailsPageState createState() => _ViewPoiDetailsPageState();
}

class MaskedTextInputFormatter extends TextInputFormatter {
  final String mask;

  MaskedTextInputFormatter({required this.mask});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String maskedText = '';
    int maskIndex = 0;

    for (int i = 0; i < newValue.text.length; i++) {
      if (maskIndex >= mask.length) break;

      if (mask[maskIndex] == 'H' || mask[maskIndex] == 'm') {
        // Allow digits only for 'H' and 'm' in the mask
        if (RegExp(r'\d').hasMatch(newValue.text[i])) {
          maskedText += newValue.text[i];
          maskIndex++;
        }
      } else {
        // For other characters in the mask, append them as is
        maskedText += mask[maskIndex];
        maskIndex++;
      }
    }

    return TextEditingValue(
      text: maskedText,
      selection: TextSelection.collapsed(offset: maskedText.length),
    );
  }
}

class Ticket {
  final String documentID;
  final Map<String, dynamic> data;

  Ticket(this.documentID, this.data);
}

class Trip {
  final String tripID;
  final String tripName;
  final String tripStartDate;
  final String tripEndDate;
  final String tripLocation;
  final String tripStatus;
  final String userID;

  Trip({
    required this.tripID,
    required this.tripName,
    required this.tripStartDate,
    required this.tripEndDate,
    required this.tripLocation,
    required this.tripStatus,
    required this.userID,
  });
}



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
  String imageUrl;

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
    required this.imageUrl,
  });
}

class Activity {
  final String activityID;
  final String dayID;
  final String poiID;
  final String activityStartTime;
  final String activityEndTime;
  final String source;
  final String activityRating;
  final String activityRatingDate;
  final String activityReview;

  Activity({
    required this.activityID,
    required this.dayID,
    required this.poiID,
    required this.activityStartTime,
    required this.activityEndTime,
    required this.source,
    required this.activityRating,
    required this.activityRatingDate,
    required this.activityReview,
  });
}

class _ViewPoiDetailsPageState extends State<ViewPoiDetailsPage> {
  late CollectionReference ticket;
  late GoogleMapController mapController;
  final List<POI> contentBasedList = [];
  String poiID = "";
  String poiName = '';
  String poiAddress = '';
  String poiLocation = '';
  String poiRating = '';
  String poiNoOfReviews = '';
  String poiUrl = '';
  double poiLatitude = 0.0;
  double poiLongitude = 0.0;
  String poiImageUrl = '';
  String poiPrice = '';
  String poiTag = '';
  String poiType = '';
  String poiPhone = '';
  String poiOperatingHours = '';
  String poiDescription = '';
  String poiPriceRange = '';
  String selectedDate = '';
  int selectedAdultQuantity = 0;
  int selectedChildQuantity = 0;
  String tripIDSelected = '';
  String tripName = '';
  String tripStartDate = '2021-01-01';
  String tripEndDate = '2021-01-01';
  String tripLocation='';
  String userID='';
  String source='search';
  POI currentPoi = POI(poiID: '',
    poiType: '',
    poiName: '',
    poiAddress: '',
    poiLocation: '',
    poiUrl: '',
    poiPriceRange: '',
    poiPrice: '',
    poiPhone: '',
    poiTag: '',
    poiOperatingHours: '',
    poiRating: '',
    poiNoOfReviews: '',
    poiDescription: '',
    poiLatitude: 0.0,
    poiLongitude: 0.0,
    imageUrl: '',);

  @override
  void initState() {
    super.initState();
    fetchDataFromDatabase();
    ticket = FirebaseFirestore.instance.collection('ticket');
    fetchTicketsForPoiID(widget.poiID);
    loadUserData();

  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email') ?? '';

    print('${email}is found');
    if (email.isNotEmpty) {
      await fetchUserDataFromFirestore(email);
    }
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

        setState(() {
          userID=userData['userID']?.toString() ?? '';
        });
      } else {
        print('User not found.');
      }
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
    }
  }

  void displayTripSelectionSheet(String userID, POI poi) async {
    List<Trip> userTrips = await fetchUserTrips(userID);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a Trip',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              // Display a list of trips
              ListView.builder(
                shrinkWrap: true,
                itemCount: userTrips.length,
                itemBuilder: (context, index) {
                  final trip = userTrips[index];
                  return ListTile(
                    title: Text(trip.tripName),
                    onTap: () {
                      tripIDSelected=trip.tripID;
                      // Close the trip selection sheet and pass relevant details to day selection sheet
                      Navigator.pop(context);
                      displayDaySelectionSheet(poi, trip.tripID);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  List<DateTime> getItineraryDates() {
    DateTime startDate = DateTime.parse(tripStartDate);
    DateTime endDate = DateTime.parse(tripEndDate);

    int numberOfDays = endDate.difference(startDate).inDays + 1;

    return List.generate(numberOfDays, (index) => startDate.add(Duration(days: index)));
  }


  void displayDaySelectionSheet(POI poi, String selectedTripID) async {
    await fetchTripDetails(selectedTripID);
    List<DateTime> itineraryDates = await getItineraryDates();
    TextEditingController startTimeController = TextEditingController();
    TextEditingController endTimeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select a Day',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              // Display a list of available days
              ListView.builder(
                shrinkWrap: true,
                itemCount: itineraryDates.length,
                itemBuilder: (context, index) {
                  final day = itineraryDates[index];
                  return ListTile(
                    title: Text(DateFormat('E d/MM').format(day)),
                    onTap: () async {
                      // Close the day selection sheet
                      Navigator.pop(context);

                      // Show text fields for start and end times
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Enter Start and End Times'),
                            content: Column(
                              children: [
                                TextField(
                                  controller: startTimeController,
                                  decoration: InputDecoration(labelText: 'Start Time (HH:mm)'),
                                  keyboardType: TextInputType.datetime,
                                  inputFormatters: [
                                    MaskedTextInputFormatter(mask: 'HH:mm'),
                                  ],
                                ),
                                TextField(
                                  controller: endTimeController,
                                  decoration: InputDecoration(labelText: 'End Time (HH:mm)'),
                                  keyboardType: TextInputType.datetime,
                                  inputFormatters: [
                                    MaskedTextInputFormatter(mask: 'HH:mm'),
                                  ],
                                ),
                              ],
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  String startTime = startTimeController.text.trim();
                                  String endTime = endTimeController.text.trim();

                                  // Validate the input
                                  if (startTime.isEmpty || endTime.isEmpty) {
                                    // Handle invalid input
                                    // You can show an error message or perform any other action
                                  } else {
                                    // Proceed with confirmation
                                    bool confirmAdd =
                                    await _confirmAddPoiToDay(context, poi, day, startTime, endTime);
                                    if (confirmAdd) {
                                      // Add the POI to the selected day with specified start and end times
                                      await addPoiToTrip(poi, day, startTime, endTime);
                                    }
                                  }
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmAddPoiToDay(BuildContext context, POI poi, DateTime selectedDay, String startTime, String endTime) async {
    bool confirmed = false;

    // Check for time conflicts with existing POIs
    bool hasTimeConflict = await checkTimeConflict(selectedDay, startTime, endTime);

    if (hasTimeConflict) {
      // Display an error message using toast
      showToast('Time conflict with an existing POI. Please choose a different time.');
    } else {
      // No time conflict, proceed with the addition
      // Show confirmation dialog
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add ${poi.poiName} to ${DateFormat('E d/MM').format(selectedDay)}?'),
                Text('Start Time: $startTime'),
                Text('End Time: $endTime'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  confirmed = true;
                  Navigator.of(context).pop();
                },
                child: Text('Add'),
              ),
            ],
          );
        },
      );
    }
    return confirmed;
  }

  Future<void> addPoiToTrip(POI poi, DateTime selectedDay, String startTime, String endTime) async {
    try {

      String formattedSelectedDay = DateFormat('yyyy-MM-dd').format(selectedDay);

      DateTime currentDate = DateTime.now();
      String formattedCurrentDate = DateFormat('yyyy-MM-dd').format(currentDate);

      // Fetch the dayID based on the selected day and tripID
      String tripID = tripIDSelected;
      String dayID = await fetchDayID(tripID, formattedSelectedDay);

      String activityID = await generateNewActivityID();
      await FirebaseFirestore.instance.collection('activity').doc(activityID).set({
        'activityID': activityID,
        'dayID': dayID,
        'poiID': poi.poiID,
        'activityStartTime': startTime,
        'activityEndTime': endTime,
        'source': source,
        'activityRating':'',
        'activityRatingDate':'',
        'activityReview':'',
      });

      if(source!="searched"){
        String recommendationID = await generateNewRecommendationID();

        await FirebaseFirestore.instance.collection('recommendation').doc(recommendationID).set({
          'recommendationID': recommendationID,
          'activityID': activityID,
          'recommendationDate': formattedCurrentDate,
          'recommendationFactor':source,
          'recommendationRating':'',
          'recommendationReview':'',
        });
      }

      showToast('Successfully added to trip');
    } catch (e) {
      showToast('Error adding POI to trip: $e');
    }
  }

  Future<String> fetchDayID(String tripID, String selectedDay) async {
    try {
      // Fetch the day document based on tripID and selectedDay
      QuerySnapshot<Map<String, dynamic>> daySnapshot = await FirebaseFirestore.instance.collection('day')
          .where('tripID', isEqualTo: tripID)
          .where('dayDate', isEqualTo: selectedDay)
          .get();

      if (daySnapshot.docs.isNotEmpty) {
        // Assuming there's only one document for a given day and tripID
        return daySnapshot.docs.first['dayID'];
      } else {
        // Handle the case where the day document does not exist
        print('Day document does not exist.');
        return '';
      }
    } catch (e) {
      print('Error fetching dayID: $e');
      // Handle error
      return '';
    }
  }

  Future<List<Activity>> fetchActivitiesForDay(String dayID) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('activity')
          .where('dayID', isEqualTo: dayID)
          .get();

      // Extract activity data from the snapshot
      List<Activity> activities = snapshot.docs.map((DocumentSnapshot<Map<String, dynamic>> doc) {
        return Activity(
          activityID: doc['activityID'],
          poiID: doc['poiID'],
          activityStartTime: doc['activityStartTime'],
          activityEndTime: doc['activityEndTime'],
          dayID: doc['dayID'],
          source: doc['source'],
          activityRating: doc['activityRating'],
          activityRatingDate: doc['activityRatingDate'],
          activityReview:doc['activityReview'],
        );
      }).toList();

      return activities;
    } catch (e) {
      print('Error fetching activities for day: $e');
      return [];
    }
  }

  Future<bool> checkTimeConflict(DateTime selectedDay, String newStartTime, String newEndTime) async {
    // Fetch existing activities for the selected day
    String formattedSelectedDay = DateFormat('yyyy-MM-dd').format(selectedDay);
    String dayID = await fetchDayID(tripIDSelected, formattedSelectedDay);
    List<Activity> existingActivities = await fetchActivitiesForDay(dayID);

    // Check for time conflicts
    for (var activity in existingActivities) {
      String existingStartTime = activity.activityStartTime;
      String existingEndTime = activity.activityEndTime;

      print('Existing Start Time: $existingStartTime, Existing End Time: $existingEndTime');
      print('New Start Time: $newStartTime, New End Time: $newEndTime');

      if (_isTimeConflict(newStartTime, newEndTime, existingStartTime, existingEndTime)) {
        // Time conflict found
        return true;
      }
    }

    // No time conflict
    return false;
  }

  bool _isTimeConflict(String startTime1, String endTime1, String startTime2, String endTime2) {
    // Convert times to DateTime objects for easier comparison
    DateTime start1 = DateTime.parse('2023-01-01 ' + startTime1);
    DateTime end1 = DateTime.parse('2023-01-01 ' + endTime1);
    DateTime start2 = DateTime.parse('2023-01-01 ' + startTime2);
    DateTime end2 = DateTime.parse('2023-01-01 ' + endTime2);

    // Check for overlap
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  Future<String> generateNewActivityID() async {
    try {
      // Fetch the last activity document from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('activity').orderBy('activityID', descending: true).limit(1).get();

      String lastActivityID = '';

      if (querySnapshot.docs.isNotEmpty) {
        // Get the last activityID
        lastActivityID = querySnapshot.docs.first['activityID'];
      }

      // Extract the numeric part and increment it
      int lastID = int.parse(lastActivityID.substring(1));
      int newID = lastID + 1;

      // Generate the new activityID
      String newActivityID = 'A' + newID.toString().padLeft(5, '0');

      return newActivityID;
    } catch (e) {
      print('Error generating new activityID: $e');
      // Handle error
      return '';
    }
  }

  Future<String> generateNewRecommendationID() async {
    try {
      // Fetch the last activity document from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('recommendation').orderBy('recommendationID', descending: true).limit(1).get();

      String lastRecommendationID = '';

      if (querySnapshot.docs.isNotEmpty) {
        lastRecommendationID = querySnapshot.docs.first['recommendationID'];
      }

      // Extract the numeric part and increment it
      int lastID = int.parse(lastRecommendationID.substring(1));
      int newID = lastID + 1;

      // Generate the new activityID
      String newRecommendationID = 'R' + newID.toString().padLeft(5, '0');

      return newRecommendationID;
    } catch (e) {
      print('Error generating new recommendationID: $e');
      // Handle error
      return '';
    }
  }

  Future<List<Trip>> fetchUserTrips(String userID) async {
    try {
      final tripQuery = await FirebaseFirestore.instance
          .collection('trip')
          .where('userID', isEqualTo: userID)
          .where('tripStatus', isEqualTo: 'upcoming') // Add this line to filter by tripStatus
          .get();

      List<Trip> userTrips = [];

      for (var tripSnapshot in tripQuery.docs) {
        final tripData = tripSnapshot.data() as Map<String, dynamic>;

        Trip trip = Trip(
          tripID: tripSnapshot.id,
          tripName: tripData['tripName'] ?? '',
          tripStartDate: tripData['tripStartDate'] ?? '',
          tripEndDate: tripData['tripEndDate'] ?? '',
          tripLocation: tripData['tripLocation'] ?? '',
          tripStatus: tripData['tripStatus'] ?? '',
          userID: tripData['userID'] ?? '',
        );

        userTrips.add(trip);
      }

      return userTrips;
    } catch (e) {
      print('Error fetching user trips: $e');
      return [];
    }
  }

  Future<void> fetchTripDetails(String tripID) async {
    try {
      final tripSnapshot = await FirebaseFirestore.instance.collection('trip').doc(tripID).get();
      if (tripSnapshot.exists) {
        final tripData = tripSnapshot.data() as Map<String, dynamic>;
        setState(() {
          tripName = tripData['tripName'] ?? '';
          tripStartDate = tripData['tripStartDate'] ?? '';
          tripEndDate = tripData['tripEndDate'] ?? '';
          tripLocation =tripData['tripLocation'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching trip details: $e');
    }
  }

  List<Map<String, dynamic>> ticketsData = [];

  Future<List<Map<String, dynamic>>> fetchTicketsForPoiID(String poiID) async {
    try {
      QuerySnapshot ticketSnapshot = await ticket.where(
          'poiID', isEqualTo: poiID).get();
      List<Map<String, dynamic>> ticketsData = [];

      // Loop through the documents in the snapshot
      ticketSnapshot.docs.forEach((DocumentSnapshot document) {
        // Access the fields of each document
        String ticketID = document['ticketID'];
        String poiID = document['poiID'];
        String ticketDate = document['ticketDate'];
        double childTicketPrice = document['childTicketPrice'].toDouble();
        int childTicketQty = document['childTicketQty'];
        double adultTicketPrice = document['adultTicketPrice'].toDouble();
        int adultTicketQty = document['adultTicketQty'];

        // Store the data in a list
        ticketsData.add({
          'ticketID': ticketID,
          'poiID': poiID,
          'ticketDate': ticketDate,
          'childTicketPrice': childTicketPrice,
          'childTicketQty': childTicketQty,
          'adultTicketPrice': adultTicketPrice,
          'adultTicketQty': adultTicketQty,
        });
      });

      return ticketsData;
    } catch (e) {
      showToast('Error fetching tickets: $e');
      return []; // Return an empty list or handle errors as needed
    }
  }


  Future<void> fetchDataFromDatabase() async {
    try {
      final response = await http.get(Uri.parse(
          'http://34.124.197.131:5000/get_poi_based_on_id?query=${widget
              .poiID}'));

      if (response.statusCode == 200) {
        // Parse the response body
        List<dynamic> responseDataList = json.decode(response.body);

        if (responseDataList.isNotEmpty) {
          // Extract the first element from the list
          dynamic responseData = responseDataList[0];

          if (responseData is Map<String, dynamic>) {
            // If the response is a map, update the state with the retrieved details
            setState(() {
              poiID = responseData['poiID']?.toString() ?? '';
              poiName = responseData['poiName']?.toString() ?? '';
              poiAddress = responseData['poiAddress']?.toString() ?? '';
              poiLocation = responseData['poiLocation']?.toString() ?? '';
              poiPrice = responseData['poiPrice']?.toString() ?? '';
              poiRating = responseData['poiRating']?.toString() ?? '';
              poiTag = responseData['poiTag']?.toString() ?? '';
              poiNoOfReviews = responseData['poiNoOfReviews']?.toString() ?? '';
              poiType = responseData['poiType']?.toString() ?? '';
              poiUrl = responseData['poiUrl']?.toString() ?? '';
              poiPhone = responseData['poiPhone']?.toString() ?? '';
              poiOperatingHours =
                  responseData['poiOperatingHours']?.toString() ?? '';
              poiDescription = responseData['poiDescription']?.toString() ?? '';
              poiPriceRange = responseData['poiPriceRange']?.toString() ?? '';
              poiLatitude = responseData['poiLatitude']?.toDouble() ?? 0.0;
              poiLongitude = responseData['poiLongitude']?.toDouble() ?? 0.0;
            });

            fetchImageFromGooglePlaces(poiName);
            contentBasedList.clear();
            if(poiType == 'Restaurant'){
              fetchRestaurantContentBased(poiName);
            }else if(poiType == 'Attraction'){
              fetchAttractionContentBased(poiName);
            }else if(poiType == 'Hotel'){
              fetchHotelContentBased(poiName);
            }

            currentPoi = POI(
              poiID: poiID,
              poiType: poiType,
              poiName: poiName,
              poiAddress: poiAddress,
              poiLocation: poiLocation,
              poiUrl: poiUrl,
              poiPriceRange: poiPriceRange,
              poiPrice: poiPrice,
              poiPhone: poiPhone,
              poiTag: poiTag,
              poiOperatingHours: poiOperatingHours,
              poiRating: poiRating,
              poiNoOfReviews: poiNoOfReviews,
              poiDescription: poiDescription,
              poiLatitude: 0.0,
              poiLongitude: 0.0,
              imageUrl: '',);

          } else {
            print(
                'Unexpected response format. First element is not a map: $responseData');
          }
        } else {
          // Handle the case where the list is empty
          print('Unexpected response format. Empty list.');
        }
      } else {
        // Handle the case where the response status code is not 200
        print('Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any exceptions that might occur during the process
      print('Error fetching data from database: $e');
    }
  }

  LatLng getLatLng(double latitude, double longitude) {
    return LatLng(latitude, longitude);
  }

  Future<void> fetchImageForPOI(Map<String, dynamic> poiDetails) async {
    // Use Google Places API to fetch additional details, including images
    const apiKey = 'AIzaSyDz9pepBSYg90CZXK1WZkucemlJxlSinuY';
    final placeName = poiDetails['poiName'];

    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$placeName'
            '&inputtype=textquery'
            '&fields=photos'
            '&key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final List<dynamic> candidates = data['candidates'];

        if (candidates != null && candidates.isNotEmpty) {
          final String photoReference = candidates[0]['photos'][0]['photo_reference'];
          final imageUrl =
              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';

          poiDetails['imageUrl'] = imageUrl;
        }
      }
    }
  }

  Future<void> fetchImageFromGooglePlaces(String placeName) async {
    try {
      const apiKey = 'AIzaSyDz9pepBSYg90CZXK1WZkucemlJxlSinuY';
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$placeName'
              '&inputtype=textquery'
              '&fields=photos'
              '&key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List<dynamic> candidates = data['candidates'];

          if (candidates != null && candidates.isNotEmpty) {
            final String photoReference = candidates[0]['photos'][0]['photo_reference'];
            final imageUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';

            setState(() {
              poiImageUrl = imageUrl;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching image from Google Places API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isNotHotel = poiType != 'Hotel';
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        backgroundColor: Theme
            .of(context)
            .primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the retrieved data
            if (poiImageUrl.isNotEmpty)
              Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width,
                height: MediaQuery
                    .of(context)
                    .size
                    .height * 0.3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                  child: Image.network(
                    poiImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(poiName, style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      // Name
                      Spacer(),
                      // Rating and Review
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.yellow),
                          SizedBox(width: 8),
                          Text('$poiRating (${poiNoOfReviews})',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  if (poiPriceRange != '-1') Row(
                    children: [
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            "Price Range:$poiPriceRange", style: TextStyle(
                            fontSize: 16)),
                      ),
                    ],
                  ),
                  if (poiTag != '-1') Row(
                    children: [
                      Icon(Icons.local_offer, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(poiTag, style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                  if (poiOperatingHours != '-1') Row(
                    children: [
                      Icon(Icons.access_time, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Operating Hours: $poiOperatingHours', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.0),
                  // Smaller header for the description
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Location',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  SizedBox(height: 8.0),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: (poiLatitude != 0.0 && poiLongitude != 0.0 && poiLatitude != null && poiLongitude != null && poiLatitude != '' && poiLongitude != '')
                        ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: getLatLng(poiLatitude, poiLongitude),
                        zoom: 14.0,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        setState(() {
                          mapController = controller;
                        });
                      },
                      markers: {
                        Marker(
                          markerId: MarkerId('poiMarker'),
                          position: getLatLng(poiLatitude, poiLongitude),
                          infoWindow: InfoWindow(title: poiName),
                        ),
                      },
                    )
                        : Container(
                      // You can customize this container to display a message or placeholder image
                      child: Center(
                        child: Text('Map not available'),
                      ),
                    ),
                  ),
                  if (poiAddress!= '-1')
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(poiAddress, style: TextStyle(
                              fontSize: 16)),
                        ),
                      ],
                    ),
                  SizedBox(height: 16.0),
                  if (poiDescription != '-1' || poiUrl != '-1' || poiPhone != '-1')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        if (poiDescription != '-1') Row(
                          children: [
                            Icon(Icons.description, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (poiDescription.length > 100) ? '${poiDescription.substring(0, 100)}...' : poiDescription,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),

                        if (poiUrl != '-1') Row(
                          children: [
                            Icon(Icons.link, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => launch(poiUrl),
                                child: Text(
                                  poiUrl,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                  overflow: TextOverflow.visible,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (poiPhone != '-1') Row(
                          children: [
                            Icon(Icons.phone, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(poiPhone, style: TextStyle(fontSize: 16)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  SizedBox(height: 8.0),
                  // Display Ticket List
                  displayTicketList(widget.poiID, context),
                  SizedBox(height: 16.0),

                  Visibility(
                    visible: isNotHotel, // Show the text if isNotHotel is true
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Similar Places',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: contentBasedList.length,
                    itemBuilder: (context, index) {
                      return buildPoiCard(contentBasedList[index]);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          displayTripSelectionSheet(userID, currentPoi);
        },
        child: Icon(Icons.add),
        backgroundColor: Theme
            .of(context)
            .primaryColor,
      ),
    );
  }

  Widget displayTicketList(String poiID, BuildContext context) {
    List<DropdownMenuItem<String>> dropdownItems = [];
    return FutureBuilder(
      future: fetchTicketsForPoiID(poiID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Error fetching tickets: ${snapshot.error}'));
        } else if (snapshot.data == null ||
            !(snapshot.data is List<Map<String, dynamic>>)) {
          return Center(child: Text('Invalid or null data format.'));
        }

        List<Map<String, dynamic>> ticketsData = snapshot.data as List<
            Map<String, dynamic>>;

        bool hasTicketsAvailable = hasAvailableTickets(ticketsData);

        if (!hasTicketsAvailable) {
          return const Text('No tickets available for this POI.');
        }

        Map<String,
            List<Map<String, dynamic>>> ticketsByDate = groupTicketsByDate(
            ticketsData);

        Set<String> uniqueDates = Set();

        dropdownItems.clear(); // Clear the previous dropdown items

        for (String date in ticketsByDate.keys) {
          if (uniqueDates.add(date)) {
            dropdownItems.add(DropdownMenuItem<String>(
              value: date,
              child: Text(date),
            ));
          }
        }

        // Ensure selectedDate is a valid value
        if (!dropdownItems.any((item) => item.value == selectedDate)) {
          selectedDate =
          dropdownItems.isNotEmpty ? dropdownItems.first.value ?? '' : '';
        }

        return Column(
          children: [
            if (hasTicketsAvailable)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Tickets Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            Container(
              margin: EdgeInsets.only(bottom: 16.0),
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: selectedDate,
                    icon: const Icon(Icons.arrow_downward),
                    iconSize: 24,
                    elevation: 16,
                    style: const TextStyle(color: Colors.deepPurple),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedDate = newValue!;
                      });
                    },
                    items: dropdownItems,
                  ),
                  SizedBox(height: 16.0),
                  ...buildTicketListTilesForDate(
                      ticketsByDate[selectedDate]!, context),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      _showTicketQuantityModal(
                          context, ticketsByDate[selectedDate]!.first);
                    },
                    child: Text('Select'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }


  // Function to check if there are available tickets
  bool hasAvailableTickets(List<Map<String, dynamic>> ticketsData) {
    return ticketsData.any((ticket) =>
    ticket['childTicketQty'] > 0 || ticket['adultTicketQty'] > 0);
  }

  // Function to group tickets by date
  Map<String, List<Map<String, dynamic>>> groupTicketsByDate(
      List<Map<String, dynamic>> ticketsData) {
    Map<String, List<Map<String, dynamic>>> ticketsByDate = {};

    ticketsData.forEach((ticket) {
      String ticketDate = ticket['ticketDate'];
      ticketsByDate.putIfAbsent(ticketDate, () => []);
      ticketsByDate[ticketDate]!.add(ticket);
    });

    return ticketsByDate;
  }

  List<Widget> buildTicketListTilesForDate(
      List<Map<String, dynamic>> dateTickets, BuildContext context) {
    if (dateTickets == null || dateTickets.isEmpty) {
      return [Text('No tickets available for the selected date.')];
    }

    return dateTickets.map((ticket) {
      return ListTile(
        title: Text('Ticket ID: ${ticket['ticketID']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adult'),
            Text('RM: ${ticket['adultTicketPrice']}'),
            Text('Children'),
            Text('RM: ${ticket['childTicketPrice']}'),
          ],
        ),
        // onTap: () {
        //   _showTicketQuantityModal(context, ticket);
        // },
      );
    }).toList();
  }


  void _showTicketQuantityModal(BuildContext context, Map<String, dynamic> ticketData) {
    double adultTicketPrice = ticketData['adultTicketPrice'] ?? 0.0;
    double childTicketPrice = ticketData['childTicketPrice'] ?? 0.0;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Select Ticket Quantities'),
                  SizedBox(height: 16.0),
                  // Display the selected date
                  Text('Date: ${ticketData['ticketDate']}'),
                  SizedBox(height: 16.0),
                  _buildTicketQuantitySelector(
                    label: 'Adult Ticket',
                    quantity: selectedAdultQuantity,
                    price: adultTicketPrice,
                    availableQuantity: ticketData['adultTicketQty'],
                    // Pass the available adult ticket quantity
                    onChanged: (value) {
                      setState(() {
                        selectedAdultQuantity = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  _buildTicketQuantitySelector(
                    label: 'Child Ticket',
                    quantity: selectedChildQuantity,
                    price: childTicketPrice,
                    availableQuantity: ticketData['childTicketQty'],
                    // Pass the available child ticket quantity
                    onChanged: (value) {
                      setState(() {
                        selectedChildQuantity = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),
                  // Display total price
                  Text('Total Price: RM${_calculateTotalPrice(selectedAdultQuantity, selectedChildQuantity, adultTicketPrice, childTicketPrice)}'),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      // Check if both adult and child quantities are zero
                      if (selectedAdultQuantity == 0 && selectedChildQuantity == 0) {
                        showToast('Please select at least one ticket.');
                        return;
                      }else
                        {
                          // Navigate to the booking summary page with selected ticket details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookingSummaryPage(
                                    ticketID: ticketData['ticketID'],
                                    adultQuantity: selectedAdultQuantity,
                                    childQuantity: selectedChildQuantity,
                                    adultTicketPrice: adultTicketPrice,
                                    childTicketPrice: childTicketPrice,
                                    ticketDate: ticketData['ticketDate'],
                                  ),
                            ),
                          );
                        }
                    },
                    child: Text('Book Now'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {});
  }


  Widget _buildTicketQuantitySelector({
    required String label,
    required int quantity,
    required double price,
    required int availableQuantity,
    required void Function(int) onChanged,
  }) {
    return Row(
      children: [
        Text('$label Quantity: $quantity'),
        Spacer(),
        IconButton(
          onPressed: () {
            if (quantity > 0) {
              onChanged(quantity - 1);
            }
          },
          icon: Icon(Icons.remove),
        ),
        Text(' RM${price.toStringAsFixed(2)} '),
        IconButton(
          onPressed: () {
            if (quantity < availableQuantity) {
              onChanged(quantity + 1);
            }
          },
          icon: Icon(Icons.add),
        ),
      ],
    );
  }

  double _calculateTotalPrice(int adultQuantity, int childQuantity,
      double adultPrice, double childPrice) {
    return (adultQuantity * adultPrice) + (childQuantity * childPrice);
  }

  Widget buildPoiCard(POI placeDetails) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to viewPoiDetails page when a POI is clicked
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewPoiDetailsPage(poiID: placeDetails.poiID),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (placeDetails.imageUrl != null)
                Image.network(
                  placeDetails.imageUrl,
                  width: 75,
                  height: 75,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 8),
              Text(
                placeDetails.poiName,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Rating: ${placeDetails.poiRating}'),
            ],
          ),
        ),
      ),
    );
  }



  Future<void> fetchRestaurantContentBased(String poiName) async {
    try {
      final response = await http.get(
          Uri.parse('http://34.124.197.131:5000/recommend_restaurant_content_based?poiName=$poiName'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);

        if (dataMap.containsKey('error')) {
          print('Error: ${dataMap['error']}');
        } else if (dataMap.containsKey('content_based_restaurants')) {
          final List<dynamic> dataList = dataMap['content_based_restaurants'];

          for (var item in dataList) {
            if (item != null) {
              await fetchImageForPOI(item); // Fetch image for each POI
              contentBasedList.add(POI(
                poiID: item['poiID']?.toString() ?? '',
                poiType: item['poiType']?.toString() ?? '',
                poiName: item['poiName']?.toString() ?? '',
                poiAddress: '',
                poiLocation: '',
                poiUrl: '',
                poiPriceRange: '',
                poiPrice: item['poiPrice']?.toString() ?? '',
                poiPhone: '',
                poiTag: item['poiTag']?.toString() ?? '',
                poiOperatingHours: '',
                poiRating: item['poiRating']?.toString() ?? '',
                poiNoOfReviews: '',
                poiDescription: '',
                poiLatitude: 0.0,
                poiLongitude: 0.0,
                imageUrl: item['imageUrl']?.toString() ?? '',
              ));
            }
          }

          // Update the UI
          setState(() {});

        } else {
          print('Invalid JSON format: missing expected key');
        }
      } else {
        // Handle error, e.g., print an error message
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }

  // Future<void> fetchAttractionContentBased(String poiName) async {
  //   try {
  //     final response = await http.get(
  //         Uri.parse('http://34.124.197.131:5000/recommend_attraction_content_based?poiName=$poiName'));
  //
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> dataMap = json.decode(response.body);
  //
  //       if (dataMap.containsKey('error')) {
  //         print('Error: ${dataMap['error']}');
  //       } else if (dataMap.containsKey('content_based_attractions')) {
  //         final List<dynamic> dataList = dataMap['content_based_attractions'];
  //
  //         for (var item in dataList) {
  //           await fetchImageForPOI(item); // Fetch image for each POI
  //           contentBasedList.add(POI(
  //             poiID: item['poiID']?.toString() ?? '',
  //             poiType: item['poiType']?.toString() ?? '',
  //             poiName: item['poiName']?.toString() ?? '',
  //             poiAddress: '',
  //             poiLocation: '',
  //             poiUrl: '',
  //             poiPriceRange: '',
  //             poiPrice: '',
  //             poiPhone: '',
  //             poiTag: item['poiTag']?.toString() ?? '',
  //             poiOperatingHours: '',
  //             poiRating: item['poiRating']?.toString() ?? '',
  //             poiNoOfReviews: '',
  //             poiDescription: '',
  //             poiLatitude: 0.0,
  //             poiLongitude: 0.0,
  //             imageUrl: item['imageUrl']?.toString() ?? '',
  //           ));
  //         }
  //
  //         // Update the UI
  //         setState(() {});
  //
  //       } else {
  //         print('Invalid JSON format: missing expected key');
  //       }
  //     } else {
  //       // Handle error, e.g., print an error message
  //       print('Failed to fetch JSON data. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error loading POIs from JSON: $e');
  //   }
  // }

  Future<void> fetchAttractionContentBased(String poiName) async {
    try {
      final response = await http.get(
          Uri.parse('http://34.124.197.131:5000/recommend_attraction_content_based?poiName=$poiName'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);

        if (dataMap.containsKey('error')) {
          print('Error: ${dataMap['error']}');
        } else if (dataMap.containsKey('content_based_attractions')) {
          final List<dynamic> dataList = dataMap['content_based_attractions'];

          for (var item in dataList) {
            if (item != null) {
              await fetchImageForPOI(item); // Fetch image for each POI
              contentBasedList.add(POI(
                poiID: item['poiID']?.toString() ?? '',
                poiType: item['poiType']?.toString() ?? '',
                poiName: item['poiName']?.toString() ?? '',
                poiAddress: item['poiAddress']?.toString() ?? '', // Add null check for other properties
                poiLocation: item['poiLocation']?.toString() ?? '',
                poiUrl: item['poiUrl']?.toString() ?? '',
                poiPriceRange: item['poiPriceRange']?.toString() ?? '',
                poiPrice: item['poiPrice']?.toString() ?? '',
                poiPhone: item['poiPhone']?.toString() ?? '',
                poiTag: item['poiTag']?.toString() ?? '',
                poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
                poiRating: item['poiRating']?.toString() ?? '',
                poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
                poiDescription: item['poiDescription']?.toString() ?? '',
                poiLatitude: item['poiLatitude']?.toDouble() ?? 0.0,
                poiLongitude: item['poiLongitude']?.toDouble() ?? 0.0,
                imageUrl: item['imageUrl']?.toString() ?? '',
              ));
            }
          }

          // Update the UI
          setState(() {});
        } else {
          print('Invalid JSON format: missing expected key');
        }
      } else {
        // Handle error, e.g., print an error message
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }


  Future<void> fetchHotelContentBased(String poiName) async {
    try {
      final response = await http.get(
          Uri.parse('http://34.124.197.131:5000/recommend_hotel_content_based?poiName=$poiName'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);

        if (dataMap.containsKey('error')) {
          print('Error: ${dataMap['error']}');
        } else if (dataMap.containsKey('content_based_hotels')) {
          final List<dynamic> dataList = dataMap['content_based_hotels'];

          for (var item in dataList) {
            await fetchImageForPOI(item); // Fetch image for each POI
            contentBasedList.add(POI(
              poiID: item['poiID']?.toString() ?? '',
              poiType: item['poiType']?.toString() ?? '',
              poiName: item['poiName']?.toString() ?? '',
              poiAddress: '',
              poiLocation: '',
              poiUrl: '',
              poiPriceRange: '',
              poiPrice: item['poiPrice']?.toString() ?? '',
              poiPhone: '',
              poiTag: item['poiTag']?.toString() ?? '',
              poiOperatingHours: '',
              poiRating: item['poiRating']?.toString() ?? '',
              poiNoOfReviews: '',
              poiDescription: '',
              poiLatitude: 0.0,
              poiLongitude: 0.0,
              imageUrl: item['imageUrl']?.toString() ?? '',
            ));
          }

          // Update the UI
          setState(() {});

        } else {
          print('Invalid JSON format: missing expected key');
        }
      } else {
        // Handle error, e.g., print an error message
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }

}
