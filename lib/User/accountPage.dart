import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_travel_mate/User/reviewPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_travel_mate/User/editProfile.dart';
import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {

  String userName = '';
  String userID='';

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
          userName = userData['name']?.toString() ?? '';
          userID = userData['userID']?.toString() ?? '';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: EdgeInsets.only(left: 16, top: 25, right: 16),
        child: ListView(
          children: [
            // User Information Section
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.account_circle_rounded,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(width: 16), // Add some space between the icon and text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // Account Section
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  "Account",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(
              height: 15,
              thickness: 2,
            ),
            SizedBox(
              height: 10,
            ),
            buildAccountOptionRow(context, "Edit Profile"),
            buildAccountOptionRow(context, "Reset Password"),
            buildAccountOptionRow(context, "Log Out"),
            SizedBox(
              height: 40,
            ),

            // My Activity Section
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(
                  width: 8,
                ),
                Text(
                  "My Activity",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Divider(
              height: 15,
              thickness: 2,
            ),
            SizedBox(
              height: 10,
            ),
            buildAccountOptionRow(context, "Reviews"),
            buildAccountOptionRow(context, "Bookings"),
          ],
        ),
      ),
    );
  }


  GestureDetector buildAccountOptionRow(BuildContext context, String title) {
    return GestureDetector(
      onTap: () async {
        if (title == "Edit Profile") {
          Navigator.pushNamed(context, '/editProfile');
        } else if (title == "Reset Password") {
          Navigator.pushNamed(context, '/forgotPassword');
        } else if (title == "Bookings") {
          Navigator.pushNamed(context, '/viewBookingsPage');
        } else if (title == "Reviews") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewsPage(userId: userID),
            ),
          );
        } else if (title == "Log Out") {
          await FirebaseAuth.instance.signOut();
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.pushNamed(context, '/login');
        }
        // Add other conditions as needed
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}