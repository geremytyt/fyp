import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';



class StaffAccountPage extends StatefulWidget {
  @override
  _StaffAccountPageState createState() => _StaffAccountPageState();
}

class _StaffAccountPageState extends State<StaffAccountPage> {

  String staffName = '';

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
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('staff');

      // Fetch the user data using the user's email
      QuerySnapshot querySnapshot = await usersCollection.where('staffEmail', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;

        // Convert the data to a Map<String, dynamic>
        Map<String, dynamic> userData = documentSnapshot.data() as Map<String, dynamic>;

        setState(() {
          staffName = userData['staffName']?.toString() ?? '';
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
                      staffName,
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

            // AdminAccount Section
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
            buildAdminAccountOptionRow(context, "Edit Profile"),
            buildAdminAccountOptionRow(context, "Reset Password"),
            buildAdminAccountOptionRow(context, "Log Out"),
            SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }


  GestureDetector buildAdminAccountOptionRow(BuildContext context, String title) {
    return GestureDetector(
      onTap: () async {
        if (title == "Edit Profile") {
          Navigator.pushNamed(context, '/staffEditProfilePage');
        } else if (title == "Reset Password") {
          Navigator.pushNamed(context, '/forgotPassword');
        } else if (title == "Log Out") {
          await FirebaseAuth.instance.signOut();
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