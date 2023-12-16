import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_travel_mate/Widget/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCardPage extends StatefulWidget {
  final VoidCallback onCardSaved;

  AddCardPage({required this.onCardSaved});

  @override
  _AddCardPageState createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final TextEditingController cardNoController = TextEditingController();
  final TextEditingController cardHolderNameController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();

  bool isCardValid = false;
  String userId = '';

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email') ?? '';

    print('${email}is found');
    if (email.isNotEmpty) {
      await fetchUserDataFromFirestore(email);
    }
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

        setState(() {
          userId = userData['userID']?.toString() ?? '';
        });
      } else {
        print('User not found.');
      }
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 32.0),
              Center(
                child: Text(
                  'Add New Card',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: cardNoController,
                decoration: InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  // Apply credit card number validation
                  if (validateCreditCard(value!)) {
                    return null;
                  }
                  showToast('Invalid credit card number') ;
                },
              ),
              TextFormField(
                controller: cardHolderNameController,
                decoration: InputDecoration(labelText: 'Cardholder Name'),
              ),
              Row(
                children: [
                  Container(
                    width: 50.0,
                    child: TextFormField(
                      controller: cvvController,
                      decoration: InputDecoration(labelText: 'CVV'),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: TextFormField(
                      controller: expiryDateController,
                      decoration: InputDecoration(labelText: 'Expiry Date (MM/YYYY)'),
                      maxLength: 7,
                      validator: (value) {
                        // Apply expiry date validation
                        if (validateExpiryDate(value!)) {
                          return null;
                        }
                        showToast('Invalid expiry date');
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      saveCardDetails();
                      widget.onCardSaved();
                    },
                    child: Text('Save Card'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Validate credit card number using Luhn algorithm
  bool validateCreditCard(String cardNo) {
    if (cardNo.isEmpty) {
      return false;
    }

    // Remove spaces and non-numeric characters from the card number
    String cleanCardNo = cardNo.replaceAll(RegExp(r'[^0-9]'), '');

    int sum = 0;
    bool isOdd = cleanCardNo.length.isOdd;

    for (int i = 0; i < cleanCardNo.length; i++) {
      int digit = int.parse(cleanCardNo[i]);

      if (isOdd) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isOdd = !isOdd;
    }

    return sum % 10 == 0;
  }

  // bool validateExpiryDate(String expiryDate) {
  //   // Use regular expression to validate expiry date format (MM/YYYY)
  //   RegExp regex = RegExp(r'^\d{2}/\d{4}$');
  //
  //   if (!regex.hasMatch(expiryDate)) {
  //     return false; // Invalid format
  //   }
  //
  //   // Extract month and year from the expiry date
  //   List<String> dateParts = expiryDate.split('/');
  //   int expiryMonth = int.tryParse(dateParts[0]) ?? 0;
  //   int expiryYear = int.tryParse(dateParts[1]) ?? 0;
  //
  //   // Get current month and year
  //   DateTime now = DateTime.now();
  //   int currentMonth = now.month;
  //   int currentYear = now.year;
  //
  //   // Check if expiry date is later than today's month
  //   if (expiryYear > currentYear || (expiryYear == currentYear && expiryMonth >= currentMonth)) {
  //     return true; // Valid expiry date
  //   } else {
  //     return false; // Invalid expiry date
  //   }
  // }

  bool validateExpiryDate(String expiryDate) {
    // Use regular expression to validate expiry date format (MM/YYYY)
    RegExp regex = RegExp(r'^\d{2}/\d{4}$');

    if (!regex.hasMatch(expiryDate)) {
      return false; // Invalid format
    }

    // Extract month and year from the expiry date
    List<String> dateParts = expiryDate.split('/');
    int expiryMonth = int.tryParse(dateParts[0]) ?? 0;
    int expiryYear = int.tryParse(dateParts[1]) ?? 0;

    // Get current month and year
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    // Check if expiry date is later than today's month and year
    if (expiryYear > currentYear || (expiryYear == currentYear && expiryMonth >= currentMonth)) {
      return true; // Valid expiry date
    } else {
      return false; // Invalid expiry date
    }
  }


  Future<bool> checkIfCardExists(String cardNumber, String userId) async {
    try {
      QuerySnapshot cardSnapshot = await FirebaseFirestore.instance
          .collection('card')
          .where('cardNo', isEqualTo: cardNumber)
          .where('userID', isEqualTo: userId)
          .get();

      return cardSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if card exists: $e');
      return false;
    }
  }



  void saveCardDetails() async {
    try {
      // Check if the card is already registered for the specific user
      bool isCardRegistered = await checkIfCardExists(cardNoController.text, userId);

      if (isCardRegistered) {
        showToast('This card is already registered for the user.');
        return;
      }

      List<String> dateParts = expiryDateController.text.split('/');
      int expiryMonth = int.tryParse(dateParts[0]) ?? 0;
      int expiryYear = int.tryParse(dateParts[1]) ?? 0;

      String formattedExpiryDate = '$expiryYear-${expiryMonth.toString().padLeft(2, '0')}-01';

      // Generate a card ID (document key)
      String cardID = await generateCardID();

      Map<String, dynamic> cardData = {
        'cardNo': cardNoController.text,
        'cardHolderName': cardHolderNameController.text,
        'cvv': cvvController.text,
        'expiryDate': formattedExpiryDate,
        'userID': userId,
        'cardID':cardID,
      };

      // Save card details with the generated card ID
      await FirebaseFirestore.instance.collection('card').doc(cardID).set(cardData);

      showToast('Card details saved successfully');
      widget.onCardSaved();
    } catch (e) {
      // Print an error message
      showToast('Invalid card details');
    }
  }

  Future<String> generateCardID() async {
    try {
      // Fetch the current card count from Firestore
      QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection('card').get();

      int cardCount = snapshot.size + 1;

      // Format the card ID with leading zeros
      String cardID = 'C' + cardCount.toString().padLeft(5, '0');

      return cardID;
    } catch (e) {
      print('Error generating card ID: $e');
      throw Exception('Error generating card ID');
    }
  }

}


