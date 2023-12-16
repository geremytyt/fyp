import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:my_travel_mate/Widget/viewMap.dart';

import '../Widget/widgets.dart';
import 'editPoi.dart';
import 'managePoi.dart';
import 'manageTicket.dart';

class StaffViewPoiDetailsPage extends StatefulWidget {
  final String poiID;

  StaffViewPoiDetailsPage({required this.poiID});

  @override
  _StaffViewPoiDetailsPageState createState() => _StaffViewPoiDetailsPageState();
}

class _StaffViewPoiDetailsPageState extends State<StaffViewPoiDetailsPage> {
  late GoogleMapController mapController;
  String poiID="";
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
  String poiPhone='';
  String poiOperatingHours = '';
  String poiDescription='';
  String poiPriceRange='';

  @override
  void initState() {
    super.initState();
    fetchDataFromDatabase();
  }

  Future<void> fetchDataFromDatabase() async {
    try {
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_based_on_id?query=${widget.poiID}'));

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
              poiLocation =responseData['poiLocation']?.toString() ?? '';
              poiPrice = responseData['poiPrice']?.toString() ?? '';
              poiRating = responseData['poiRating']?.toString() ?? '';
              poiTag = responseData['poiTag']?.toString() ?? '';
              poiNoOfReviews = responseData['poiNoOfReviews']?.toString() ?? '';
              poiType = responseData['poiType']?.toString() ?? '';
              poiUrl = responseData['poiUrl']?.toString() ?? '';
              poiPhone = responseData['poiPhone']?.toString() ?? '';
              poiOperatingHours = responseData['poiOperatingHours']?.toString() ?? '';
              poiDescription = responseData['poiDescription']?.toString() ?? '';
              poiPriceRange = responseData['poiPriceRange']?.toString() ?? '';
              poiLatitude = responseData['poiLatitude']?.toDouble() ?? 0.0;
              poiLongitude = responseData['poiLongitude']?.toDouble() ?? 0.0;
            });

            fetchImageFromGooglePlaces(poiName);
          } else {
            // Handle the case where the first element is not a map, if needed
            print('Unexpected response format. First element is not a map: $responseData');
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Details'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManagePoi(),
              ),
            );
          },
        ),
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
                      Text('Operating Hours: $poiOperatingHours',
                          style: TextStyle(fontSize: 16)),
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
            child: Icon(Icons.edit),
            backgroundColor: Colors.blue,
            label: 'Edit',
            labelStyle: TextStyle(fontSize: 14),
            onTap: () {
              // Navigate to the EditPoi page and pass the poiID
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPoi(poiID: poiID),
                ),
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.local_attraction),
            backgroundColor: Colors.blue,
            label: 'Ticket',
            labelStyle: TextStyle(fontSize: 14),
            onTap: () {
              if (poiType == "Attraction") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageTicket(poiID: poiID),
                  ),
                );
              } else {
                showToast("Tickets not available for this POI type");
              }
            },
          ),
        ],
      ),
    );
  }

}

