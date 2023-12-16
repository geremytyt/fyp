import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';


class AdminEditProfilePage extends StatefulWidget {
  @override
  _AdminEditProfilePageState createState() => _AdminEditProfilePageState();
}

class _AdminEditProfilePageState extends State<AdminEditProfilePage> {
  late TextEditingController adminNameController;
  late TextEditingController adminEmailController;
  late TextEditingController genderController;
  late DateTime selectedDate;
  String? selectedGender;
  String? adminID;

  @override
  void initState() {
    super.initState();
    adminNameController = TextEditingController();
    adminEmailController = TextEditingController();
    loadUserData();
    selectedDate = DateTime.now(); // Set the initial date to the current date
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    await fetchUserDataFromFirestore(email);
  }

  Future<void> fetchUserDataFromFirestore(String adminEmail) async {
    try {
      CollectionReference adminsCollection = FirebaseFirestore.instance.collection('admin');
      QuerySnapshot querySnapshot = await adminsCollection.where('adminEmail', isEqualTo: adminEmail).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;

        // Convert the data to a Map<String, dynamic>
        Map<String, dynamic> adminData = documentSnapshot.data() as Map<String, dynamic>;

        // Update the state only if the widget is still mounted
        if (mounted) {
          setState(() {
            adminID=adminData['adminID']?.toString() ?? '';
            adminNameController = TextEditingController(text: adminData['adminName']?.toString() ?? '');
            adminEmailController = TextEditingController(text: adminEmail);
            genderController = TextEditingController(text: adminData['gender']?.toString() ?? '');
            selectedGender = adminData['gender']?.toString() ?? '';
            selectedDate = DateTime.parse(adminData['dateOfBirth']?.toString() ?? '');
          });
        }
      } else {
        print('User not found.');
      }
    } catch (e) {
      print('Error fetching admin data from Firestore: $e');
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
              buildTextField("Name", adminNameController),
              buildTextField("E-mail", adminEmailController, enabled: false),
              buildGenderSelector(),
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
                      // Save the updated admin data
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
      CollectionReference adminsCollection = FirebaseFirestore.instance.collection('admin');

      // Use the adminEmail as the document ID
      String documentId = adminEmailController.text;

      // Format the date as 'yyyy-MM-dd'
      String formattedDate = selectedDate.toLocal().toIso8601String().split('T')[0];

      // Calculate age based on the updated dateOfBirth
      DateTime now = DateTime.now();
      int age = now.year - selectedDate.year;
      if (now.month < selectedDate.month || (now.month == selectedDate.month && now.day < selectedDate.day)) {
        age--;
      }

      await adminsCollection.doc(documentId).set({
        'adminID': adminID,
        'adminName': adminNameController.text,
        'adminEmail':adminEmailController.text,
        'gender': selectedGender!,
        'dateOfBirth': formattedDate,
        'age': age,
        'role':"admin",
      });


      // Display a success toast message
      Fluttertoast.showToast(
        msg: 'Admin data updated successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminEmail', documentId);

      Navigator.pushNamed(context, '/adminAccountPage');
    } catch (e) {
      // Display an error toast message
      print('Error updating admin data: $e');
      Fluttertoast.showToast(
        msg: 'Error updating admin data: $e',
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
