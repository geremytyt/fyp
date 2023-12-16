import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';


class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController genderController;
  late TextEditingController countryController;
  late DateTime selectedDate;
  String? selectedGender;
  String? selectedCountry;
  String? userID;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    countryController = TextEditingController();
    loadUserData();
    selectedDate = DateTime.now(); // Set the initial date to the current date
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    await fetchUserDataFromFirestore(email);
  }

  Future<void> fetchUserDataFromFirestore(String email) async {
    try {
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('user');

      // Fetch the user data using the user's email
      QuerySnapshot querySnapshot = await usersCollection.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming email is unique, directly access the first document
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;

        // Convert the data to a Map<String, dynamic>
        Map<String, dynamic> userData = documentSnapshot.data() as Map<String, dynamic>;

        // Update the state only if the widget is still mounted
        if (mounted) {
          setState(() {
            userID=userData['userID']?.toString() ?? '';
            nameController = TextEditingController(text: userData['name']?.toString() ?? '');
            emailController = TextEditingController(text: email);
            genderController = TextEditingController(text: userData['gender']?.toString() ?? '');
            selectedGender = userData['gender']?.toString() ?? '';
            countryController = TextEditingController(text: userData['country']?.toString() ?? '');
            selectedCountry = userData['country']?.toString() ?? '';
            selectedDate = DateTime.parse(userData['dateOfBirth']?.toString() ?? '');
          });
        }
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
        title: Text('Edit Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        padding: EdgeInsets.only(left: 16, top: 25, right: 16),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: ListView(
            children: [
              SizedBox(
                height: 35,
              ),
              buildTextField("Name", nameController),
              buildTextField("E-mail", emailController, enabled: false),
              buildGenderSelector(),
              buildTextField("Country", countryController),
              buildDateOfBirthSelector(),
              SizedBox(
                height: 35,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("CANCEL"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Save the updated user data
                      saveUserData();
                    },
                    child: Text("SAVE"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, TextEditingController controller, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 35.0),
      child: TextField(
        controller: controller,
        enabled: enabled, // Set the enabled property
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(bottom: 3),
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: "Enter $labelText",
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 35.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Gender",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Radio<String>(
                value: "Male",
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),
              Text("Male"),
              Radio<String>(
                value: "Female",
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),
              Text("Female"),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildDateOfBirthSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 35.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Date of Birth",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _selectDate(context);
            },
            child: Text(
              "${selectedDate.toLocal()}".split(' ')[0],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    )) ??
        selectedDate;

    if (picked != selectedDate && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveUserData() async {
    try {
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('user');

      // Use the email as the document ID
      String documentId = emailController.text;

      // Format the date as 'yyyy-MM-dd'
      String formattedDate = selectedDate.toLocal().toIso8601String().split('T')[0];

      // Calculate age based on the updated dateOfBirth
      DateTime now = DateTime.now();
      int age = now.year - selectedDate.year;
      if (now.month < selectedDate.month || (now.month == selectedDate.month && now.day < selectedDate.day)) {
        age--;
      }

      // Update the user data using the email as the document ID
      await usersCollection.doc(documentId).set({
        'userID': userID,
        'name': nameController.text,
        'email':emailController.text,
        'gender': selectedGender!,
        'country': countryController.text,
        'dateOfBirth': formattedDate,
        'age': age,
        'role':"customer",
      });

      // Display a success toast message
      Fluttertoast.showToast(
        msg: 'User data updated successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', documentId);

      Navigator.pushNamed(context, '/accountPage');
    } catch (e) {
      // Display an error toast message
      print('Error updating user data: $e');
      Fluttertoast.showToast(
        msg: 'Error updating user data: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

}
