import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_travel_mate/User/submitReview.dart';
import 'package:my_travel_mate/User/viewReviewPage.dart';

class ReviewsPage extends StatefulWidget {
  final String userId;

  ReviewsPage({required this.userId});

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
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

class _ReviewsPageState extends State<ReviewsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reviews'),
          backgroundColor: Theme.of(context).primaryColor,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Past'),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: TabBarView(
          children: [
            buildReviewsList(context, true),  // Pending Reviews
            buildReviewsList(context, false), // Past Reviews
          ],
        ),
      ),
    );
  }

  Widget buildReviewsList(BuildContext context, bool pending) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchData(pending),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final data = snapshot.data ?? [];
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  final poiDetails = await searchPointsOfInterestById(data[index]['poiID']);

                  if (pending) {
                    // Navigate to SubmitReviewPage for Pending reviews
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmitReviewPage(
                          tripID: data[index]['tripID'],
                          tripName: data[index]['tripName'],
                          dayDate: data[index]['dayDate'],
                          activityID: data[index]['activityID'],
                          poiID: poiDetails.poiID,
                        ),
                      ),
                    );
                  } else {
                    // Navigate to ViewReviewPage for Past reviews
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewReviewPage(
                          tripID: data[index]['tripID'],
                          tripName: data[index]['tripName'],
                          dayDate: data[index]['dayDate'],
                          activityID: data[index]['activityID'],
                          poiID: poiDetails.poiID,
                        ),
                      ),
                    );
                  }
                },
                child: ListTile(
                  title: FutureBuilder<POI>(
                    future: searchPointsOfInterestById(data[index]['poiID']),
                    builder: (context, poiSnapshot) {
                      if (poiSnapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (poiSnapshot.hasError) {
                        return Text('Error fetching POI details: ${poiSnapshot.error}');
                      } else {
                        final poiDetails = poiSnapshot.data;
                        return Text(poiDetails?.poiName ?? 'N/A');
                      }
                    },
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trip ID: ${data[index]['tripID']}'),
                      Text('Trip Name: ${data[index]['tripName']}'),
                      Text('Day Date: ${data[index]['dayDate']}'),
                      Text('Activity ID: ${data[index]['activityID']}'),
                      if (!pending)
                        Row(
                          children: [
                            Text('Rating: ${data[index]['activityRating']}'),
                            Icon(
                              Icons.star,
                              color: Colors.yellow,
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
      },
    );
  }


  Future<List<Map<String, dynamic>>> fetchData(bool pending) async {
    try {
      final tripQuerySnapshot = await FirebaseFirestore.instance
          .collection('trip')
          .where('userID', isEqualTo: widget.userId)
          .get();

      final tripIDs = tripQuerySnapshot.docs.map((doc) => doc.id).toList();

      final dayIDs = <String>[];
      for (final tripID in tripIDs) {
        final tripData = tripQuerySnapshot.docs
            .firstWhere((doc) => doc.id == tripID)
            .data() as Map<String, dynamic>;

        final tripEndDate = DateTime.parse(tripData['tripEndDate'] as String);

        // Check if trip end date has passed the current date
        if (tripEndDate.isBefore(DateTime.now())) {
          final dayQuerySnapshot = await FirebaseFirestore.instance
              .collection('day')
              .where('tripID', isEqualTo: tripID)
              .get();
          dayIDs.addAll(dayQuerySnapshot.docs.map((doc) => doc.id));
        }
      }

      final activityIDs = <String>[];
      for (final dayID in dayIDs) {
        final activityQuerySnapshot = await FirebaseFirestore.instance
            .collection('activity')
            .where('dayID', isEqualTo: dayID)
            .get();
        activityIDs.addAll(activityQuerySnapshot.docs.map((doc) => doc.id));
      }

      final reviewsData = <Map<String, dynamic>>[];
      for (final activityID in activityIDs) {
        final activityData = (await FirebaseFirestore.instance
            .collection('activity')
            .doc(activityID)
            .get())
            .data() as Map<String, dynamic>;

        final dayData = (await FirebaseFirestore.instance
            .collection('day')
            .doc(activityData['dayID'])
            .get())
            .data() as Map<String, dynamic>;

        final tripID = dayData['tripID'];
        final tripData = (await FirebaseFirestore.instance
            .collection('trip')
            .doc(tripID)
            .get())
            .data() as Map<String, dynamic>;

        final rating = activityData['activityRating'];
        final isRatingEmpty = rating == null || rating.isEmpty;

        if (pending && isRatingEmpty) {
          reviewsData.add({
            'tripID': tripID,
            'tripName': tripData['tripName'],
            'dayDate': dayData['dayDate'],
            'activityID': activityID,
            'poiID': activityData['poiID'],
          });
        } else if (!pending && !isRatingEmpty) {
          reviewsData.add({
            'tripID': tripID,
            'tripName': tripData['tripName'],
            'dayDate': dayData['dayDate'],
            'activityID': activityID,
            'poiID': activityData['poiID'],
            'activityRating': activityData['activityRating'],
          });
        }
      }

      return reviewsData;
    } catch (e) {
      print('Error fetching data: $e');
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
    );
  }
}
