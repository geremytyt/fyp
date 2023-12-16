import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class ViewBookingDetailsPage extends StatelessWidget {
  final String bookingID;
  final String poiID;

  ViewBookingDetailsPage({required this.bookingID, required this.poiID});

  Future<Map<String, dynamic>> fetchBookingDetails(String bookingID) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> bookingSnapshot =
      await FirebaseFirestore.instance.collection('booking').doc(bookingID).get();

      if (bookingSnapshot.exists) {
        return bookingSnapshot.data() ?? {};
      } else {
        print('Booking document does not exist for ID: $bookingID');
        return {};
      }
    } catch (e) {
      print('Error fetching booking details: $e');
      return {};
    }
  }

  Future<POI> fetchPoiDetails(String poiID) async {
    try {
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_based_on_id?query=$poiID'));

      if (response.statusCode == 200) {
        // Parse the response body
        List<dynamic> responseDataList = json.decode(response.body);

        if (responseDataList.isNotEmpty) {
          // Extract the first element from the list
          dynamic responseData = responseDataList[0];

          if (responseData is Map<String, dynamic>) {
            // If the response is a map, create a POI instance
            return POI(
              poiID: responseData['poiID']?.toString() ?? '',
              poiName: responseData['poiName']?.toString() ?? '',
              poiAddress: responseData['poiAddress']?.toString() ?? '',
              poiLocation: responseData['poiLocation']?.toString() ?? '',
              poiPrice: responseData['poiPrice']?.toString() ?? '',
              poiRating: responseData['poiRating']?.toString() ?? '',
              poiTag: responseData['poiTag']?.toString() ?? '',
              poiNoOfReviews: responseData['poiNoOfReviews']?.toString() ?? '',
              poiType: responseData['poiType']?.toString() ?? '',
              poiUrl: responseData['poiUrl']?.toString() ?? '',
              poiPhone: responseData['poiPhone']?.toString() ?? '',
              poiOperatingHours: responseData['poiOperatingHours']?.toString() ?? '',
              poiDescription: responseData['poiDescription']?.toString() ?? '',
              poiPriceRange: responseData['poiPriceRange']?.toString() ?? '',
              poiLatitude: responseData['poiLatitude']?.toDouble() ?? 0.0,
              poiLongitude: responseData['poiLongitude']?.toDouble() ?? 0.0,
            );
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
        print('Failed to fetch POI data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Handle any exceptions that might occur during the process
      print('Error fetching POI data: $e');
    }

    // Return an empty POI instance if there's an error
    return POI(
      poiID: '',
      poiType: '',
      poiName: '',
      poiAddress: '',
      poiLocation: '',
      poiPrice: '',
      poiRating: '',
      poiTag: '',
      poiNoOfReviews: '',
      poiUrl: '',
      poiPhone: '',
      poiOperatingHours: '',
      poiDescription: '',
      poiPriceRange: '',
      poiLatitude: 0.0,
      poiLongitude: 0.0,
    );
  }

  Future<Map<String, dynamic>> fetchPaymentDetails(String bookingID) async {
    try {
      QuerySnapshot<Map<String, dynamic>> paymentSnapshot = await FirebaseFirestore
          .instance
          .collection('payment')
          .where('bookingID', isEqualTo: bookingID)
          .get();

      if (paymentSnapshot.docs.isNotEmpty) {
        return paymentSnapshot.docs.first.data() ?? {};
      } else {
        print('Payment document does not exist for Booking ID: $bookingID');
        return {};
      }
    } catch (e) {
      print('Error fetching payment details: $e');
      return {};
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: fetchBookingDetails(bookingID),
          builder: (context, bookingSnapshot) {
            if (bookingSnapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (bookingSnapshot.hasError) {
              return Text('Error fetching booking details: ${bookingSnapshot.error}');
            } else {
              final bookingDetails = bookingSnapshot.data ?? {};

              return FutureBuilder<POI>(
                future: fetchPoiDetails(poiID),
                builder: (context, poiSnapshot) {
                  if (poiSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (poiSnapshot.hasError) {
                    return Text('Error fetching POI details: ${poiSnapshot.error}');
                  } else {
                    POI poiDetails = poiSnapshot.data as POI;

                    return FutureBuilder<Map<String, dynamic>>(
                      future: fetchPaymentDetails(bookingDetails['bookingID']),
                      builder: (context, paymentSnapshot) {
                        if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (paymentSnapshot.hasError) {
                          return Text('Error fetching payment details: ${paymentSnapshot.error}');
                        } else {
                          final paymentDetails = paymentSnapshot.data ?? {};

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewPoiDetailsPage(poiID: poiDetails.poiID),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('POI Details', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                                        Text(poiDetails.poiName),
                                        if (poiDetails.poiAddress != '-1')
                                          Text(poiDetails.poiAddress),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 16.0),

                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Booking Details', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                                      Text('Booking ID: ${bookingDetails['bookingID']}'),
                                      Text('Ticket ID: ${bookingDetails['ticketID']}'),
                                      Text('Booking Date: ${bookingDetails['bookingDate']}'),
                                      Text('Adult Ticket Quantity: ${bookingDetails['bookingAdultQty']}'),
                                      Text('Child Ticket Quantity: ${bookingDetails['bookingChildQty']}'),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: 16.0),

                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Payment Details', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
                                      Text('Payment ID: ${paymentDetails['paymentID']}'),
                                      Text('Payment Date: ${paymentDetails['paymentDateTime']}'),
                                      Text('Payment Amount: ${paymentDetails['paymentAmount']}'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }

}
