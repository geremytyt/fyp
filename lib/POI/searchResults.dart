// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:my_travel_mate/POI/viewPoiDetails.dart';
//
// import '../main.dart';
//
// class SearchResultsPage extends StatefulWidget {
//   SearchResultsPage();
//
//   @override
//   _SearchResultsPageState createState() => _SearchResultsPageState();
// }
//
// class _SearchResultsPageState extends State<SearchResultsPage> {
//   TextEditingController _searchController = TextEditingController();
//   List<PlaceDetails> searchResults = [];
//
//   void _handlePoiTapped(BuildContext context, PlaceDetails selectedPoi) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ViewPoiDetailsPage(poiID: selectedPoi.poiID),
//       ),
//     );
//   }
//
//   void _handleSearch(String query) async {
//     try {
//       final dataSnapshot = await FirebaseDatabase.instance.reference().child('poi').once();
//
//       // Process the query results
//       final List<PlaceDetails> tempResults = [];
//
//       if (dataSnapshot.snapshot.value != null) {
//         (dataSnapshot.snapshot.value as Map<String, dynamic>).forEach((key, value) {
//           final data = value as Map<String, dynamic>;
//
//           // Check if poiName contains the search query
//           if (data['poiName'].toString().toLowerCase().contains(query.toLowerCase())) {
//             final placeDetails = PlaceDetails(
//               key, // Assuming the key is the poiID
//               data['poiName'],
//               data['poiNoOfReviews'],
//               data['poiRating'].toDouble(),
//               data['score'],
//               data['imageUrl'],
//               // data['poiType'],
//             );
//
//             tempResults.add(placeDetails);
//           }
//         });
//       }
//
//       // Update the state with search results
//       setState(() {
//         searchResults = tempResults;
//       });
//     } catch (e) {
//       print('Error searching for POIs: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Search Results'),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Enter search query...',
//               ),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               _handleSearch(_searchController.text);
//             },
//             child: Text('Search'),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: searchResults.length,
//               itemBuilder: (context, index) {
//                 final placeDetails = searchResults[index];
//
//                 return ListTile(
//                   title: Text(placeDetails.poiName),
//                   subtitle: Text('Rating: ${placeDetails.poiRating}'),
//                   onTap: () {
//                     _handlePoiTapped(context, placeDetails);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }