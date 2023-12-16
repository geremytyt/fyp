import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Widget/widgets.dart';

class AddPoi extends StatefulWidget {
  @override
  _AddPoiState createState() => _AddPoiState();
}

class _AddPoiState extends State<AddPoi> {
  late String poiType = "Hotel";
  late String poiName = "";
  late String poiAddress = "";
  late String poiLocation = "Kuala Lumpur";
  late String poiUrl = "";
  late double poiPrice = 0.0;
  late String poiPriceRange = "";
  late String poiPhone = "";
  late String poiTag = "";
  late String poiOperatingHours = "";
  late double poiRating = 0.0;
  late int poiNoOfReviews = 0;
  late String poiDescription = "";
  double poiLatitude = 0.0;
  double poiLongitude = 0.0;

  final List<String> poiTypes = ["Hotel", "Restaurant", "Attraction"];
  final TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Point of Interest'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: poiType,
                decoration: InputDecoration(labelText: 'Type'),
                items: poiTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    poiType = value!;
                  });
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == "") {
                    return 'POI Name is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    poiName = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value == "") {
                    return 'POI Address is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    poiAddress = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: poiLocation,
                decoration: InputDecoration(labelText: 'Location'),
                items: statesOfMalaysia.map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    poiLocation = value!;
                  });
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'URL'),
                onChanged: (value) {
                  setState(() {
                    poiUrl = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    poiPrice = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Tag'),
                validator: (value) {
                  if (value == "") {
                    return 'POI Tag is required';
                  }
                  return null;
                },
                onSaved: (value) {
                  poiTag = value!;
                },
                onChanged: (value) {
                  setState(() {
                    poiTag = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              if (poiType == "Attraction")
                TextFormField(
                  decoration: InputDecoration(labelText: 'Operating Hours'),
                  onChanged: (value) {
                    setState(() {
                      poiOperatingHours = value;
                    });
                  },
                ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Phone'),
                onChanged: (value) {
                  setState(() {
                    poiPhone = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  setState(() {
                    poiDescription = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    calculatePoiDetails();
                    savePoiDetails();
                  },
                  child: Text('Save Point of Interest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void calculatePoiDetails() {
    // Check if poiPrice is 0.0
    if (poiPrice == 0.0) {
      poiPriceRange = '-1';
      return;
    }

    // Calculate poiPriceRange based on poiType and poiPrice
    if (poiType == 'Restaurant') {
      if (poiPrice <= 20) {
        poiPriceRange = '\$';
      } else if (poiPrice <= 40) {
        poiPriceRange = '\$\$';
      } else if (poiPrice <= 100) {
        poiPriceRange = '\$\$ - \$\$\$';
      } else {
        poiPriceRange = '\$\$\$\$';
      }
    } else if (poiType == 'Hotel') {
      if (poiPrice <= 200) {
        poiPriceRange = '\$';
      } else if (poiPrice <= 300) {
        poiPriceRange = '\$\$';
      } else if (poiPrice <= 500) {
        poiPriceRange = '\$\$\$';
      } else {
        poiPriceRange = '\$\$\$\$';
      }
    } else {
      poiPriceRange = '-1'; // For attractions
    }
  }


  Future<void> getLatLngFromAddress(String address) async {
    final apiKey = 'AIzaSyDz9pepBSYg90CZXK1WZkucemlJxlSinuY'; // Replace with your actual API key
    final endpoint = 'https://maps.googleapis.com/maps/api/geocode/json';

    final response = await http.get(Uri.parse('$endpoint?address=$address&key=$apiKey'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK' && data['results'] is List && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        poiLatitude = location['lat'];
        poiLongitude = location['lng'];
      } else {
        print('Geocoding failed: ${data['status']}');
      }
    } else {
      print('Failed to fetch geocoding data: ${response.statusCode}');
    }
  }

  Future<String> fetchLastPoiID() async {
    try {
      final response = await http.get(
        Uri.parse('http://34.124.197.131:5000/get-last-poi-id'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['lastPoiID']?.toString() ?? '';
      } else {
        print('Failed to fetch last POI ID: ${response.statusCode}');
        return ''; // Return an empty string or handle the error accordingly
      }
    } catch (e) {
      print('Error fetching last POI ID: $e');
      return ''; // Return an empty string or handle the error accordingly
    }
  }

  Future<void> savePoiDetails() async {

    // Fetch the last poiID
    String lastPoiID = await fetchLastPoiID();

    if (lastPoiID.isNotEmpty) {
      print('The poi ID is: $lastPoiID');
      int lastId = int.parse(lastPoiID.substring(1).padLeft(6, '0'));
      String nextPoiID = 'P' + (lastId + 1).toString().padLeft(6, '0');

      // Calculate poiLatitude and poiLongitude
      await getLatLngFromAddress('$poiAddress, $poiLocation');

    try {
        final response = await http.post(
          Uri.parse('http://34.124.197.131:5000/save-poi-details'),
          body: {
            'poiID': nextPoiID,
            'poiType': poiType,
            'poiName': poiName,
            'poiAddress': poiAddress == "" ? '-1' : poiLocation,
            'poiLocation': poiLocation,
            'poiUrl': poiUrl == "" ? '-1' : poiUrl,
            'poiPrice': poiPrice.toString() ?? '-1',
            'poiPriceRange': poiPriceRange == "" ? '-1' : poiPriceRange.toString(),
            'poiPhone': poiPhone == "" ? '-1' : poiPhone,
            'poiTag': poiTag== "" ? '-1' : poiTag,
            'poiOperatingHours': poiOperatingHours == "" ? '-1' : poiOperatingHours,
            'poiRating': poiRating.toString() ?? '-1',
            'poiNoOfReviews': poiNoOfReviews.toString() ?? '-1',
            'poiDescription': poiDescription == "" ? '-1' : poiDescription,
            'poiLatitude': poiLatitude.toString() ?? '-1',
            'poiLongitude': poiLongitude.toString() ?? '-1',
          },
        );

        if (response.statusCode == 200) {
          print('POI details saved successfully');
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          print('Failed to save POI details: ${response.statusCode}');
        }
      } catch (e) {
        print('Error saving POI details: $e');
      }

    } else {
      print('Invalid poi ID: $lastPoiID');
    }

  }
}
