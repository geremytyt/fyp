import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SubmitReviewPage extends StatefulWidget {
  final String tripID;
  final String tripName;
  final String dayDate;
  final String activityID;
  final String poiID;

  SubmitReviewPage({
    required this.tripID,
    required this.tripName,
    required this.dayDate,
    required this.activityID,
    required this.poiID,
  });

  @override
  _SubmitReviewPageState createState() => _SubmitReviewPageState();
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

class Recommendation {
  final String recommendationID;
  final String activityID;
  final String recommendationDate;
  final String recommendationFactor;
  final String recommendationReview;
  final double recommendationRating;

  Recommendation({
    required this.recommendationID,
    required this.activityID,
    required this.recommendationDate,
    required this.recommendationFactor,
    required this.recommendationReview,
    required this.recommendationRating,
  });
}

class _SubmitReviewPageState extends State<SubmitReviewPage> {
  double userRating = 0.0;
  double recommendationRating = 0.0;
  TextEditingController reviewController = TextEditingController();
  TextEditingController recommendationReviewController = TextEditingController();
  late POI poiDetails;
  Recommendation? recommendationDetails;
  File? imageFile;

  String ratingError = '';
  String reviewError = '';
  String recommendationRatingError = '';
  String recommendationReviewError = '';

  @override
  void initState() {
    super.initState();
    fetchPoiDetails();
    if (widget.activityID.isNotEmpty) {
      fetchRecommendationDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Review'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<POI>(
                future: fetchPoiDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error fetching POI details: ${snapshot.error}');
                  } else {
                    final poiDetails = snapshot.data;
                    return Text(
                      'POI Name: ${poiDetails?.poiName ?? 'N/A'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    );
                  }
                },
              ),
              Text('Trip ID: ${widget.tripID}'),
              Text('Trip Name: ${widget.tripName}'),
              Text('Day Date: ${widget.dayDate}'),
              Text('Activity ID: ${widget.activityID}'),
              SizedBox(height: 16.0),
              Text('Rate the Place:'),
              RatingBar.builder(
                initialRating: userRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 30.0,
                itemBuilder: (context, _) => Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    userRating = rating;
                  });
                },
              ),
              Text(
                ratingError,
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16.0),
              Text('Write your review:'),
              TextField(
                controller: reviewController,
                maxLines: 3,
                maxLength: 50, // Set maximum character limit
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  counterText: '${reviewController.text.length}/50', // Display character count
                ),
              ),
              Text(
                reviewError,
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              if (widget.activityID.isNotEmpty &&
                  recommendationDetails != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.0),
                    Text(
                      'This place was recommended to you based on ${recommendationDetails?.recommendationFactor}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                    Text('Rate the Recommendation:'),
                    RatingBar.builder(
                      initialRating: recommendationRating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 30.0,
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          recommendationRating = rating;
                        });
                      },
                    ),
                    Text(
                      recommendationRatingError,
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Text('Write your recommendation review:'),
                    TextField(
                      controller: recommendationReviewController,
                      maxLines: 3,
                      maxLength: 50, // Set maximum character limit
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        counterText:
                        '${recommendationReviewController.text.length}/50', // Display character count
                      ),
                    ),
                    Text(
                      recommendationReviewError,
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16.0),
              Text('Upload a Picture:'),
              GestureDetector(
                onTap: () {
                  _pickImage();
                },
                child: Container(
                  width: 100.0,
                  height: 100.0,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: imageFile != null
                      ? Image.file(
                    imageFile!,
                    fit: BoxFit.cover,
                  )
                      : Icon(Icons.camera_alt, color: Colors.grey),
                ),
              ),
              SizedBox(height: 16.0),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    validateAndSubmit();
                  },
                  child: Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (imageFile == null) {
      return null; // No image to upload
    }

    try {
      final String fileName = 'reviewImage/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
      final firebase_storage.Reference reference = firebase_storage.FirebaseStorage.instance.ref().child(fileName);
      final firebase_storage.UploadTask uploadTask = reference.putFile(imageFile!);

      final firebase_storage.TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }


  Future<void> validateAndSubmit() async {
    bool isValid = true;

    if (userRating == 0.0) {
      setState(() {
        ratingError = 'Please provide a rating.';
      });
      isValid = false;
    } else {
      setState(() {
        ratingError = '';
      });
    }

    if (reviewController.text.isEmpty) {
      setState(() {
        reviewError = 'Please provide a review.';
      });
      isValid = false;
    } else {
      setState(() {
        reviewError = '';
      });
    }

    if (widget.activityID.isNotEmpty &&
        recommendationDetails != null) {
      if (recommendationRating == 0.0) {
        setState(() {
          recommendationRatingError = 'Please provide a rating for the recommendation.';
        });
        isValid = false;
      } else {
        setState(() {
          recommendationRatingError = '';
        });
      }

      if (recommendationReviewController.text.isEmpty) {
        setState(() {
          recommendationReviewError = 'Please provide a review for the recommendation.';
        });
        isValid = false;
      } else {
        setState(() {
          recommendationReviewError = '';
        });
      }
    }
    // Upload image and get the download URL
    final imageUrl = await _uploadImage();

    // If all fields are valid, proceed with submission
    if (isValid) {
      updateActivityDetails(imageUrl);
      if (widget.activityID.isNotEmpty &&
          recommendationDetails != null) {
        updateRecommendationDetails();
      }
      Navigator.pop(context); // Navigate back to the previous page
    }
  }

  Future<POI> fetchPoiDetails() async {
    try {
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_based_on_id?query=${widget.poiID}'));

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

  Future<void> fetchRecommendationDetails() async {
    try {
      final recommendationSnapshot = await FirebaseFirestore.instance
          .collection('recommendation')
          .where('activityID', isEqualTo: widget.activityID)
          .get();

      if (recommendationSnapshot.docs.isNotEmpty) {
        final recommendationData = recommendationSnapshot.docs.first.data() as Map<String, dynamic>;

        recommendationDetails = Recommendation(
          recommendationID: recommendationSnapshot.docs.first.id,
          activityID: recommendationData['activityID'],
          recommendationDate: recommendationData['recommendationDate'],
          recommendationFactor: recommendationData['recommendationFactor'],
          recommendationReview: recommendationData['recommendationReview'] ?? '', // Assign empty string if null
          recommendationRating: recommendationData['recommendationRating'] != null
              ? double.tryParse(recommendationData['recommendationRating'].toString()) ?? 0.0
              : 0.0,
        );

        setState(() {
          recommendationRating = recommendationDetails?.recommendationRating ?? 0.0;
          recommendationReviewController.text = recommendationDetails?.recommendationReview ?? '';
        });

        print(recommendationDetails);
      }
    } catch (e) {
      print('Error fetching recommendation details: $e');
    }
  }


  void updateRecommendationDetails() {
    final recommendationData = {
      'recommendationRating': recommendationRating.toString(),
      'recommendationReview': recommendationReviewController.text,
    };

    FirebaseFirestore.instance
        .collection('recommendation')
        .doc(recommendationDetails?.recommendationID)
        .update(recommendationData)
        .then((_) {
      print('Recommendation details updated successfully');
    }).catchError((error) {
      print('Error updating recommendation details: $error');
    });
  }

  void updateActivityDetails(String? imageUrl) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final activityData = {
      'activityRating': userRating,
      'activityReview': reviewController.text.toString(),
      'activityRatingDate': formattedDate,
      'reviewPhoto': imageUrl,
    };

    FirebaseFirestore.instance
        .collection('activity')
        .doc(widget.activityID)
        .update(activityData)
        .then((_) {
      print('Activity details updated successfully');
    }).catchError((error) {
      print('Error updating activity details: $error');
    });
  }

}
