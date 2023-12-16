import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Forgot Password'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Image.asset(
                'assets/logo.png',
                width: 150,
                height: 150,
              ),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                resetPassword();
              },
              child: Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text);

      // Display success message using toast
      Fluttertoast.showToast(
        msg: 'Password reset email sent! Check your email.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      Navigator.pop(context);  // Navigate back to the previous screen
    } catch (e) {
      // Display error message based on the exception type
      String errorMessage = 'Error resetting password: $e';

      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email address. Please enter a valid email.';
        } else {
          errorMessage = 'Error: $e';
        }
      }

      // Display error message using toast
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Log the error to the console
      print(errorMessage);
    }
  }
}
