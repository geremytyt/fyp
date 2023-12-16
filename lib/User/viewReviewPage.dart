import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewReviewPage extends StatefulWidget {
  final String tripID;
  final String tripName;
  final String dayDate;
  final String activityID;
  final String poiID;

  ViewReviewPage({
    required this.tripID,
    required this.tripName,
    required this.dayDate,
    required this.activityID,
    required this.poiID,
  });

  @override
  _ViewReviewPageState createState() => _ViewReviewPageState();
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

class _ViewReviewPageState extends State<ViewReviewPage> {
  late POI poiDetails;
  double activityRating = 0.0;
  String activityReview = '';
  double recommendationRating = 0.0;
  String recommendationReview = '';

  @override
  void initState() {
    super.initState();
    fetchPoiDetails();
    fetchActivityDetails();
    fetchRecommendationDetails(); // Will only fetch if recommendation exists
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Review'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POI Name: ${poiDetails.poiName}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            Text('Trip ID: ${widget.tripID}'),
            Text('Trip Name: ${widget.tripName}'),
            Text('Day Date: ${widget.dayDate}'),
            Text('Activity ID: ${widget.activityID}'),
            SizedBox(height: 16.0),
            Text('Activity Rating:'),
            Row(
              children: [
                for (int i = 1; i <= activityRating.ceil(); i++)
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
              ],
            ),
            SizedBox(height: 16.0),
            Text('Activity Review:'),
            TextField(
              controller: TextEditingController(text: activityReview),
              maxLines: 3,
              enabled: false, // Set to false to make it non-editable
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            if (recommendationRating > 0.0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recommendation Rating:'),
                  Row(
                    children: [
                      for (int i = 1; i <= recommendationRating.ceil(); i++)
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Text('Recommendation Review:'),
                  TextField(
                    controller: TextEditingController(text: recommendationReview),
                    maxLines: 3,
                    enabled: false, // Set to false to make it non-editable
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchPoiDetails() async {
    try {
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_based_on_id?query=${widget.poiID}'));

      if (response.statusCode == 200) {
        List<dynamic> responseDataList = json.decode(response.body);

        if (responseDataList.isNotEmpty) {
          dynamic responseData = responseDataList[0];

          if (responseData is Map<String, dynamic>) {
            setState(() {
              poiDetails = POI(
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
            });
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
  }

  Future<void> fetchActivityDetails() async {
    try {
      // Fetch activity details based on activityID
      // Replace 'activity' with the actual collection name in your Firestore database
      final activitySnapshot = await FirebaseFirestore.instance
          .collection('activity')
          .doc(widget.activityID)
          .get();

      if (activitySnapshot.exists) {
        setState(() {
          activityRating = double.tryParse(activitySnapshot['activityRating'] ?? '0.0') ?? 0.0;
          activityReview = activitySnapshot['activityReview'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching activity details: $e');
    }
  }

  Future<void> fetchRecommendationDetails() async {
    try {

      final recommendationSnapshot = await FirebaseFirestore.instance
          .collection('recommendation')
          .where('activityID', isEqualTo: widget.activityID)
          .get();

      if (recommendationSnapshot.docs.isNotEmpty) {
        setState(() {
          recommendationRating = double.tryParse(recommendationSnapshot.docs.first['recommendationRating'] ?? '0.0') ?? 0.0;
          recommendationReview = recommendationSnapshot.docs.first['recommendationReview'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching recommendation details: $e');
    }
  }
}
