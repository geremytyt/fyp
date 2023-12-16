import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:my_travel_mate/Widget/widgets.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedGender = 'Male';
  String? _selectedCountry;
  List<String> _countries = [];

  late String nextUserId;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadLastUserId();
    _fetchCountries();
  }

  String? _nameErrorText;
  String? _emailErrorText;
  String? _passwordErrorText;
  String? _dateErrorText;
  String? _countryErrorText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Register'),
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
                decoration: InputDecoration(labelText: 'Name', errorText: _nameErrorText),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email', errorText: _emailErrorText),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, // Toggle visibility based on the state
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: _passwordErrorText,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      // Toggle password visibility
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                children: [
                  Text('Gender: '),
                  Radio(
                    value: 'Male',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  Text('Male'),
                  Radio(
                    value: 'Female',
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  Text('Female'),
                ],
              ),
              SizedBox(height: 16.0),
              Row(
                children: [
                  Text('Date of Birth: '),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: Text(
                      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              // Dropdown for Country
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                  });
                },
                items: _countries.map<DropdownMenuItem<String>>((String country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Country', errorText: _countryErrorText),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_validateFields()) {
                    try {
                      // Register user in Firebase Authentication
                      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );

                      // Save user data to Firestore with the generated ID
                      CollectionReference usersCollection = FirebaseFirestore.instance.collection('user');

                      // Calculate age based on date of birth
                      DateTime now = DateTime.now();
                      int age = now.year - _selectedDate.year;
                      if (now.month < _selectedDate.month || (now.month == _selectedDate.month && now.day < _selectedDate.day)) {
                        age--;
                      }

                      await usersCollection.doc(_emailController.text).set({
                        'userID': nextUserId,
                        'name': _nameController.text,
                        'email': _emailController.text,
                        'dateOfBirth': _selectedDate.toIso8601String(),
                        'gender': _selectedGender,
                        'country': _selectedCountry,
                        'age': age,
                        'role': "customer",
                      });

                      Navigator.of(context).pushReplacementNamed('/login');
                    } catch (e) {
                      showToast('Registration failed: $e');
                    }
                  }
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(Uri.parse('https://restcountries.com/v2/all'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<String> countries = data.map((country) => country['name'].toString()).toList();

        setState(() {
          _countries = countries;

          // If 'United States of America' is selected, set it to 'USA'
          if (_selectedCountry == 'United States of America') {
            _selectedCountry = 'Usa';
          }
        });
      } else {
        print('Failed to load countries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading countries: $e');
    }
  }


  Future<void> _loadLastUserId() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection('user').orderBy('userID', descending: true).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        // Extract the numeric part, increment it, and format it back with leading zeros
        int numericUserId = int.tryParse(snapshot.docs.first['userID'].substring(1)) ?? 0;
        nextUserId = 'U${(numericUserId + 1).toString().padLeft(5, '0')}';
      } else {
        // No existing users, start from "U00001"
        nextUserId = 'U00001';
      }
    } catch (e) {
      // Handle error
      print('Error loading last userID: $e');
    }
  }

  bool _validateFields() {
    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
      _countryErrorText = null;
      _dateErrorText=null;
    });

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedCountry!.isEmpty) {
      // Set specific error messages for each field
      if (_nameController.text.isEmpty) {
        setState(() {
          _nameErrorText = 'Name is required.';
        });
      }
      if (_emailController.text.isEmpty) {
        setState(() {
          _emailErrorText = 'Email is required.';
        });
      }
      if (_passwordController.text.isEmpty) {
        setState(() {
          _passwordErrorText = 'Password is required.';
        });
      }
      if (_selectedCountry!.isEmpty) {
        setState(() {
          _countryErrorText = 'Country is required.';
        });
      }
      return false;
    }

    if (_passwordController.text.length < 8) {
      setState(() {
        _passwordErrorText = 'Password must be at least 8 characters long.';
        print('Error: Password must be at least 8 characters long.');
      });
      return false;
    }

    // Check if the user is 18 years or older
    DateTime now = DateTime.now();
    int age = now.year - _selectedDate.year;
    if (now.month < _selectedDate.month || (now.month == _selectedDate.month && now.day < _selectedDate.day)) {
      age--;
    }
    if (age < 18) {
      setState(() {
        _dateErrorText = 'User must be 18 years or older.';
        print('Error: User must be 18 years or older.');
      });
      return false;
    }

    return true;
  }
}
