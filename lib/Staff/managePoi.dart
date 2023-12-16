import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_travel_mate/Staff/staffViewPoiDetails.dart';

import 'addPoi.dart';

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

class ManagePoi extends StatefulWidget {
  @override
  _ManagePoiState createState() => _ManagePoiState();
}

class _ManagePoiState extends State<ManagePoi> {
  final List<POI> allPOIs = [];
  List<POI> filteredPOIs = [];
  String errorMessage = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    Navigator.popUntil(context, (route) => route.isFirst);
    fetchPointsOfInterest();
  }

  // Future<void> fetchPointsOfInterest() async {
  //   try {
  //     // Fetch JSON data from the Flask API
  //     final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_df'));
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> dataList = json.decode(response.body);
  //
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

  // Future<void> searchPointsOfInterest(String query) async {
  //   try {
  //     // Fetch JSON data from the Flask API based on the search query
  //     final response = await http.get(Uri.parse('http://34.124.197.131:5000/search_poi?query=$query'));
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> dataList = json.decode(response.body);
  //
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage POI'),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: Column(
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
                return GestureDetector(
                  onTap: () {
                    // Navigate to StaffViewPoiDetails with the selected poiID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StaffViewPoiDetailsPage(poiID: poi.poiID),
                      ),
                    );
                  },
                  child: ListTile(
                    title: Text(poi.poiName),
                    subtitle: Text(poi.poiID),
                  ),
                );
              },
            ),

          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPoi(),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
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
    poi.poiID.toLowerCase().contains(query.toLowerCase()) ||
        poi.poiTag.toLowerCase().contains(query.toLowerCase()) ||
    poi.poiName.toLowerCase().contains(query.toLowerCase()) ||
        poi.poiType.toLowerCase().contains(query.toLowerCase()))
        .toList();
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
          )));
        });

        // Update the UI
        setState(() {});
      } else {
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }
}
