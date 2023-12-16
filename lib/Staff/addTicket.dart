import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Widget/widgets.dart';
import 'manageTicket.dart';

class AddTicket extends StatefulWidget {
  final String poiID;

  AddTicket({required this.poiID});

  @override
  _AddTicketState createState() => _AddTicketState();
}

class _AddTicketState extends State<AddTicket> {
  late DateTime selectedDate; // Track the selected date
  int childQuantity = 0;
  int adultQuantity = 0;
  double childTicketPrice = 0.0;
  double adultTicketPrice = 0.0;

  @override
  void initState() {
    super.initState();
    // Set the initial selected date to today + 7 days
    selectedDate = DateTime.now().add(Duration(days: 7));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Ticket for ${widget.poiID}'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ManageTicket(poiID: widget.poiID),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Selection
                Text('Select Ticket Date:'),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().add(Duration(days: 7)), // Minimum date
                      lastDate: DateTime(2101),
                    );

                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text('Pick Date'),
                ),
                SizedBox(height: 16.0),
                // Add your form elements here
                Text('Child Quantity:'),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      childQuantity = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                SizedBox(height: 16.0),
                Text('Adult Quantity:'),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      adultQuantity = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                SizedBox(height: 16.0),
                Text('Child Ticket Price:'),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      childTicketPrice = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
                SizedBox(height: 16.0),
                Text('Adult Ticket Price:'),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      adultTicketPrice = double.tryParse(value) ?? 0.0;
                    });
                  },
                ),
                SizedBox(height: 16.0),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Implement the logic to save the new ticket to Firestore
                      _addTicket();
                    },
                    child: Text('Save Ticket'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _addTicket() async {
    try {
      // Retrieve the last ticketID from the Firestore collection
      QuerySnapshot lastTicketQuery = await FirebaseFirestore.instance
          .collection('ticket')
          .orderBy('ticketID', descending: true)
          .limit(1)
          .get();

      int newTicketNumber = 1;

      if (lastTicketQuery.docs.isNotEmpty) {
        // If there are existing tickets, extract the number from the last ticketID
        String lastTicketID = lastTicketQuery.docs.first['ticketID'];
        int lastTicketNumber = int.parse(lastTicketID.substring(1));

        // Increment the number for the new ticketID
        newTicketNumber = lastTicketNumber + 1;
      }

      String newTicketID = 'T' + newTicketNumber.toString().padLeft(5, '0');
      String formattedDate = "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}";

      await FirebaseFirestore.instance.collection('ticket').doc(newTicketID).set({
        'ticketID': newTicketID,
        'poiID': widget.poiID,
        'ticketDate': formattedDate,
        'childTicketPrice': childTicketPrice,
        'childTicketQty': childQuantity,
        'adultTicketPrice': adultTicketPrice,
        'adultTicketQty': adultQuantity,
      });

      showToast('Ticket added successfully');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManageTicket(poiID: widget.poiID),
        ),
      );
    } catch (e) {
      // Handle errors
      showToast('Error adding ticket: $e');
    }
  }

}
