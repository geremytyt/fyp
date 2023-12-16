import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:my_travel_mate/User/tripPage.dart';
import 'package:my_travel_mate/Widget/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../POI/viewPoiDetails.dart';

class TripDetails extends StatefulWidget {
  final String tripId;

  TripDetails({required this.tripId});

  @override
  _TripDetailsState createState() => _TripDetailsState();
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


class _TripDetailsState extends State<TripDetails> {
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
  List<POI> hotelList = [];
  List<POI> restaurantList = [];
  List<POI> attractionList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await loadUserData();
    await fetchTripDetails();
    fetchPointsOfInterest();
    LocationCoordinates coordinates = assignCoordinatesByLocation(tripLocation);
    fetchTopRatedPoi(coordinates.poiLatitude, coordinates.poiLongitude);
    fetchNearbyRestaurant(coordinates.poiLatitude, coordinates.poiLongitude);
    fetchTopRatedHotel(coordinates.poiLatitude, coordinates.poiLongitude);
    fetchDemographicRecommendations(country, age, gender);
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
      length: 3,
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
                  onTap: () {
                    _showDateRangePicker();
                  },
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
                  Tab(text: 'Explore'),
                  Tab(text: 'Hotel'),
                ],
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    buildItineraryTab(context, dates),
                    buildExploreTab(context),
                    buildHotelTab(context),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: SpeedDial(
          icon: Icons.menu,
          activeIcon: Icons.close,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          overlayColor: Colors.transparent,
          children: [
            SpeedDialChild(
              child: Icon(Icons.add),
              backgroundColor: Colors.blue,
              label: 'Add Day',
              labelStyle: TextStyle(fontSize: 14),
              onTap: () {
                addDayToTrip(widget.tripId);
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.edit),
              backgroundColor: Colors.blue,
              label: 'Edit Trip',
              labelStyle: TextStyle(fontSize: 14),
              onTap: () {
                showEditTripModal(context,tripName,tripLocation);
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.delete),
              backgroundColor: Colors.blue,
              label: 'Delete Trip',
              labelStyle: TextStyle(fontSize: 14),
              onTap: () {
                deleteTrip(widget.tripId);
              },
            ),
          ],
        ),

      ),
    );
  }

  void showEditTripModal(BuildContext context, String currentTripName, String currentTripLocation) {
    String newTripName = currentTripName;
    String newTripLocation = currentTripLocation;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Trip',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.0),

                  // Trip Name Input
                  TextFormField(
                    initialValue: currentTripName,
                    decoration: InputDecoration(labelText: 'Trip Name'),
                    onChanged: (value) {
                      setState(() {
                        newTripName = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),

                  // Trip Location Dropdown
                  DropdownButtonFormField<String>(
                    value: newTripLocation,
                    decoration: InputDecoration(labelText: 'Trip Location'),
                    items: statesOfMalaysia.map((state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        newTripLocation = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16.0),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the bottom sheet on cancel
                        },
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Save the changes and update the trip in the collection
                          editTrip(widget.tripId, newTripName, newTripLocation);
                          Navigator.of(context).pop(); // Close the bottom sheet on save
                        },
                        child: Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void editTrip(String tripId, String newTripName, String newTripLocation) async {
    try {
      await FirebaseFirestore.instance.collection('trip').doc(tripId).update({
        'tripName': newTripName,
        'tripLocation': newTripLocation,
      });

      showToast('Trip edited successfully.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => TripDetails(tripId: tripId),
        ),
      );
    } catch (e) {
      print('Error editing trip: $e');
      // Handle the error as needed
    }
  }

  void deleteTrip(String tripId) async {
    // Show a confirmation dialog
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this trip?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // User canceled the delete
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // User confirmed the delete
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        // Delete the trip from the trip collection
        await FirebaseFirestore.instance.collection('trip').doc(tripId).delete();

        // Delete the day documents associated with the trip
        QuerySnapshot daysSnapshot = await FirebaseFirestore.instance
            .collection('day')
            .where('tripID', isEqualTo: tripId)
            .get();
        for (QueryDocumentSnapshot dayDoc in daysSnapshot.docs) {
          String dayId = dayDoc['dayID'];
          await FirebaseFirestore.instance.collection('day').doc(dayId).delete();

          // Delete the activities associated with the day
          await FirebaseFirestore.instance.collection('activity').where('dayID', isEqualTo: dayId).get().then(
                (QuerySnapshot activitySnapshot) {
              for (QueryDocumentSnapshot activityDoc in activitySnapshot.docs) {
                String activityId = activityDoc['activityID'];
                FirebaseFirestore.instance.collection('activity').doc(activityId).delete();
              }
            },
          );
        }

        showToast('Trip deleted successfully.');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TripPage(),
          ),
        );
      } catch (e) {
        print('Error deleting trip: $e');
        // Handle the error as needed
      }
    }
  }



  Widget buildHotelTab(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Top Rated Hotels Nearby',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
          itemCount: topRatedHotelList.length,
          itemBuilder: (context, index) {
            return buildHotelCard(topRatedHotelList[index],selectedSource: 'topRated');
          },
        ),
      ],
    );
  }


  Widget buildExploreTab(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Top Rated Places',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final placeDetails in topRatedPoiList)
                buildPoiCard(placeDetails, selectedSource: 'topRated'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'You May Like',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final placeDetails in demographicPoiList)
                buildPoiCard(placeDetails, selectedSource: 'demographic'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Restaurants in $tripLocation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final placeDetails in nearbyRestaurantList)
                buildPoiCard(placeDetails, selectedSource: 'location'),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildHotelCard(POI placeDetails, {required String selectedSource}) {
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
              ElevatedButton.icon(
                icon: Icon(Icons.location_on, color: Colors.black54),
                label: Text(
                  'Add to Trip',
                  style: TextStyle(color: Colors.black54),
                ),
                onPressed: () {
                  if (selectedSource == 'topRated') {
                    // Add logic for Top Rated source
                    source = 'topRated';
                  } else if (selectedSource == 'demographic') {
                    // Add logic for Demographic source
                    source = 'demographic';
                  }
                  displayDaySelectionSheet(placeDetails);
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey[300],
                  elevation: 0,
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
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  Text(
                    ' ${double.parse(placeDetails.poiRating).toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.location_on, color: Colors.black54),
                label: Text(
                  'Add to Trip',
                  style: TextStyle(color: Colors.black54),
                ),
                onPressed: () {
                  if (selectedSource == 'topRated') {
                    source = 'topRated';
                  } else if (selectedSource == 'demographic') {
                    source = 'demographic';
                  } else if (selectedSource == 'location') {
                    source = 'location';
                  }
                  displayDaySelectionSheet(placeDetails);
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey[300],
                  elevation: 0,
                ),
              ),
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
        // Check if the index is the last one
        if (index == dates.length) {
          return Container();
        }
        Map<DateTime, String> lastPoiIDs = {};
        // Use FutureBuilder to handle asynchronous fetching of activities
        return FutureBuilder<String>(
          future: fetchDayID(widget.tripId, index < dates.length ? DateFormat('yyyy-MM-dd').format(dates[index]) : ''),
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
                          index < dates.length ? DateFormat('E d/MM').format(dates[index]) : '',
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
                                            if (poi.poiAddress != '-1') {
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('POI Name: ${poi.poiName}'),
                                                  Text('POI Address: ${poi.poiAddress}'),
                                                ],
                                              );
                                            } else {
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('POI Name: ${poi.poiName}'),
                                                ],
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      Text('Start Time: ${activity.activityStartTime}'),
                                      Text('End Time: ${activity.activityEndTime}'),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit),
                                            onPressed: () async {
                                              selectedPOI = await searchPointsOfInterestById(activity.poiID);

                                              selectedDay = dates[index];
                                              if (selectedPOI != null && selectedDay != null) {
                                                displayEditDaySheet(selectedPOI!, selectedDay!, activity.activityStartTime, activity.activityEndTime, activity.activityID);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete),
                                            onPressed: () {
                                              _showDeleteConfirmationDialog(context, activity.activityID);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                          ElevatedButton.icon(
                            icon: Icon(Icons.location_on, color: Colors.black54),
                            label: Text(
                              'Add POI',
                              style: TextStyle(color: Colors.black54),
                            ),
                            onPressed: () {
                              // Use the lastPoiID when the "Add POI" button is clicked
                              if (activities.isNotEmpty) {
                                lastPoiIDs[dates[index]] = activities.last.poiID;
                                // Fetch near points of interest
                                source = "location";
                                fetchNearPointsOfInterest(lastPoiIDs[dates[index]]!);
                                showCustomPopup(context, 'Places Nearby', 'Explore recommended places nearby! Press OK to continue.');
                                setState(() {});
                              } else {
                                source = "searched";
                                fetchPointsOfInterest();
                                showCustomPopup(context, 'Places', 'Find some places to add to your trip! Press OK to continue.');
                                setState(() {});
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Colors.grey[300],
                              elevation: 0,
                            ),
                          ),
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

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String activityID) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this activity?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog

                // Call the function to delete the activity
                await deleteActivity(activityID);

              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteActivity(String activityID) async {
    try {
      await FirebaseFirestore.instance.collection('activity').doc(activityID).delete();
      showToast('Activity removed.');
    } catch (e) {
      showToast('Error removing activity: $e');
    }
  }


  // void displayPoiList() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (BuildContext context) {
  //       return Container(
  //         padding: EdgeInsets.all(16.0),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Padding(
  //               padding: const EdgeInsets.all(8.0),
  //               child: TextField(
  //                 onChanged: (query) {
  //                   setState(() {
  //                     searchQuery = query;
  //                   });
  //                 },
  //                 onSubmitted: (query) {
  //                   if (query.isNotEmpty) {
  //                     // Perform search only when the query is not empty
  //                     source="searched";
  //
  //                   } else {
  //                     source="searched";
  //                     // Reset to the top 20 results when the query is empty
  //                     filteredPOIs = allPOIs.take(20).toList();
  //                     setState(() {});
  //                   }
  //                 },
  //                 decoration: InputDecoration(
  //                   hintText: 'Search POI',
  //                   prefixIcon: Icon(Icons.search),
  //                 ),
  //               ),
  //             ),
  //             Expanded(
  //               child: ListView.builder(
  //                 itemCount: filteredPOIs.length,
  //                 itemBuilder: (context, index) {
  //                   final poi = filteredPOIs[index];
  //                   return ListTile(
  //                     title: Row(
  //                       children: [
  //                         Expanded(
  //                           child: GestureDetector(
  //                             onTap: () {
  //                               // Navigate to ViewPoiDetailsPage with the selected poiID
  //                               Navigator.push(
  //                                 context,
  //                                 MaterialPageRoute(
  //                                   builder: (context) => ViewPoiDetailsPage(poiID: poi.poiID),
  //                                 ),
  //                               );
  //                             },
  //                             child: Column(
  //                               crossAxisAlignment: CrossAxisAlignment.start,
  //                               children: [
  //                                 Text(poi.poiName),
  //                                 Text(poi.poiID),
  //                                 if (isValidDouble(poi.poiLocation))
  //                                   Text('${double.parse(poi.poiLocation).toStringAsFixed(2)} km'),
  //                               ],
  //                             ),
  //                           ),
  //                         ),
  //                         ElevatedButton(
  //                           onPressed: () {
  //                             displayDaySelectionSheet(poi);
  //                           },
  //                           style: ElevatedButton.styleFrom(
  //                             primary: Theme.of(context).primaryColor,
  //                           ),
  //                           child: Icon(Icons.add),
  //                         ),
  //                       ],
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  void displayPoiList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (query) {
                    performSearch(query);
                  },
                  onSubmitted: (query) {
                    fetchPointsOfInterest();
                    if (query.isNotEmpty) {
                      // Perform search only when the query is not empty
                      performSearch(query);
                    } else {
                      // Reset to the top 20 results when the query is empty
                      filteredPOIs = allPOIs.take(20).toList();
                      setState(() {});
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Search POI',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredPOIs.length,
                  itemBuilder: (context, index) {
                    final poi = filteredPOIs[index];
                    return ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Navigate to ViewPoiDetailsPage with the selected poiID
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ViewPoiDetailsPage(poiID: poi.poiID),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(poi.poiName),
                                  Text(poi.poiType),
                                  if (isValidDouble(poi.poiLocation))
                                    Text('${double.parse(poi.poiLocation).toStringAsFixed(2)} km'),
                                ],
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              displayDaySelectionSheet(poi);
                            },
                            style: ElevatedButton.styleFrom(
                              primary: Theme.of(context).primaryColor,
                            ),
                            child: Icon(Icons.add),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void performSearch(String query) {
    if (query.isNotEmpty) {
      setState(() {
        filteredPOIs = filterPOIs(query);
      });
    } else {
      // Display default list when the query is empty
      setState(() {
        filteredPOIs = allPOIs.take(20).toList();
      });
    }
  }


  List<POI> filterPOIs(String query) {
    return allPOIs
        .where((poi) =>
    poi.poiName.toLowerCase().contains(query.toLowerCase()) ||
        poi.poiType.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> fetchNearPointsOfInterest(String poiID) async {
    try {
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_nearby_points_of_interest?query=$poiID'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check if the response contains the "top_50_nearby_points" key
        if (data.containsKey("top_50_nearby_points")) {
          final List<dynamic> dataList = data["top_50_nearby_points"];
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
              poiLatitude: item['poiLatitude']?.toDouble() ?? 0.0,
              poiLongitude: item['poiLongitude']?.toDouble() ?? 0.0,
              imageUrl: '',
            )));
          });

          // Load the top 20 POIs initially
          filteredPOIs = allPOIs.take(20).toList();

          // Update the UI
          setState(() {});
        } else {
          print('Error: Response does not contain the "top_50_nearby_points" key.');
        }
      } else {
        // Handle error, e.g., print an error message
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }

  Future<void> fetchPointsOfInterest() async {
    try {
      // Fetch JSON data from the Flask API
      final response =
      await http.get(Uri.parse('http://34.124.197.131:5000/get_all_poi_df'));

      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);
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
            poiLatitude: item['poiLatitude']?.toDouble() ?? 0.0,
            poiLongitude: item['poiLongitude']?.toDouble() ?? 0.0,
            imageUrl: '',
          )));
        });

        filteredPOIs = allPOIs.take(20).toList();

        // Update the UI
        setState(() {});
      } else {
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }


  bool isValidDouble(String value) {
    if (value == '-1') {
      return false; // Exclude the specific value '-1.00'
    }

    try {
      // Try parsing the string to a double
      double.parse(value);
      // If successful, it's a valid double
      return true;
    } catch (e) {
      // If an exception occurs, it's not a valid double
      return false;
    }
  }

  void showCustomPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                displayPoiList();
              },
              child: Text('OK'),
            ),
          ],
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


  Future<void> _showDateRangePicker() async {
    DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(
        start: DateTime.parse(tripStartDate),
        end: DateTime.parse(tripEndDate),
      ),
    );

    if (pickedDateRange != null) {
      setState(() {
        tripStartDate = pickedDateRange.start.toLocal().toString();
        tripEndDate = pickedDateRange.end.toLocal().toString();
      });

      // Update the trip dates in Firestore
      await updateTripDateRange(pickedDateRange);
    }
  }

  Future<void> updateTripDateRange(DateTimeRange pickedDateRange) async {
    try {
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

      // Fetch existing days for the trip
      QuerySnapshot daysQuery = await FirebaseFirestore.instance
          .collection('day')
          .where('tripID', isEqualTo: widget.tripId)
          .get();

      List<DocumentSnapshot> existingDays = daysQuery.docs;

      // Convert the picked date range to a list of dates
      List<DateTime> newDates = List.generate(
        pickedDateRange.end.difference(pickedDateRange.start).inDays + 1,
            (index) => pickedDateRange.start.add(Duration(days: index)),
      );

      // Update or add days based on the new date range
      for (int i = 0; i < newDates.length; i++) {
        DateTime currentDate = newDates[i];
        String formattedDate = dateFormat.format(currentDate);

        // Check if a day already exists for the current date
        DocumentSnapshot? existingDay = findFirstWhereOrNull(
          existingDays,
              (day) => day['dayDate'] == formattedDate,
        );

        if (existingDay != null) {
          // Update existing day
          await existingDay.reference.update({
            'dayDate': formattedDate,
          });
          existingDays.remove(existingDay); // Remove from the list of existing days
        } else {
          // Create a new day if it doesn't exist
          String newDayID = await generateNewDayID();
          await FirebaseFirestore.instance.collection('day').doc(newDayID).set({
            'dayID': newDayID,
            'tripID': widget.tripId,
            'dayDate': formattedDate,
          });
        }
      }

      // Remove days that are no longer part of the date range
      for (int i = 0; i < existingDays.length; i++) {
        DocumentSnapshot day = existingDays[i];
        await deleteDayAndActivities(day);
      }

      // Update tripStartDate and tripEndDate in the 'trip' collection
      DateTime firstDate = newDates.first;
      DateTime lastDate = newDates.last;

      await FirebaseFirestore.instance.collection('trip').doc(widget.tripId).update({
        'tripStartDate': dateFormat.format(firstDate),
        'tripEndDate': dateFormat.format(lastDate),
      });
    } catch (e) {
      print('Error updating trip dates: $e');
    }
  }


  Future<void> updateTripEndDate(String tripId, String newEndDate) async {
    await FirebaseFirestore.instance.collection('trip').doc(tripId).update({
      'tripEndDate': newEndDate,
    });
  }


  Future<void> deleteDayAndActivities(DocumentSnapshot day) async {
    // Get the dayID
    String dayID = day['dayID'];

    // Fetch activities for the day
    QuerySnapshot activitiesQuery = await FirebaseFirestore.instance
        .collection('activity')
        .where('dayID', isEqualTo: dayID)
        .get();

    // Delete each activity
    for (QueryDocumentSnapshot activity in activitiesQuery.docs) {
      await activity.reference.delete();
    }

    // Delete the day
    await day.reference.delete();
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

  void displayEditDaySheet(POI poi, DateTime selectedDay, String startTime, String endTime, String activityID) {
    TextEditingController newStartTimeController = TextEditingController(text: startTime);
    TextEditingController newEndTimeController = TextEditingController(text: endTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, // Adjust padding based on keyboard height
              left: 16.0,
              right: 16.0,
              top: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Time',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                // Display the selected day and time
                ListTile(
                  title: Text('Selected Day: ${DateFormat('E d/MM').format(selectedDay)}'),
                  subtitle: Text('Selected Time: $startTime - $endTime'),
                ),
                // Show text fields for editing start and end times
                TextField(
                  controller: newStartTimeController,
                  decoration: InputDecoration(labelText: 'New Start Time (HH:mm)'),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    MaskedTextInputFormatter(mask: 'HH:mm'),
                  ],
                ),
                TextField(
                  controller: newEndTimeController,
                  decoration: InputDecoration(labelText: 'New End Time (HH:mm)'),
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [
                    MaskedTextInputFormatter(mask: 'HH:mm'),
                  ],
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        String newStartTime = newStartTimeController.text.trim();
                        String newEndTime = newEndTimeController.text.trim();

                        // Validate the input
                        if (newStartTime.isEmpty || newEndTime.isEmpty) {
                          showToast('Please enter start and end time');
                        } else {
                          // Proceed with confirmation
                          bool? confirmEdit = await _confirmEditPoiInDay(context, poi, selectedDay, startTime, endTime, newStartTime, newEndTime);

                          if (confirmEdit == true) {
                            // User confirmed the edit, proceed with editing
                            await editPoiInTrip(poi, selectedDay, startTime, endTime, newStartTime, newEndTime, activityID);
                          } else {
                            showToast('Edit cancelled');
                          }
                        }
                        Navigator.of(context).pop();
                      },
                      child: Text('OK'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmEditPoiInDay(BuildContext context, POI poi, DateTime selectedDay, String startTime, String endTime, String newStartTime, String newEndTime) async {
    return await showDialog<bool?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Edit'),
          content: Text('Are you sure you want to edit this POI in the selected day?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled the edit
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed the edit
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editPoiInTrip(POI poi, DateTime selectedDay, String startTime, String endTime, String newStartTime, String newEndTime, String activityID) async {
    try {
      String formattedSelectedDay = DateFormat('yyyy-MM-dd').format(selectedDay);

      // Fetch the dayID based on the selected day and tripID
      String tripID = widget.tripId;
      String dayID = await fetchDayID(tripID, formattedSelectedDay);

      // Update the activity with the new start and end times
      await FirebaseFirestore.instance.collection('activity').doc(activityID).update({
        'activityStartTime': newStartTime,
        'activityEndTime': newEndTime,
        'dayID':dayID,
      });

      print('POI edited successfully in the selected day.');
    } catch (e) {
      print('Error editing POI in the selected day: $e');
      // Handle error
    }
  }

  void displayDaySelectionSheet(POI poi) {
    List<DateTime> dates = getItineraryDates();
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
              // Display a list of days
              ListView.builder(
                shrinkWrap: true,
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final day = dates[index];
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
                                    showToast('Please enter start and end time');
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

  Future<bool> checkTimeConflict(DateTime selectedDay, String newStartTime, String newEndTime) async {
    // Fetch existing activities for the selected day
    String formattedSelectedDay = DateFormat('yyyy-MM-dd').format(selectedDay);
    String dayID = await fetchDayID(widget.tripId, formattedSelectedDay);
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
    DateTime start1 = DateTime.parse('2023-01-01 ' + startTime1);
    DateTime end1 = DateTime.parse('2023-01-01 ' + endTime1);
    DateTime start2 = DateTime.parse('2023-01-01 ' + startTime2);
    DateTime end2 = DateTime.parse('2023-01-01 ' + endTime2);

    // Check for overlap
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  Future<void> addPoiToTrip(POI poi, DateTime selectedDay, String startTime, String endTime) async {
    try {

      String formattedSelectedDay = DateFormat('yyyy-MM-dd').format(selectedDay);

      DateTime currentDate = DateTime.now();
      String formattedCurrentDate = DateFormat('yyyy-MM-dd').format(currentDate);

      // Fetch the dayID based on the selected day and tripID
      String tripID = widget.tripId;
      String dayID = await fetchDayID(tripID, formattedSelectedDay);

      String activityID = await generateNewActivityID();
      await FirebaseFirestore.instance.collection('activity').doc(activityID).set({
        'activityID': activityID,
        'dayID': dayID,
        'poiID': poi.poiID,
        'activityStartTime': startTime,
        'activityEndTime': endTime,
        'source':source,
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
    } catch (e) {
      showToast('Error adding POI to trip: $e');
    }
  }

  Future<void> addDayToTrip(String tripID) async {
    try {
      DateTime currentDate = DateTime.now();
      DateTime newDate;

      // Fetch the trip document to get the tripEndDate
      DocumentSnapshot tripSnapshot = await FirebaseFirestore.instance
          .collection('trip')
          .doc(tripID)
          .get();

      if (tripSnapshot.exists) {
        // Parse the tripEndDate string into a DateTime object
        String tripEndDateString = tripSnapshot['tripEndDate'];
        DateTime tripEndDate = DateTime.parse(tripEndDateString);

        // Calculate the new date by adding one day to the tripEndDate
        newDate = tripEndDate.add(Duration(days: 1));
      } else {
        // If the trip document doesn't exist, default to the current date
        newDate = currentDate;
      }

      // Format the new date
      String formattedDate = DateFormat('yyyy-MM-dd').format(newDate);

      // Generate a new dayID
      String newDayID = await generateNewDayID();

      // Assign the tripID to the new day
      await FirebaseFirestore.instance.collection('day').doc(newDayID).set({
        'dayID': newDayID,
        'tripID': tripID,
        'dayDate': formattedDate,
      });

      // Update the tripEndDate in the trip database
      await updateTripEndDate(tripID, formattedDate);

      showToast('Day added successfully: $newDayID');
    } catch (e) {
      showToast('Error adding day to trip: $e');
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

  Future<String> generateNewDayID() async {
    try {
      // Fetch the number of documents in the 'day' collection
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('day').get();

      if (querySnapshot.docs.isEmpty) {
        // If there are no existing days, start with D00001
        return 'D00001';
      }

      // Find the maximum day ID
      String lastDayID = querySnapshot.docs.last['dayID'];
      int lastId = int.parse(lastDayID.substring(1));

      // Increment the counter for the new day
      int newDayId = lastId + 1;

      // Generate a new dayID in the format 'Dxxxxx' based on the incremented value
      String newDayID = 'D' + newDayId.toString().padLeft(5, '0');

      return newDayID;
    } catch (e) {
      print('Error generating new dayID: $e');
      // Handle error, you might want to return a default or throw an exception
      return '';
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


  // Future<void> fetchPointsOfInterest() async {
  //   try {
  //     // Fetch JSON data from the Flask API
  //     final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_df'));
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> dataList = json.decode(response.body);
  //       filteredPOIs.clear();
  //       allPOIs.clear();
  //       setState(() {
  //         allPOIs.addAll(dataList.map((item) => POI(
  //           poiID: item['poiID']?.toString() ?? '',
  //           poiType: item['poiType']?.toString() ?? '',
  //           poiName: item['poiName']?.toString() ?? '',
  //           poiAddress: item['poiAddress']?.toString() ?? '',
  //           poiLocation: item['poiLocation']?.toString() ?? '',
  //           poiUrl: item['poiUrl']?.toString() ?? '',
  //           poiPriceRange: item['poiPriceRange']?.toString() ?? '',
  //           poiPrice: item['poiPrice']?.toString() ?? '',
  //           poiPhone: item['poiPhone']?.toString() ?? '',
  //           poiTag: item['poiTag']?.toString() ?? '',
  //           poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
  //           poiRating: item['poiRating']?.toString() ?? '',
  //           poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
  //           poiDescription: item['poiDescription']?.toString() ?? '',
  //           poiLatitude: item['poiLatitude']?.toDouble() ?? '',
  //           poiLongitude: item['poiLongitude']?.toDouble() ?? '',
  //           imageUrl: '',
  //         )));
  //       });
  //
  //       // Load the top 20 POIs initially
  //       filteredPOIs = allPOIs.take(20).toList();
  //
  //       // Update the UI
  //       setState(() {});
  //     } else {
  //       // Handle error, e.g., print an error message
  //       print('Failed to fetch JSON data. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error loading POIs from JSON: $e');
  //   }
  // }

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


  // Future<void> searchPointsOfInterest(String query) async {
  //   try {
  //     // Fetch JSON data from the Flask API based on the search query
  //     final response = await http.get(Uri.parse('http://34.124.197.131:5000/search_poi?query=$query'));
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> dataList = json.decode(response.body);
  //       setState(() {
  //         // Clear existing data before adding new search results
  //         filteredPOIs.clear();
  //         filteredPOIs.addAll(dataList.map((item) => POI(
  //           poiID: item['poiID']?.toString() ?? '',
  //           poiType: item['poiType']?.toString() ?? '',
  //           poiName: item['poiName']?.toString() ?? '',
  //           poiAddress: item['poiAddress']?.toString() ?? '',
  //           poiLocation: item['poiLocation']?.toString() ?? '',
  //           poiUrl: item['poiUrl']?.toString() ?? '',
  //           poiPriceRange: item['poiPriceRange']?.toString() ?? '',
  //           poiPrice: item['poiPrice']?.toString() ?? '',
  //           poiPhone: item['poiPhone']?.toString() ?? '',
  //           poiTag: item['poiTag']?.toString() ?? '',
  //           poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
  //           poiRating: item['poiRating']?.toString() ?? '',
  //           poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
  //           poiDescription: item['poiDescription']?.toString() ?? '',
  //           poiLatitude: item['poiLatitude']?.toDouble() ?? '',
  //           poiLongitude: item['poiLongitude']?.toDouble() ?? '',
  //           imageUrl: '',
  //         )));
  //       });
  //
  //       // Update the UI
  //       setState(() {});
  //     } else {
  //       // Handle error, e.g., print an error message
  //       print('Failed to fetch search results. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error searching POIs: $e');
  //   }
  // }

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

  // Future<void> fetchTopRatedPoi() async {
  //   try {
  //     final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_top_rated_poi'));
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> dataList = json.decode(response.body);
  //
  //       // Fetch details for each POI
  //       for (final item in dataList) {
  //         await fetchImageForPOI(item);
  //       }
  //
  //       setState(() {
  //         topRatedPoiList.addAll(dataList.map((item) => POI(
  //           poiID: item['poiID']?.toString() ?? '',
  //           poiType: item['poiType']?.toString() ?? '',
  //           poiName: item['poiName']?.toString() ?? '',
  //           poiAddress: item['poiAddress']?.toString() ?? '',
  //           poiLocation: item['poiLocation']?.toString() ?? '',
  //           poiUrl: item['poiUrl']?.toString() ?? '',
  //           poiPriceRange: item['poiPriceRange']?.toString() ?? '',
  //           poiPrice: item['poiPrice']?.toString() ?? '',
  //           poiPhone: item['poiPhone']?.toString() ?? '',
  //           poiTag: item['poiTag']?.toString() ?? '',
  //           poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
  //           poiRating: item['poiRating']?.toString() ?? '',
  //           poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
  //           poiDescription: item['poiDescription']?.toString() ?? '',
  //           poiLatitude: item['poiLatitude']?.toDouble() ?? '',
  //           poiLongitude: item['poiLongitude']?.toDouble() ?? '',
  //           imageUrl: item['imageUrl']?.toString() ?? '',
  //         )));
  //       });
  //     } else {
  //       setState(() {
  //         errorMessage = 'Error: ${response.statusCode}';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       errorMessage = 'Error: $e';
  //     });
  //   }
  // }

  // Future<void> fetchTopRatedPoi(String type) async {
  //   try {
  //     final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_top_rated_poi'));
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> dataList = json.decode(response.body);
  //
  //       // Fetch details for each POI
  //       for (final item in dataList) {
  //         await fetchImageForPOI(item);
  //       }
  //
  //       // Dynamically filter based on the input type
  //       final filteredPoiList = dataList
  //           .where((item) => item['poiType']?.toString() == type)
  //           .map((item) => POI(
  //         poiID: item['poiID']?.toString() ?? '',
  //         poiType: item['poiType']?.toString() ?? '',
  //         poiName: item['poiName']?.toString() ?? '',
  //         poiAddress: item['poiAddress']?.toString() ?? '',
  //         poiLocation: item['poiLocation']?.toString() ?? '',
  //         poiUrl: item['poiUrl']?.toString() ?? '',
  //         poiPriceRange: item['poiPriceRange']?.toString() ?? '',
  //         poiPrice: item['poiPrice']?.toString() ?? '',
  //         poiPhone: item['poiPhone']?.toString() ?? '',
  //         poiTag: item['poiTag']?.toString() ?? '',
  //         poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
  //         poiRating: item['poiRating']?.toString() ?? '',
  //         poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
  //         poiDescription: item['poiDescription']?.toString() ?? '',
  //         poiLatitude: item['poiLatitude']?.toDouble() ?? '',
  //         poiLongitude: item['poiLongitude']?.toDouble() ?? '',
  //         imageUrl: item['imageUrl']?.toString() ?? '',
  //       ))
  //           .toList();
  //
  //       setState(() {
  //         topRatedPoiList.clear(); // Clear existing list
  //         topRatedPoiList.addAll(filteredPoiList); // Add filtered results
  //       });
  //     } else {
  //       setState(() {
  //         errorMessage = 'Error: ${response.statusCode}';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       errorMessage = 'Error: $e';
  //     });
  //   }
  // }

  // Future<void> fetchTopRatedPoi(String type, double latitude, double longitude) async {
  //   try {
  //     final String apiUrl = 'http://34.124.197.131:5000/get_top_rated_poi_in_location';
  //     final Map<String, String> queryParams = {
  //       'latitude': latitude.toString(),
  //       'longitude': longitude.toString(),
  //     };
  //     final Uri uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);
  //
  //     final response = await http.get(uri);
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> dataList = json.decode(response.body);
  //
  //       // Fetch details for each POI
  //       for (final item in dataList) {
  //         await fetchImageForPOI(item);
  //       }
  //
  //       // Dynamically filter based on the input type
  //       final filteredPoiList = dataList
  //           .where((item) => item['poiType']?.toString() == type)
  //           .map((item) => POI(
  //         poiID: item['poiID']?.toString() ?? '',
  //         poiType: item['poiType']?.toString() ?? '',
  //         poiName: item['poiName']?.toString() ?? '',
  //         poiAddress: item['poiAddress']?.toString() ?? '',
  //         poiLocation: item['poiLocation']?.toString() ?? '',
  //         poiUrl: item['poiUrl']?.toString() ?? '',
  //         poiPriceRange: item['poiPriceRange']?.toString() ?? '',
  //         poiPrice: item['poiPrice']?.toString() ?? '',
  //         poiPhone: item['poiPhone']?.toString() ?? '',
  //         poiTag: item['poiTag']?.toString() ?? '',
  //         poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
  //         poiRating: item['poiRating']?.toString() ?? '',
  //         poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
  //         poiDescription: item['poiDescription']?.toString() ?? '',
  //         poiLatitude: item['poiLatitude']?.toDouble() ?? '',
  //         poiLongitude: item['poiLongitude']?.toDouble() ?? '',
  //         imageUrl: item['imageUrl']?.toString() ?? '',
  //       ))
  //           .toList();
  //
  //       setState(() {
  //         topRatedPoiList.clear(); // Clear existing list
  //         topRatedPoiList.addAll(filteredPoiList); // Add filtered results
  //       });
  //     } else {
  //       setState(() {
  //         errorMessage = 'Error: ${response.statusCode}';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       errorMessage = 'Error: $e';
  //     });
  //   }
  // }


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

  Future<void> fetchDemographicRecommendations(String country, String age, String gender) async {
    try {
      final String apiUrl = 'http://34.124.197.131:5000/get_demographic_recommendations';

      Map<String, dynamic> data = {
        'country': country,
        'age': age,
        'gender': gender,
      };

      // Fetch JSON data from the Flask API using a POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);

        // Check if the dataMap contains a key representing the list of POIs
        if (dataMap.containsKey('error')) {
          print('Error: ${dataMap['error']}');
        } else {
          final List<dynamic> dataList = dataMap['top_10_demo'];
          demographicPoiList.clear();

          for (var item in dataList) {
            await fetchImageForPOI(item); // Fetch image for each POI
            demographicPoiList.add(POI(
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
              imageUrl: item['imageUrl']?.toString() ?? '',
            ));
          }

          // Update the UI
          setState(() {});
        }
      } else {
        // Handle error, e.g., print an error message
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }

  Future<void> fetchNearbyRestaurant(double latitude, double longitude) async {
    try {
      final String apiUrl = 'http://34.124.197.131:5000/get_restaurant_in_location';
      final Map<String, String> queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };
      final Uri uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey("restaurant_in_location")) {
          nearbyRestaurantList.clear();
          final List<dynamic> dataList = data["restaurant_in_location"];
          for (var item in dataList) {
            await fetchImageForPOI(item); // Fetch image for each POI
            nearbyRestaurantList.add(POI(
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
              imageUrl: item['imageUrl']?.toString() ?? '',
            ));
          }

          //topRatedHotelList = List.from(topRatedPoiList);
          // Update the state with the filtered list
          setState(() {});

        } else {
          // Handle the case when the key is not present in the response
          setState(() {
            errorMessage = 'Error: "top_rated_restaurant_in_location" key not found in response';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> fetchTopRatedPoi(double latitude, double longitude) async {
    try {
      final String apiUrl = 'http://34.124.197.131:5000/get_top_rated_poi_in_location';
      final Map<String, String> queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };
      final Uri uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey("top_rated_poi_in_location")) {
          topRatedPoiList.clear();
          final List<dynamic> dataList = data["top_rated_poi_in_location"];
          for (var item in dataList) {
            await fetchImageForPOI(item); // Fetch image for each POI
            topRatedPoiList.add(POI(
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
              imageUrl: item['imageUrl']?.toString() ?? '',
            ));
          }
          setState(() {});

        } else {
          setState(() {
            errorMessage = 'Error: "top_rated_poi_in_location" key not found in response';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> fetchTopRatedHotel(double latitude, double longitude) async {
    try {
      final String apiUrl = 'http://34.124.197.131:5000/get_top_rated_hotel_in_location';
      final Map<String, String> queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };
      final Uri uri = Uri.parse(apiUrl).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey("top_rated_hotel_in_location")) {
          topRatedHotelList.clear();
          final List<dynamic> dataList = data["top_rated_hotel_in_location"];
          for (var item in dataList) {
            await fetchImageForPOI(item); // Fetch image for each POI
            topRatedHotelList.add(POI(
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
              imageUrl: item['imageUrl']?.toString() ?? '',
            ));
          }

          setState(() {});

        } else {
          // Handle the case when the key is not present in the response
          setState(() {
            errorMessage = 'Error: "top_rated_hotel_in_location" key not found in response';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

}


