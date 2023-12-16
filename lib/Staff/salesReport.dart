

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

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

class SalesReportPage extends StatefulWidget {
  @override
  _SalesReportPageState createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  late CollectionReference<Map<String, dynamic>> _bookingsCollection;
  late CollectionReference<Map<String, dynamic>> _tripCollection;

  @override
  void initState() {
    super.initState();
    _bookingsCollection = FirebaseFirestore.instance.collection('booking');
    _tripCollection = FirebaseFirestore.instance.collection('trip');
  }

  Future<List<Map<String, dynamic>>> _getBookingDetails() async {
    final bookingsSnapshot = await _bookingsCollection.get();
    final bookingsData = bookingsSnapshot.docs.map((doc) => doc.data()).toList();

    final bookingDetails = <Map<String, dynamic>>[];

    for (final booking in bookingsData) {
      final ticketId = booking['ticketID'] as String;
      final adultQty = booking['bookingAdultQty'] as int;
      final childQty = booking['bookingChildQty'] as int;

      final tripSnapshot = await _tripCollection.where('ticketID', isEqualTo: ticketId).get();
      final tripData = tripSnapshot.docs.map((doc) => doc.data()).toList();

      if (tripData.isNotEmpty) {
        final poiId = tripData[0]['poiID'] as String;

        final poiDetail = await searchPointsOfInterestById(poiId);
        final poiTag = poiDetail.poiTag;

        print('BookingID: ${booking['bookingID']}, PoiID: $poiId, PoiTag: $poiTag');

        bookingDetails.add({
          'poiTag': poiTag,
          'totalTickets': adultQty + childQty,
        });
      }
    }

    return bookingDetails;
  }


  Future<List<POI>> _getPoiDetails(List<String> poiIds) async {
    final List<POI> poiDetails = [];

    for (final poiId in poiIds) {
      final poiDetail = await searchPointsOfInterestById(poiId);
      poiDetails.add(poiDetail);
    }

    return poiDetails;
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

  Future<List<String>> _getPoiIds(List<String> ticketIds) async {
    final poiIds = <String>[];

    for (final ticketId in ticketIds) {
      final tripSnapshot = await _tripCollection.where('ticketID', isEqualTo: ticketId).get();
      final tripData = tripSnapshot.docs.map((doc) => doc['poiID'] as String).toList();
      poiIds.addAll(tripData);
    }

    return poiIds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Report'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getBookingDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          final bookingDetails = snapshot.data ?? [];

          // Process bookingDetails to get total tickets for each poiTag

          final totalTicketsByPoiTag = <String, int>{};

          for (final detail in bookingDetails) {
            final poiTag = detail['poiTag'] as String;
            final totalTickets = detail['totalTickets'] as int;

            // Check if poiTag has multiple categories
            final poiTags = poiTag.split(', ');

            for (final individualTag in poiTags) {
              totalTicketsByPoiTag[individualTag] =
                  (totalTicketsByPoiTag[individualTag] ?? 0) + totalTickets;
            }
          }

          // Now totalTicketsByPoiTag contains the total tickets for each poiTag

          return DataTable(
            columns: [
              DataColumn(
                label: Text(
                  'POI Tag',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DataColumn(
                label: Text(
                  'Total Tickets',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            rows: totalTicketsByPoiTag.entries.map((entry) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      entry.key,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Text(
                      entry.value.toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
