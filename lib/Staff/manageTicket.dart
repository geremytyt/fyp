import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_travel_mate/Staff/staffViewPoiDetails.dart';
import 'package:my_travel_mate/Widget/widgets.dart';

import 'addTicket.dart';

class ManageTicket extends StatefulWidget {
  final String poiID;

  ManageTicket({required this.poiID});

  @override
  _ManageTicketState createState() => _ManageTicketState();
}

class _ManageTicketState extends State<ManageTicket> {
  late CollectionReference ticket;

  @override
  void initState() {
    super.initState();
    // Initialize the Firestore collection reference
    ticket = FirebaseFirestore.instance.collection('ticket');
    fetchTickets();
  }

  List<Map<String, dynamic>> ticketsData = [];

  Future<void> fetchTickets() async {
    try {
      // Query tickets where poiID is equal to widget.poiID
      QuerySnapshot ticketSnapshot = await ticket
          .where('poiID', isEqualTo: widget.poiID)
          .get();

      // Clear existing data
      ticketsData.clear();

      // Loop through the documents in the snapshot
      ticketSnapshot.docs.forEach((DocumentSnapshot document) {
        // Access the fields of each document
        String ticketID = document['ticketID'];
        String poiID = document['poiID'];
        String ticketDate = document['ticketDate'];
        double childTicketPrice = document['childTicketPrice'].toDouble();
        int childTicketQty = document['childTicketQty'];
        double adultTicketPrice = document['adultTicketPrice'].toDouble();
        int adultTicketQty = document['adultTicketQty'];

        // Store the data in a list
        ticketsData.add({
          'ticketID': ticketID,
          'poiID': poiID,
          'ticketDate': ticketDate,
          'childTicketPrice': childTicketPrice,
          'childTicketQty': childTicketQty,
          'adultTicketPrice': adultTicketPrice,
          'adultTicketQty': adultTicketQty,
        });
      });
    } catch (e) {
      // Handle errors
      showToast('Error fetching tickets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Tickets for ${widget.poiID}'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StaffViewPoiDetailsPage(poiID: widget.poiID),
              ),
            );
          },
        ),
      ),
      body: FutureBuilder(
        future: fetchTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching tickets: ${snapshot.error}'));
          } else {
            return ListView.builder(
              itemCount: ticketsData.length,
              itemBuilder: (context, index) {
                String ticketID = ticketsData[index]['ticketID'];
                String poiID = ticketsData[index]['poiID'];
                String ticketDate = ticketsData[index]['ticketDate'];
                int childTicketQty = ticketsData[index]['childTicketQty'];
                int adultTicketQty = ticketsData[index]['adultTicketQty'];
                double childTicketPrice = ticketsData[index]['childTicketPrice'];
                double adultTicketPrice = ticketsData[index]['adultTicketPrice'];

                return ListTile(
                  title: Text('Ticket ID: $ticketID'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('POI: $poiID'),
                      Text('Date: $ticketDate'),
                      Text('Child Quantity: $childTicketQty'),
                      Text('Adult Quantity: $adultTicketQty'),
                      Text('Child Ticket Price: $childTicketPrice'),
                      Text('Adult Ticket Price: $adultTicketPrice'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Open the edit modal sheet
                          _showEditModal(
                            context,
                            ticketID,
                            poiID,
                            ticketDate,
                            childTicketQty,
                            adultTicketQty,
                            childTicketPrice,
                            adultTicketPrice,
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Show a confirmation dialog for removing the ticket
                          _showConfirmationDialog(context, ticketID);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTicket(poiID: widget.poiID),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }


  void _showEditModal(
      BuildContext context,
      String ticketID,
      String poiID,
      String ticketDate,
      int initialChildQty,
      int initialAdultQty,
      double initialChildTicketPrice,
      double initialAdultTicketPrice,
      ) {
    int editedChildQty = initialChildQty;
    int editedAdultQty = initialAdultQty;
    double editedChildTicketPrice = initialChildTicketPrice;
    double editedAdultTicketPrice = initialAdultTicketPrice;

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Edit Ticket'),
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        Flexible(
                          child: Text('POI: $poiID'),
                        ),
                        SizedBox(width: 16.0), // Adjust the spacing as needed
                        Flexible(
                          child: Text('Date: $ticketDate'),
                        ),
                      ],
                    ),
                    _buildTextFieldWithValidation(
                      label: 'Child Quantity',
                      value: editedChildQty.toString(),
                      onChanged: (value) {
                        setState(() {
                          editedChildQty = int.tryParse(value) ?? initialChildQty;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    _buildTextFieldWithValidation(
                      label: 'Adult Quantity',
                      value: editedAdultQty.toString(),
                      onChanged: (value) {
                        setState(() {
                          editedAdultQty = int.tryParse(value) ?? initialAdultQty;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    _buildTextFieldWithValidation(
                      label: 'Child Ticket Price',
                      value: editedChildTicketPrice.toString(),
                      onChanged: (value) {
                        setState(() {
                          editedChildTicketPrice = double.tryParse(value) ?? initialChildTicketPrice;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    _buildTextFieldWithValidation(
                      label: 'Adult Ticket Price',
                      value: editedAdultTicketPrice.toString(),
                      onChanged: (value) {
                        setState(() {
                          editedAdultTicketPrice = double.tryParse(value) ?? initialAdultTicketPrice;
                        });
                      },
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the modal sheet on cancel
                          },
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Save the edited quantities and prices and update Firestore
                              _saveEditedQuantities(
                                ticketID,
                                poiID,
                                ticketDate,
                                editedChildQty,
                                editedAdultQty,
                                editedChildTicketPrice,
                                editedAdultTicketPrice,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManageTicket(poiID: widget.poiID),
                                ),
                              );
                            }
                          },
                          child: Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _saveEditedQuantities(
      String ticketID,
      String poiID,
      String ticketDate,
      int editedChildQty,
      int editedAdultQty,
      double editedChildTicketPrice,
      double editedAdultTicketPrice,
      ) async {
    try {
      // Reference to the ticket document in Firestore
      DocumentReference ticketRef = FirebaseFirestore.instance.collection('ticket').doc(ticketID);

      // Update the ticket data with edited quantities and prices
      await ticketRef.update({
        'poiID': poiID,
        'ticketDate': ticketDate,
        'childTicketQty': editedChildQty,
        'adultTicketQty': editedAdultQty,
        'childTicketPrice': editedChildTicketPrice,
        'adultTicketPrice': editedAdultTicketPrice,
      });

      // Log success message
      showToast('Ticket updated successfully');
    } catch (e) {
      // Handle errors
      showToast('Error updating ticket: $e');
    }
  }

  Widget _buildTextFieldWithValidation({
    required String label,
    required String value,
    required void Function(String) onChanged,
  }) {
    return Row(
      children: [
        Text('$label:'),
        SizedBox(width: 8.0),
        Expanded(
          child: TextFormField(
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter $label',
            ),
            initialValue: value,
            onChanged: onChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '$label cannot be empty';
              }

              double? parsedDoubleValue = double.tryParse(value);
              if (parsedDoubleValue == null || parsedDoubleValue < 0) {
                int? parsedIntValue = int.tryParse(value);
                if (parsedIntValue == null || parsedIntValue < 0) {
                  return '$label must be a non-negative number';
                }
              }

              return null;
            },
          ),
        ),
      ],
    );
  }



  void _showConfirmationDialog(BuildContext context, String ticketID) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to remove this ticket?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog on cancel
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _removeTicket(ticketID);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageTicket(poiID: widget.poiID),
                  ),
                );
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void _removeTicket(String ticketID) async {
    try {
      // Get a reference to the Firestore document using ticketID
      DocumentReference ticketRef =
      FirebaseFirestore.instance.collection('ticket').doc(ticketID);

      // Delete the document
      await ticketRef.delete();

      showToast('Ticket removed: $ticketID');
    } catch (e) {
      // Handle errors
      showToast('Error removing ticket: $e');
    }
  }
}
