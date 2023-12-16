import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_travel_mate/Admin/manageStaff.dart';
import 'package:my_travel_mate/Widget/widgets.dart';

class AddStaff extends StatefulWidget {
  @override
  _AddStaffState createState() => _AddStaffState();
}

class _AddStaffState extends State<AddStaff> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  late String nextStaffId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Staff'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_validateFields()) {
                    try {
                      if (await _isEmailAlreadyRegistered(_emailController.text)) {
                        showToast('Email is already registered.');
                      } else {
                        await _loadLastStaffId();

                        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: _emailController.text,
                          password: _passwordController.text,
                        );

                        CollectionReference staffCollection = FirebaseFirestore.instance.collection('staff');

                        await staffCollection.doc(_emailController.text).set({
                          'staffName': _nameController.text,
                          'staffEmail': _emailController.text,
                          'staffID': nextStaffId,
                          'role': 'staff',
                          'status': 'active',
                          'gender': 'Male',
                          'dateOfBirth':'2002-01-01',
                          'age':'',
                        });

                        showToast('Staff added successfully!');
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      showToast('Adding staff failed: $e');
                    }
                  }
                },
                child: Text('Add Staff'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateFields() {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showToast('All fields are required.');
      return false;
    }

    if (_passwordController.text.length < 8) {
      showToast('Password must be at least 8 characters long.');
      return false;
    }

    return true;
  }

  Future<void> _loadLastStaffId() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection('staff').orderBy('staffID', descending: true).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        int numericStaffId = int.tryParse(snapshot.docs.first['staffID'].substring(1)) ?? 0;
        nextStaffId = 'S${(numericStaffId + 1).toString().padLeft(4, '0')}';
      } else {
        // No existing staff, start from "S0001"
        nextStaffId = 'S0001';
      }
    } catch (e) {
      // Handle error
      showToast('Error loading last staffID: $e');
    }
  }

  Future<bool> _isEmailAlreadyRegistered(String email) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection('staff').where('staffEmail', isEqualTo: email).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // Handle error
      showToast('Error checking email registration: $e');
      return false;
    }
  }
}
