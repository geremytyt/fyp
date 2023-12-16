import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_travel_mate/Staff/staffViewPoiDetails.dart';
import 'package:my_travel_mate/Widget/widgets.dart';

class EditPoi extends StatefulWidget {
  final String poiID;

  EditPoi({required this.poiID});

  @override
  _EditPoiState createState() => _EditPoiState();
}

class _EditPoiState extends State<EditPoi> {
  String poiRating = '';
  String poiNoOfReviews = '';
  double poiLatitude = 0.0;
  double poiLongitude = 0.0;
  String poiPriceRange='';

  TextEditingController poiNameController = TextEditingController();
  TextEditingController poiAddressController = TextEditingController();
  TextEditingController poiLocationController = TextEditingController();
  TextEditingController poiPriceController = TextEditingController();
  TextEditingController poiTagController = TextEditingController();
  TextEditingController poiTypeController = TextEditingController();
  TextEditingController poiUrlController = TextEditingController();
  TextEditingController poiPhoneController = TextEditingController();
  TextEditingController poiOperatingHoursController = TextEditingController();
  TextEditingController poiDescriptionController = TextEditingController();

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
              poiRating = responseData['poiRating']?.toString() ?? '';
              poiNoOfReviews = responseData['poiNoOfReviews']?.toString() ?? '';
              poiPriceRange = responseData['poiPriceRange']?.toString() ?? '';
              poiLatitude = responseData['poiLatitude']?.toDouble() ?? 0.0;
              poiLongitude = responseData['poiLongitude']?.toDouble() ?? 0.0;
              poiNameController.text = responseData['poiName']?.toString() ?? '';
              poiAddressController.text = responseData['poiAddress'] == -1 ? '' : responseData['poiAddress']?.toString() ?? '';
              poiLocationController.text = responseData['poiLocation']?.toString() ?? '';
              poiPriceController.text = responseData['poiPrice']?.toString() ?? '';
              poiTagController.text = responseData['poiTag']?.toString() ?? '';
              poiTypeController.text = responseData['poiType']?.toString() ?? '';
              poiUrlController.text = responseData['poiUrl'] == -1 ? '' : responseData['poiUrl']?.toString() ?? '';
              poiPhoneController.text = responseData['poiPhone'] == -1 ? '' : responseData['poiPhone']?.toString() ?? '';
              poiOperatingHoursController.text = responseData['poiOperatingHours'] == -1 ? '' : responseData['poiOperatingHours']?.toString() ?? '';
              poiDescriptionController.text = responseData['poiDescription'] == -1 ? '' : responseData['poiDescription']?.toString() ?? '';
            });

            if(poiTypeController.text=='-1'){
              poiTypeController.text='Hotel';
            }

            if(poiLocationController.text=='-1'){
              poiLocationController.text='Kuala Lumpur';
            }


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit POI'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: poiTypeController.text,
              decoration: InputDecoration(labelText: 'Type'),
              items: ['Hotel', 'Restaurant', 'Attraction']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  poiTypeController.text = newValue ?? '';
                });
              },
            ),
            TextField(
              controller: poiNameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: poiAddressController,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            // Dropdown for Location
            DropdownButtonFormField<String>(
              value: poiLocationController.text,
              decoration: InputDecoration(labelText: 'Location'),
              items: statesOfMalaysia.map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  poiLocationController.text = newValue ?? '';
                });
              },
            ),
            TextField(
              controller: poiPriceController,
              decoration: InputDecoration(labelText: 'Price'),
            ),
            TextField(
              controller: poiTagController,
              decoration: InputDecoration(labelText: 'Tag'),
            ),
            TextField(
              controller: poiUrlController,
              decoration: InputDecoration(labelText: 'URL'),
            ),
            TextField(
              controller: poiPhoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: poiOperatingHoursController,
              decoration: InputDecoration(labelText: 'Operating Hours'),
            ),
            TextField(
              controller: poiDescriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                calculatePoiDetails();
                savePoiDetails();
              },
              child: Text('Save'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                showDeleteConfirmationDialog();
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
              ),
              child: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this POI?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deletePoi();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deletePoi() async {
    try {
      final response = await http.post(
        Uri.parse('http://34.124.197.131:5000/delete-poi'),
        body: {'poiID': widget.poiID},
      );

      if (response.statusCode == 200) {
        showToast('POI deleted successfully');
        Navigator.pop(context);
      } else {
        showToast('Failed to delete POI: ${response.statusCode}');
      }
    } catch (e) {
      showToast('Error deleting POI: $e');
    }
  }

  void calculatePoiDetails() {
    // Get the current value of poiPriceController
    double currentPoiPrice = double.tryParse(poiPriceController.text) ?? 0.0;

    // Check if poiPrice is 0.0
    if (currentPoiPrice == 0.0) {
      poiPriceRange = '-1';
      return;
    }

    // Calculate poiPriceRange based on poiType and currentPoiPrice
    if (poiTypeController.text == 'Restaurant') {
      if (currentPoiPrice <= 20) {
        poiPriceRange = '\$';
      } else if (currentPoiPrice <= 40) {
        poiPriceRange = '\$\$';
      } else if (currentPoiPrice <= 100) {
        poiPriceRange = '\$\$ - \$\$\$';
      } else {
        poiPriceRange = '\$\$\$\$';
      }
    } else if (poiTypeController.text == 'Hotel') {
      if (currentPoiPrice <= 200) {
        poiPriceRange = '\$';
      } else if (currentPoiPrice <= 300) {
        poiPriceRange = '\$\$';
      } else if (currentPoiPrice <= 500) {
        poiPriceRange = '\$\$\$';
      } else {
        poiPriceRange = '\$\$\$\$';
      }
    } else {
      poiPriceRange = '-1'; // For attractions
    }
  }


  // Future<void> getLatLngFromAddress(String address) async {
  //   final apiKey = 'AIzaSyDz9pepBSYg90CZXK1WZkucemlJxlSinuY';
  //   final endpoint = 'https://maps.googleapis.com/maps/api/geocode/json';
  //
  //   final response = await http.get(Uri.parse('$endpoint?address=$address&key=$apiKey'));
  //
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     if (data['status'] == 'OK' && data['results'] is List && data['results'].isNotEmpty) {
  //       final location = data['results'][0]['geometry']['location'];
  //       poiLatitude = location['lat'];
  //       poiLongitude = location['lng'];
  //     } else {
  //       print('Geocoding failed: ${data['status']}');
  //     }
  //   } else {
  //     print('Failed to fetch geocoding data: ${response.statusCode}');
  //   }
  // }

  Future<void> savePoiDetails() async {
    // // Calculate poiLatitude and poiLongitude
    // await getLatLngFromAddress('$poiAddressController, $poiLocationController');

    // Null check for required fields
    if (poiNameController.text == "" || poiAddressController.text == "" || poiTagController.text == "") {
      showToast('Please fill in all required fields');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://34.124.197.131:5000/edit-poi-details'),
        body: {
          'poiID': widget.poiID,
          'poiType': poiTypeController.text,
          'poiName': poiNameController.text,
          'poiAddress': poiAddressController.text,
          'poiLocation': poiLocationController.text,
          'poiUrl': poiUrlController.text == "" ? '-1' : poiUrlController.text,
          'poiPrice': poiPriceController.text ?? '-1',
          'poiPriceRange': poiPriceRange == "" ? '-1' : poiPriceRange.toString(),
          'poiPhone': poiPhoneController.text == "" ? '-1' : poiPhoneController.text,
          'poiTag': poiTagController.text,
          'poiOperatingHours': poiOperatingHoursController.text == "" ? '-1' : poiOperatingHoursController.text,
          'poiRating': poiRating,
          'poiNoOfReviews': poiNoOfReviews,
          'poiDescription': poiDescriptionController.text == "" ? '-1' : poiDescriptionController.text,
          'poiLatitude': poiLatitude.toString() ?? '-1',
          'poiLongitude': poiLongitude.toString() ?? '-1',
        },
      );

      if (response.statusCode == 200) {
        print('POI details saved successfully');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffViewPoiDetailsPage(poiID: widget.poiID),
          ),
        );
      } else {
        print('Failed to save POI details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving POI details: $e');
    }

  }
}
