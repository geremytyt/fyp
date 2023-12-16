import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../Widget/widgets.dart';


class AddTrip extends StatefulWidget {
  final String userId;

  AddTrip({required this.userId});

  @override
  _AddTripState createState() => _AddTripState();
}

class _AddTripState extends State<AddTrip> {
  // Define variables to store user input
  late String tripName;
  String tripLocation = 'Kuala Lumpur';
  DateTimeRange? selectedDateRange;
  int numberOfDays = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Trip'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Name Input
              TextFormField(
                decoration: InputDecoration(labelText: 'Trip Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a valid trip name';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    tripName = value;
                  });
                },
              ),
              SizedBox(height: 16.0),

              // Trip Location Dropdown
              DropdownButtonFormField<String>(
                value: tripLocation,
                decoration: InputDecoration(labelText: 'Trip Location'),
                items: statesOfMalaysia.map((state) {
                  return DropdownMenuItem<String>(
                    value: state,
                    child: Text(state),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    tripLocation = value!;
                  });
                },
              ),
              SizedBox(height: 16.0),

              // Trip Date Range Picker
              ListTile(
                title: Text('Trip Date Range'),
                subtitle: selectedDateRange == null
                    ? Text('Select trip start and end date')
                    : Text(
                    '${DateFormat('yyyy-MM-dd').format(selectedDateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(selectedDateRange!.end)}'),
                leading: Icon(Icons.calendar_today), // Add a calendar icon
                onTap: () async {
                  DateTimeRange? pickedDateRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );

                  if (pickedDateRange != null) {
                    setState(() {
                      selectedDateRange = pickedDateRange;
                    });
                  }
                },
              ),
              SizedBox(height: 16.0),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    saveTripDetails();
                  },
                  child: Text('Add Trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void saveTripDetails() async {
    try {
      if (selectedDateRange == null) {
        // Show an error message or handle the lack of date range selection
        return;
      }

      // Calculate the next tripID
      String nextTripId = await getNextTripId();
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(selectedDateRange!.start);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(selectedDateRange!.end);

      // Create a new trip document
      await FirebaseFirestore.instance.collection('trip').doc(nextTripId).set({
        'tripID': nextTripId,
        'tripName': tripName,
        'tripLocation': tripLocation,
        'tripStartDate': formattedStartDate,
        'tripEndDate': formattedEndDate,
        'tripStatus': 'upcoming', // Set initial status as 'upcoming'
        'userID': widget.userId,
      });

      // Calculate the number of days between the start and end dates
      int numberOfDays = selectedDateRange!.end.difference(selectedDateRange!.start).inDays;

      // Generate a new dayID for each day in the range and add documents to the day collection
      for (int i = 0; i <= numberOfDays; i++) {
        DateTime currentDate = selectedDateRange!.start.add(Duration(days: i));
        String formattedDate = DateFormat('yyyy-MM-dd').format(currentDate);
        String newDayID = await generateNewDayID();

        // Print for debugging
        print('Adding day: $formattedDate with dayID: $newDayID');

        // Create a new day document
        await FirebaseFirestore.instance.collection('day').doc(newDayID).set({
          'dayID': newDayID,
          'tripID': nextTripId,
          'dayDate': formattedDate,
        });
      }

      Navigator.pop(context);
    } catch (e) {
      print('Error saving trip details: $e');
    }
  }

  Future<String> generateNewDayID() async {
    try {
      // Fetch the number of documents in the 'day' collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('day').get();

      // Find the maximum day ID
      int maxDayId = 0;
      querySnapshot.docs.forEach((doc) {
        int currentId = int.parse(doc['dayID'].substring(1));
        if (currentId > maxDayId) {
          maxDayId = currentId;
        }
      });

      // Increment the counter for the new day
      int newDayId = maxDayId + 1;

      // Generate a new dayID in the format 'Dxxxxx' based on the number of days
      String newDayID = 'D' + newDayId.toString().padLeft(5, '0');

      return newDayID;
    } catch (e) {
      print('Error generating new dayID: $e');
      // Handle error, you might want to return a default or throw an exception
      return '';
    }
  }



  Future<String> getNextTripId() async {
    // Get the latest trip document to determine the next tripID
    QuerySnapshot querySnapshot =
    await FirebaseFirestore.instance.collection('trip').orderBy('tripID', descending: true).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      // Extract the last tripID
      String lastTripId = querySnapshot.docs.first['tripID'];

      // Increment and format the next tripID
      int lastId = int.parse(lastTripId.substring(1));
      String nextId = 'T' + (lastId + 1).toString().padLeft(5, '0');

      return nextId;
    } else {
      // If there are no existing trips, start with T00001
      return 'T00001';
    }
  }
}
