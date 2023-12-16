import 'package:flutter/material.dart';
import 'package:my_travel_mate/Staff/manageBooking.dart';
import 'package:my_travel_mate/Staff/managePoi.dart';

import '../Staff/reportPage.dart';
import 'adminAccountPage.dart';
import 'manageStaff.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    ManagePoi(),
    ManageStaff(),
    ManageBooking(),
    ReportPage(),
    AdminAccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.place),
            label: 'POI',
            backgroundColor: Theme.of(context).primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervised_user_circle_sharp),
            label: 'Staff',
            backgroundColor: Theme.of(context).primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Booking',
            backgroundColor: Theme.of(context).primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Report',
            backgroundColor: Theme.of(context).primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}




void main() {
  runApp(MaterialApp(
    home: AdminHomePage(),
  ));
}
