import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:my_travel_mate/Widget/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../POI/viewPoiDetails.dart';

class TripHistory extends StatefulWidget {
  final String tripId;

  TripHistory({required this.tripId});

  @override
  _TripHistoryState createState() => _TripHistoryState();
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

class LocationCoordinates {
  double poiLatitude;
  double poiLongitude;

  LocationCoordinates({required this.poiLatitude, required this.poiLongitude});
}


class _TripHistoryState extends State<TripHistory> {
  List<POI> allPOIs = [];
  List<POI> demographicPoiList = [];
  List<POI> topRatedPoiList = [];
  List<POI> nearbyRestaurantList = [];
  List<POI> topRatedHotelList = [];
  String tripName = '';
  String tripStartDate = '2021-01-01';
  String tripEndDate = '2021-01-01';
  String tripLocation='';
  String searchQuery = '';
  List<POI> filteredPOIs = [];
  String source='';
  String name='';
  String userID='';
  String country='';
  String gender='';
  String age='';
  String email='';
  String dateOfBirth='';
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await loadUserData();
    await fetchTripDetails();
    fetchPointsOfInterest();
  }

  LocationCoordinates assignCoordinatesByLocation(String tripLocation) {
    Map<String, LocationCoordinates> locationCoordinates = {
      'Johor': LocationCoordinates(poiLatitude: 1.4854, poiLongitude: 103.7618),
      'Kedah': LocationCoordinates(poiLatitude: 6.1254, poiLongitude: 100.3673),
      'Kelantan': LocationCoordinates(poiLatitude: 6.1256, poiLongitude: 102.2385),
      'Kuala Lumpur': LocationCoordinates(poiLatitude: 3.1390, poiLongitude: 101.6869),
      'Labuan': LocationCoordinates(poiLatitude: 5.2767, poiLongitude: 115.2417),
      'Melaka': LocationCoordinates(poiLatitude: 2.1896, poiLongitude: 102.2501),
      'Negeri Sembilan': LocationCoordinates(poiLatitude: 2.7254, poiLongitude: 101.9421),
      'Pahang': LocationCoordinates(poiLatitude: 3.8077, poiLongitude: 103.3260),
      'Perak': LocationCoordinates(poiLatitude: 4.5921, poiLongitude: 101.0901),
      'Perlis': LocationCoordinates(poiLatitude: 6.4381, poiLongitude: 100.1947),
      'Penang': LocationCoordinates(poiLatitude: 5.4167, poiLongitude: 100.3167),
      'Putrajaya': LocationCoordinates(poiLatitude: 2.9264, poiLongitude: 101.6964),
      'Sabah': LocationCoordinates(poiLatitude: 5.9804, poiLongitude: 116.0735),
      'Sarawak': LocationCoordinates(poiLatitude: 1.5535, poiLongitude: 110.3592),
      'Selangor': LocationCoordinates(poiLatitude: 3.3792, poiLongitude: 101.5486),
      'Terengganu': LocationCoordinates(poiLatitude: 5.0745, poiLongitude: 103.0304),
    };

    // Get coordinates based on the trip location
    LocationCoordinates? coordinates = locationCoordinates[tripLocation];

    if (coordinates != null) {
      return coordinates;
    } else {
      return LocationCoordinates(poiLatitude: 0.0, poiLongitude: 0.0);
    }
  }


  @override
  Widget build(BuildContext context) {
    List<DateTime> dates = getItineraryDates();

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tripName),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Container(
          color: Colors.grey[200],
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Icon(Icons.calendar_today, color: Colors.black),
                        Text(
                          '$formattedTripStartDate - $formattedTripEndDate',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: 'Itinerary'),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    buildItineraryTab(context, dates),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPoiCard(POI placeDetails, {required String selectedSource}) {
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
          width: 150,
          height: 200,
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
              Expanded(
                child: Text(
                  placeDetails.poiName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text('Rating: ${placeDetails.poiRating}'),

            ],
          ),
        ),
      ),
    );
  }

  String get formattedTripStartDate => DateFormat('MMM d').format(DateTime.parse(tripStartDate));
  String get formattedTripEndDate => DateFormat('MMM d').format(DateTime.parse(tripEndDate));

  Widget buildItineraryTab(BuildContext context, List<DateTime> dates) {
    POI? selectedPOI;
    DateTime? selectedDay;

    return ListView.builder(
      itemCount: dates.length + 1,
      itemBuilder: (context, index) {
        if (index == dates.length) {
          // This is the additional item, you can return a widget for it
          return Container(
            // Return a widget for the additional item
          );
        }

        Map<DateTime, String> lastPoiIDs = {};
        // Use FutureBuilder to handle asynchronous fetching of activities
        return FutureBuilder<String>(
          future: fetchDayID(widget.tripId, DateFormat('yyyy-MM-dd').format(dates[index])),
          builder: (context, dayIdSnapshot) {
            if (dayIdSnapshot.connectionState == ConnectionState.waiting) {
              return Container(); // You can replace this with a loading indicator
            } else if (dayIdSnapshot.hasError || dayIdSnapshot.data == null) {
              print('Error fetching dayID: ${dayIdSnapshot.error}');
              return Container(); // You can replace this with an error message
            } else {
              // If dayID is successfully fetched, build the UI
              String dayID = dayIdSnapshot.data!;
              return FutureBuilder<List<Activity>>(
                future: fetchActivitiesForDay(dayID),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(); // You can replace this with a loading indicator
                  } else if (snapshot.hasError) {
                    print('Error: ${snapshot.error}');
                    return Container(); // You can replace this with an error message
                  } else {
                    // If data is successfully fetched, build the UI
                    List<Activity> activities = snapshot.data ?? [];

                    // Sort activities based on start time
                    activities.sort((a, b) => a.activityStartTime.compareTo(b.activityStartTime));

                    return Container(
                      margin: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          DateFormat('E d/MM').format(dates[index]),
                          style: TextStyle(fontSize: 16.0),
                        ),
                        children: [
                          if (activities.isNotEmpty) ...[
                            Divider(color: Colors.grey, height: 10, thickness: 1, endIndent: 20),
                            // Display activities in separate containers
                            for (var activity in activities) ...[
                              GestureDetector(
                                onTap: () {
                                  // Navigate to viewPoiDetails page with the poiID
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewPoiDetailsPage(poiID: activity.poiID),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder<POI>(
                                        future: searchPointsOfInterestById(activity.poiID),
                                        builder: (context, poiSnapshot) {
                                          if (poiSnapshot.connectionState == ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          } else if (poiSnapshot.hasError) {
                                            return Text('Error fetching POI details');
                                          } else {
                                            POI poi = poiSnapshot.data!;
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('POI Name: ${poi.poiName}'),
                                                Text('POI Address: ${poi.poiAddress}'),
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                      Text('Start Time: ${activity.activityStartTime}'),
                                      Text('End Time: ${activity.activityEndTime}'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
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

  List<DateTime> getItineraryDates() {
    DateTime startDate = DateTime.parse(tripStartDate);
    DateTime endDate = DateTime.parse(tripEndDate);

    int numberOfDays = endDate.difference(startDate).inDays + 1;

    return List.generate(numberOfDays, (index) => startDate.add(Duration(days: index)));
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

  Future<POI> searchPointsOfInterestById(String poiID) async {
    try {
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_based_on_id?query=$poiID'));

      if (response.statusCode == 200) {
        List<dynamic> responseDataList = json.decode(response.body);

        if (responseDataList.isNotEmpty) {
          dynamic responseData = responseDataList[0];

          if (responseData is Map<String, dynamic>) {
            return POI(
              poiID: responseData['poiID']?.toString() ?? '',
              poiType: responseData['poiType']?.toString() ?? '',
              poiName: responseData['poiName']?.toString() ?? '',
              poiAddress: responseData['poiAddress']?.toString() ?? '',
              poiLocation: responseData['poiLocation']?.toString() ?? '',
              poiUrl: responseData['poiUrl']?.toString() ?? '',
              poiPriceRange: responseData['poiPriceRange']?.toString() ?? '',
              poiPrice: responseData['poiPrice']?.toString() ?? '',
              poiPhone: responseData['poiPhone']?.toString() ?? '',
              poiTag: responseData['poiTag']?.toString() ?? '',
              poiOperatingHours: responseData['poiOperatingHours']?.toString() ?? '',
              poiRating: responseData['poiRating']?.toString() ?? '',
              poiNoOfReviews: responseData['poiNoOfReviews']?.toString() ?? '',
              poiDescription: responseData['poiDescription']?.toString() ?? '',
              poiLatitude: responseData['poiLatitude']?.toDouble() ?? 0.0,
              poiLongitude: responseData['poiLongitude']?.toDouble() ?? 0.0,
              imageUrl: '',
            );

          } else {
            print('Unexpected response format. First element is not a map: $responseData');
          }
        } else {
          print('Unexpected response format. Empty list.');
        }
      } else {
        print('Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data from database: $e');
    }

    // Return an empty POI object if there's an error
    return POI(
      poiID: '',
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
      imageUrl: '',
    );
  }

  bool hasPointOfInterest(DateTime date) {
    return false;
  }

  DocumentSnapshot? findFirstWhereOrNull<T>(
      Iterable<T> iterable,
      bool Function(T element) test,
      ) {
    for (var element in iterable) {
      if (test(element)) {
        return element as DocumentSnapshot;
      }
    }
    return null;
  }

  Future<String> fetchDayID(String tripID, String selectedDay) async {
    try {
      // Fetch the day document based on tripID and selectedDay
      QuerySnapshot<Map<String, dynamic>> daySnapshot = await FirebaseFirestore.instance.collection('day')
          .where('tripID', isEqualTo: tripID)
          .where('dayDate', isEqualTo: selectedDay)
          .get();

      if (daySnapshot.docs.isNotEmpty) {
        return daySnapshot.docs.first['dayID'];
      } else {
        print('Day document does not exist.');
        return '';
      }
    } catch (e) {
      print('Error fetching dayID: $e');
      return '';
    }
  }


  Future<void> fetchPointsOfInterest() async {
    try {
      // Fetch JSON data from the Flask API
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_df'));

      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);
        filteredPOIs.clear();
        allPOIs.clear();
        setState(() {
          allPOIs.addAll(dataList.map((item) => POI(
            poiID: item['poiID']?.toString() ?? '',
            poiType: item['poiType']?.toString() ?? '',
            poiName: item['poiName']?.toString() ?? '',
            poiAddress: item['poiAddress']?.toString() ?? '',
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
            poiLatitude: item['poiLatitude']?.toDouble() ?? '',
            poiLongitude: item['poiLongitude']?.toDouble() ?? '',
            imageUrl: '',
          )));
        });

        // Load the top 20 POIs initially
        filteredPOIs = allPOIs.take(20).toList();

        // Update the UI
        setState(() {});
      } else {
        // Handle error, e.g., print an error message
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }

  Future<void> fetchTripDetails() async {
    try {
      final tripSnapshot = await FirebaseFirestore.instance.collection('trip').doc(widget.tripId).get();
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
          name = userData['name']?.toString() ?? '';
          country = userData['country']?.toString() ?? '';
          gender = userData['gender']?.toString() ?? '';
          age = userData['age']?.toString() ?? '';
          dateOfBirth = userData['dateOfBirth']?.toString() ?? '';
          userID=userData['userID']?.toString() ?? '';
        });
      } else {
        print('User not found.');
      }
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
    }
  }

}


