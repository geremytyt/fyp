import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../POI/viewPoiDetails.dart';

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

class ViewStatePoi extends StatefulWidget {
  final String stateName;

  ViewStatePoi({required this.stateName});

  @override
  _ViewStatePoiState createState() => _ViewStatePoiState();
}

class _ViewStatePoiState extends State<ViewStatePoi> {
  List<POI> allPOIs = [];
  List<POI> restaurantList = [];
  List<POI> hotelList = [];
  List<POI> attractionList = [];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await fetchPointsOfInterest();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('POIs in ${widget.stateName}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCategoryList('Restaurants', restaurantList),
            buildCategoryList('Hotels', hotelList),
            buildCategoryList('Attractions', attractionList),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryList(String categoryName, List<POI> poiList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            categoryName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: poiList.length,
            itemBuilder: (context, index) {
              return buildPoiCard(poiList[index]);
            },
          ),
        ),
      ],
    );
  }

  Future<void> filterPOIs() async {
    // Filter POIs based on the selected state name
    restaurantList = allPOIs
        .where((poi) =>
    poi.poiType == 'Restaurant' &&
        (poi.poiLocation?.toLowerCase() == widget.stateName.toLowerCase() ||
            poi.poiAddress?.toLowerCase()?.contains(widget.stateName.toLowerCase()) ==
                true))
        .take(6)
        .toList();

    hotelList = allPOIs
        .where((poi) =>
    poi.poiType == 'Hotel' &&
        (poi.poiLocation?.toLowerCase() == widget.stateName.toLowerCase() ||
            poi.poiAddress?.toLowerCase()?.contains(widget.stateName.toLowerCase()) ==
                true))
        .take(6)
        .toList();

    attractionList = allPOIs
        .where((poi) =>
    poi.poiType == 'Attraction' &&
        (poi.poiLocation?.toLowerCase() == widget.stateName.toLowerCase() ||
            poi.poiAddress?.toLowerCase()?.contains(widget.stateName.toLowerCase()) ==
                true))
        .take(6)
        .toList();

    // Fetch images for hotels and attractions only once
    for (final poiDetails in hotelList) {
      fetchImageForPOI(poiDetails);
    }
    for (final poiDetails in attractionList) {
      fetchImageForPOI(poiDetails);
    }
    // Fetch images for all restaurantList
    for (final poiDetails in restaurantList) {
      fetchImageForPOI(poiDetails);
    }

    // Update the UI
    setState(() {});
  }

  Future<void> fetchPointsOfInterest() async {
    try {
      // Fetch JSON data from the Flask API
      final response =
      await http.get(Uri.parse('http://34.124.197.131:5000/get_all_poi_df'));

      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);
        allPOIs.clear();
        restaurantList.clear();
        attractionList.clear();
        hotelList.clear();
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

        allPOIs.sort((a, b) => b.poiRating.compareTo(a.poiRating));

        // Create separate lists for each poiType
        hotelList = allPOIs.where((poi) => poi.poiType == 'Hotel').toList();
        restaurantList =
            allPOIs.where((poi) => poi.poiType == 'Restaurant').toList();
        attractionList =
            allPOIs.where((poi) => poi.poiType == 'Attraction').toList();

        // Update the UI
        setState(() {});
      } else {
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
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
                    fontSize: 14,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchImageForPOI(POI poiDetails) async {
    const apiKey = 'AIzaSyDz9pepBSYg90CZXK1WZkucemlJxlSinuY';
    final placeName = poiDetails.poiName;

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

          if (photoReference != null && photoReference.isNotEmpty) {
            final imageUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';

            setState(() {
              poiDetails.imageUrl = imageUrl;
            });
          }
        }
      }
    }
  }
}
