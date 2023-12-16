import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Widget/widgets.dart';
import 'addCard.dart';
import 'bookingConfirmation.dart';


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

class BookingSummaryPage extends StatefulWidget {
  final String ticketID;
  final int adultQuantity;
  final int childQuantity;
  final double adultTicketPrice;
  final double childTicketPrice;
  final String ticketDate;

  BookingSummaryPage({
    required this.ticketID,
    required this.adultQuantity,
    required this.childQuantity,
    required this.adultTicketPrice,
    required this.childTicketPrice,
    required this.ticketDate,
  });

  @override
  _BookingSummaryPageState createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  String userId = '';
  String userName='';
  String userEmail='';
  String selectedCard = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Summary'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: FutureBuilder(
        future: fetchTicketDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !(snapshot.data is POI)) {
            return Center(child: Text('Invalid or null data format.'));
          }

          POI poiDetails = snapshot.data as POI;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.0),
                Container(
                  padding: EdgeInsets.all(16.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Details',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        '${poiDetails.poiName}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        '${widget.ticketDate}',
                        style: TextStyle(fontSize: 16.0),
                      ),
                      if (widget.adultQuantity > 0) Text('Adult Ticket x ${widget.adultQuantity}'),
                      if (widget.childQuantity > 0) Text('Child Ticket x ${widget.childQuantity}'),
                      SizedBox(height: 8.0),
                      Text(
                        'RM${_calculateTotalPrice(widget.adultQuantity, widget.childQuantity, widget.adultTicketPrice, widget.childTicketPrice).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.0),
                Container(
                  padding: EdgeInsets.all(16.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      _buildRegisteredCardTile(context, _reloadPage),
                      SizedBox(height: 16.0),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedCard == '') {
                              showToast('Please select a card');
                              return;
                            } else {
                              handlePaymentButtonClick(context, poiDetails);
                            }
                          },
                          child: Text('Pay Now'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  Future<POI> fetchTicketDetails() async {
    try {
      DocumentSnapshot ticketSnapshot = await FirebaseFirestore.instance.collection('ticket').doc(widget.ticketID).get();

      if (ticketSnapshot.exists) {
        String poiID = ticketSnapshot['poiID'];

        // Fetch POI details based on poiID
        POI poiDetails = await fetchPoiDetails(poiID);

        return poiDetails;
      } else {
        // Handle the case where the ticket document does not exist
        print('Ticket document does not exist for ID: ${widget.ticketID}');
        return POI(poiID: '',
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
          poiLongitude: 0.0,);
      }
    } catch (e) {
      // Handle any errors that might occur during the process
      print('Error fetching ticket details: $e');
      return POI(poiID: '',
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
        poiLongitude: 0.0,);
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

  double _calculateTotalPrice(int adultQuantity, int childQuantity, double adultTicketPrice, double childTicketPrice) {
    return (adultQuantity * adultTicketPrice) + (childQuantity * childTicketPrice);
  }

  // Widget _buildRegisteredCardTile(BuildContext context) {
  //   return FutureBuilder<List<String>>(
  //     future: fetchRegisteredCards(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return CircularProgressIndicator();
  //       } else if (snapshot.hasError) {
  //         // Handle error state
  //         return Text('Error: ${snapshot.error}');
  //       } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
  //         // Handle case where no registered cards are available
  //         return Column(
  //           children: [
  //             Text('No registered cards'),
  //             ElevatedButton.icon(
  //               onPressed: () async {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => AddCardPage(),
  //
  //                   ),
  //                 );
  //               },
  //               icon: Icon(Icons.add),
  //               label: Text('Add Card'),
  //             ),
  //           ],
  //         );
  //       }
  //
  //       // Use the first card as the default card
  //       String defaultCardNo = snapshot.data![0];
  //
  //       return ListTile(
  //         title: Text('Credit Card'),
  //         subtitle: Row(
  //           children: [
  //             Expanded(
  //               child: Text(selectedCard.isNotEmpty ? selectedCard : defaultCardNo),
  //             ),
  //             IconButton(
  //               icon: Icon(Icons.add),
  //               onPressed: () {
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (context) => AddCardPage(),
  //                   ),
  //                 );
  //               },
  //             ),
  //           ],
  //         ),
  //         onTap: () {
  //           // Display a dialog with the list of registered cards
  //           _showRegisteredCardsDialog(context);
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _buildRegisteredCardTile(BuildContext context, VoidCallback onCardSaved) {
    return FutureBuilder<List<String>>(
      future: fetchRegisteredCards(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Handle error state
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Handle case where no registered cards are available
          return Column(
            children: [
              Text('No registered cards'),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCardPage(onCardSaved: onCardSaved),
                    ),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('Add Card'),
              ),
            ],
          );
        }

        // Use the first card as the default card
        String defaultCardNo = snapshot.data![0];

        return ListTile(
          title: Text('Credit Card'),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(selectedCard.isNotEmpty ? selectedCard : defaultCardNo),
              ),
              IconButton(
                icon: Icon(Icons.credit_card),
                onPressed: () async {
                  // Show the list of registered cards
                  await _showRegisteredCardsDialog(context);
                },
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCardPage(onCardSaved: onCardSaved),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  if (selectedCard.isNotEmpty) {
                    _showDeleteCardConfirmationDialog(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteCardConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Card'),
          content: Text('Are you sure you want to delete the selected card?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await deleteCard(selectedCard);
                Navigator.pop(context);
                _reloadPage();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRegisteredCardsDialog(BuildContext context) async {
    // Fetch registered cards
    List<String> registeredCards = await fetchRegisteredCards();

    // Create a Completer to resolve when the dialog is dismissed
    Completer<void> completer = Completer<void>();

    // Show a dialog with the list of registered cards
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Registered Cards'),
          content: Column(
            children: [
              // Display each registered card
              for (String cardNo in registeredCards)
                ListTile(
                  title: Text(cardNo),
                  onTap: () {
                    // Update the selected card when a card is tapped
                    setState(() {
                      selectedCard = cardNo;
                    });
                    // Close the dialog
                    Navigator.pop(context);
                    // Resolve the completer
                    completer.complete();
                  },
                ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Resolve the completer when the dialog is closed
                  completer.complete();
                },
                child: Text('Close'),
              ),
            ),
          ],
        );
      },
    );

    // Wait for the dialog to be dismissed
    await completer.future;
  }



  Future<void> fetchUserDataFromFirestore(String email) async {
    try {
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('user');

      // Fetch the user data using the user's email
      QuerySnapshot querySnapshot = await usersCollection.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;

        // Convert the data to a Map<String, dynamic>
        Map<String, dynamic> userData = documentSnapshot.data() as Map<String, dynamic>;


        userId = userData['userID']?.toString() ?? '';
        userEmail= email;
        userName=userData['name']?.toString() ?? '';

      } else {
        print('User not found.');
      }
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
    }
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email') ?? '';

    print('${email}is found');
    if (email.isNotEmpty) {
      await fetchUserDataFromFirestore(email);
      print('User ID: $userId');
    }
  }

  Future<List<String>> fetchRegisteredCards() async {
    await loadUserData();
    try {
      // Fetch the user's registered cards based on the current user ID
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await FirebaseFirestore.instance.collection('card').where('userID', isEqualTo: userId).get();

      List<String> registeredCards = [];

      for (QueryDocumentSnapshot<Map<String, dynamic>> doc in querySnapshot.docs) {
        // Get the cardNo from each document and add it to the list
        String cardNo = doc['cardNo'] ?? '';
        if (cardNo.isNotEmpty) {
          registeredCards.add(cardNo);
        }
      }

      return registeredCards;
    } catch (e) {
      print('Error fetching registered cards: $e');
      return [];
    }
  }


  Future<void> deleteCard(String cardNo) async {
    try {
      // Delete the card based on cardNo and userID
      await FirebaseFirestore.instance
          .collection('card')
          .where('cardNo', isEqualTo: cardNo)
          .where('userID', isEqualTo: userId)
          .get()
          .then((QuerySnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.docs.isNotEmpty) {
          // If a document is found, delete it
          snapshot.docs.first.reference.delete();
          showToast('Card deleted successfully.');
        } else {
          // If no document is found, display an error message
          showToast('Card not found or you do not have permission to delete.');
        }
      });
    } catch (e) {
      print('Error deleting card: $e');
      showToast('Error deleting card. Please try again.');
    }
  }


  void handlePaymentButtonClick(BuildContext context, POI poiDetails) async {
    // Calculate total price
    double totalPrice = _calculateTotalPrice(
      widget.adultQuantity,
      widget.childQuantity,
      widget.adultTicketPrice,
      widget.childTicketPrice,
    );

    // Fetch card details
    Map<String, dynamic> cardDetails = await fetchCardDetails(selectedCard);

    // Validate if credit card details are valid
    if (isCardExpired(cardDetails['expiryDate'])) {
      showToast('Card has expired, please choose another card');
      return;
    }else
      {
        // Generate a booking ID
        String bookingID = await generateBookingID();

        // Add booking information to Firestore
        await addBookingToFirestore(bookingID);

        // Generate a payment ID
        String paymentID = await generatePaymentID();

        // Add payment information to Firestore
        await addPaymentToFirestore(paymentID, bookingID, totalPrice);

        await updateTicketQuantitiesInFirestore(
            widget.ticketID, widget.adultQuantity, widget.childQuantity);

        // Navigate to BookingConfirmation page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmation(
              poiName: poiDetails.poiName,
              poiID: poiDetails.poiID,
              ticketID: widget.ticketID,
              ticketDate: widget.ticketDate,
              adultTicketQty: widget.adultQuantity,
              childTicketQty: widget.childQuantity,
              totalPrice: totalPrice,
              cardNo: selectedCard,
              bookingID: bookingID,
              paymentID: paymentID,
            ),
          ),
        );
      }
  }

  Future<String> generatePaymentID() async {
    try {
      // Fetch the current payment count from Firestore
      QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection('payment').get();

      int paymentCount = snapshot.size + 1;

      // Format the payment ID with leading zeros
      String paymentID = 'PT' + paymentCount.toString().padLeft(5, '0');

      return paymentID;
    } catch (e) {
      print('Error generating payment ID: $e');
      throw Exception('Error generating payment ID');
    }
  }

  Future<void> updateTicketQuantitiesInFirestore(
      String ticketID, int adultQuantity, int childQuantity) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> ticketSnapshot =
      await FirebaseFirestore.instance.collection('ticket').doc(ticketID).get();

      if (ticketSnapshot.exists) {
        int currentAdultQuantity = ticketSnapshot['adultTicketQty'] ?? 0;
        int currentChildQuantity = ticketSnapshot['childTicketQty'] ?? 0;

        // Calculate the updated quantities
        int updatedAdultQuantity = currentAdultQuantity - adultQuantity;
        int updatedChildQuantity = currentChildQuantity - childQuantity;

        // Update the ticket quantities in Firestore
        await FirebaseFirestore.instance.collection('ticket').doc(ticketID).update({
          'adultTicketQty': updatedAdultQuantity,
          'childTicketQty': updatedChildQuantity,
        });

        print('Ticket quantities updated in Firestore successfully.');
      } else {
        print('Ticket document does not exist for ID: $ticketID');
      }
    } catch (e) {
      print('Error updating ticket quantities in Firestore: $e');
      throw Exception('Error updating ticket quantities in Firestore');
    }
  }

  Future<void> addPaymentToFirestore(
      String paymentID, String bookingID, double totalPrice) async {
    try {
      // Get the current date and time
      DateTime paymentDateTime = DateTime.now();

      // Add payment information to Firestore
      await FirebaseFirestore.instance.collection('payment').doc(paymentID).set({
        'paymentID': paymentID,
        'bookingID': bookingID,
        'paymentDateTime': paymentDateTime.toString(),
        'paymentAmount': totalPrice,
        'cardNo': selectedCard,
      });

      print('Payment added to Firestore successfully.');
    } catch (e) {
      print('Error adding payment to Firestore: $e');
      throw Exception('Error adding payment to Firestore');
    }
  }

  Future<String> generateBookingID() async {
    try {
      // Fetch the current count of bookings to generate the next ID
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
      await FirebaseFirestore.instance.collection('booking').get();

      int nextID = querySnapshot.size + 1;

      // Format the ID as B00001, B00002, etc.
      String bookingID = 'B${nextID.toString().padLeft(5, '0')}';

      return bookingID;
    } catch (e) {
      print('Error generating booking ID: $e');
      throw Exception('Error generating booking ID');
    }
  }

  Future<void> addBookingToFirestore(String bookingID) async {
    try {
      // Add booking information to Firestore
      await FirebaseFirestore.instance.collection('booking').doc(bookingID).set({
        'bookingID': bookingID,
        'userID': userId,
        'ticketID': widget.ticketID,
        'bookingDate': widget.ticketDate,
        'bookingAdultQty': widget.adultQuantity,
        'bookingChildQty': widget.childQuantity,
        'bookingStatus': 'active',
        'refundRequest':'',
      });
    } catch (e) {
      print('Error adding booking to Firestore: $e');
      throw Exception('Error adding booking to Firestore');
    }
  }

  Future<void> _reloadPage() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BookingSummaryPage(
          ticketID: widget.ticketID,
          adultQuantity: widget.adultQuantity,
          childQuantity: widget.childQuantity,
          adultTicketPrice: widget.adultTicketPrice,
          childTicketPrice: widget.childTicketPrice,
          ticketDate: widget.ticketDate,
        ),
      ),
    );
  }


  Future<Map<String, dynamic>> fetchCardDetails(String cardNo) async {
    try {
      // Fetch card details based on the card number
      DocumentSnapshot<Map<String, dynamic>> cardSnapshot =
      await FirebaseFirestore.instance.collection('card').doc(cardNo).get();

      if (cardSnapshot.exists) {
        return cardSnapshot.data() ?? {};
      } else {
        // Handle the case where the card document does not exist
        print('Card document does not exist for cardNo: $cardNo');
        return {};
      }
    } catch (e) {
      // Handle any errors that might occur during the process
      print('Error fetching card details: $e');
      return {};
    }
  }

  bool isCardExpired(String expiryDate) {
    try {
      // Parse the expiry date to extract month and year
      List<String> dateParts = expiryDate.split('/');
      int expiryMonth = int.tryParse(dateParts[0]) ?? 0;
      int expiryYear = int.tryParse(dateParts[1]) ?? 0;

      // Get the current date
      DateTime currentDate = DateTime.now();

      // Check if the card has passed the expiry date
      return currentDate.isAfter(DateTime(expiryYear, expiryMonth, 1));
    } catch (e) {
      // Handle any errors that might occur during the process
      print('Error checking expiry date: $e');
      return false;
    }
  }

}
