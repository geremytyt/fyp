import 'package:flutter/material.dart';
import 'package:my_travel_mate/Staff/reportPage.dart';
import 'package:my_travel_mate/Staff/staffAccountPage.dart';

import 'managePoi.dart';

class StaffHomePage extends StatefulWidget {
  @override
  _StaffHomePageState createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_currentIndex),
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

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return ManagePoi();
      case 1:
        return ReportPage();
      case 2:
        return StaffAccountPage();
      default:
        return Container();
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: StaffHomePage(),
  ));
}
