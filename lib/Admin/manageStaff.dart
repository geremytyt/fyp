import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'addStaff.dart';

class ManageStaff extends StatefulWidget {
  @override
  _ManageStaffState createState() => _ManageStaffState();
}

class _ManageStaffState extends State<ManageStaff> {
  late CollectionReference staff;

  @override
  void initState() {
    super.initState();
    staff = FirebaseFirestore.instance.collection('staff');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('Manage Staff'),
          backgroundColor: Theme.of(context).primaryColor,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Suspended'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Active Staff Tab
            StaffList(status: 'active'),

            // Suspended Staff Tab
            StaffList(status: 'suspended'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddStaff(),
              ),
            );
          },
          child: Icon(Icons.add),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

class StaffList extends StatelessWidget {
  final String status;

  StaffList({required this.status});

  Future<void> _showConfirmationDialog(BuildContext context, String staffEmail, bool isSuspended) async {
    String action = isSuspended ? 'unsuspend' : 'suspend';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm $action'),
          content: Text('Are you sure you want to $action this staff account?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update status in Firestore
                await FirebaseFirestore.instance.collection('staff').doc(staffEmail).update({'status': isSuspended ? 'active' : 'suspended'});

                Navigator.of(context).pop();
              },
              child: Text(action.capitalize()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchStaff(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error fetching staff: ${snapshot.error}'));
        } else {
          // Display the staff list
          return ListView.builder(
            itemCount: snapshot.data?.length,
            itemBuilder: (context, index) {
              var staffData = snapshot.data?[index];
              bool isSuspended = staffData?['status'] == 'suspended';

              return ListTile(
                title: Text(staffData?['staffName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${staffData?['staffEmail']}'),
                    Text('Staff ID: ${staffData?['staffID']}'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    _showConfirmationDialog(context, staffData?['staffEmail'], isSuspended);
                  },
                  child: Text(isSuspended ? 'Unsuspend' : 'Suspend'),
                ),
              );
            },
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchStaff(String status) async {
    try {
      // Fetch staff data from Firestore based on status
      QuerySnapshot staffSnapshot = await FirebaseFirestore.instance.collection('staff').where('status', isEqualTo: status).get();

      // Process staff data
      List<Map<String, dynamic>> staffData = staffSnapshot.docs
          .map((DocumentSnapshot document) => document.data() as Map<String, dynamic>)
          .toList();

      return staffData;
    } catch (e) {
      // Handle errors
      print('Error fetching staff: $e');
      return [];
    }
  }
}

extension StringExtension on String {
  // Extension method to capitalize the first letter of a string
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
