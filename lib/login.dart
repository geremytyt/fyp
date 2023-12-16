import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_travel_mate/Widget/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isObscure = true;

  Future<void> loginUser(String email, String password) async {
    try {
      // Sign in the user
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check for 'admin,' 'staff,' or 'user' role in Firestore
      String? userRole = await checkUserRoleInFirestore(email);

      if (userRole != null) {
        // Check if the staff account is suspended
        bool isSuspended = await checkStaffAccountStatus(email);

        if (isSuspended) {
          showToast('Account is suspended. Contact administrator for assistance.');
          return;
        }

        // Redirect based on the user's role
        if (userRole == 'admin') {
          Navigator.of(context).pushReplacementNamed('/adminHome');
        } else if (userRole == 'staff') {
          Navigator.of(context).pushReplacementNamed('/staffHome');
        } else if (userRole == 'user') {
          Navigator.of(context).pushReplacementNamed('/home');
        }

        print('Logged in user: ${userCredential.user?.email}');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
      }
    } catch (e) {
      String errorMessage = 'Invalid email or password';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          errorMessage = 'Invalid email or password';
        }
      }

      showToast(errorMessage);
    }
  }

  Future<bool> checkStaffAccountStatus(String staffEmail) async {
    try {
      // Check staff account status
      DocumentSnapshot staffSnapshot = await FirebaseFirestore.instance.collection('staff').doc(staffEmail).get();

      if (staffSnapshot.exists) {
        // Check the 'status' field
        String status = staffSnapshot['status'] ?? '';
        return status.toLowerCase() == 'suspended';
      }

      return false; // Staff account not found
    } catch (e) {
      print('Error checking staff account status: $e');
      return false;
    }
  }


  Future<String?> checkUserRoleInFirestore(String email) async {
    try {
      // Check in the 'admin' collection
      QuerySnapshot adminQuerySnapshot = await firestore
          .collection('admin')
          .where('adminEmail', isEqualTo: email)
          .get();

      if (adminQuerySnapshot.docs.isNotEmpty) {
        return 'admin';
      }

      // Check in the 'staff' collection
      QuerySnapshot staffQuerySnapshot = await firestore
          .collection('staff')
          .where('staffEmail', isEqualTo: email)
          .get();

      if (staffQuerySnapshot.docs.isNotEmpty) {
        return 'staff';
      }

      // Check in the 'user' collection
      QuerySnapshot userQuerySnapshot = await firestore
          .collection('user')
          .where('email', isEqualTo: email)
          .get();

      if (userQuerySnapshot.docs.isNotEmpty) {
        return 'user';
      }

      return null; // User not found in any collection
    } catch (e) {
      print('Error checking user role in Firestore: $e');
      return null;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo (Image widget)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 150,
                    height: 150,
                  ),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  obscureText: _isObscure,
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgotPassword');
                    },
                    child: Text('Forgot Password?'),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      loginUser(emailController.text, passwordController.text);
                    }
                  },
                  child: Text('Login'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
