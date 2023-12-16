import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:my_travel_mate/Staff/managePoi.dart';
import 'package:my_travel_mate/Staff/staffHome.dart';
import 'package:my_travel_mate/User/viewBookingsPage.dart';
import 'package:my_travel_mate/forgotPassword.dart';
import 'package:my_travel_mate/User/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Admin/adminAccountPage.dart';
import 'Admin/adminEditProfile.dart';
import 'Admin/adminHome.dart';
import 'Admin/manageStaff.dart';
import 'POI/searchResults.dart';
import 'Staff/staffAccountPage.dart';
import 'Staff/staffEditProfile.dart';
import 'User/tripDetails.dart';
import 'User/viewStatePoi.dart';
import 'login.dart';
import 'package:my_travel_mate/POI/viewPoiDetails.dart';
import 'package:my_travel_mate/User/tripPage.dart';
import 'package:my_travel_mate/User/accountPage.dart';
import 'package:my_travel_mate/User/editProfile.dart';
import 'package:my_travel_mate/Widget/searchBar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_place/google_place.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Color customColor = Color(0xFF74DED7);

  runApp(MyApp(customColor));
}

class MyApp extends StatelessWidget {
  final Color customColor;

  MyApp(this.customColor);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Travel Mate',
      theme: ThemeData(
        primaryColor: customColor,
      ),
      home: LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => MyHomePage(),
        '/register': (context) => RegisterScreen(),
        '/accountPage':(context)=> AccountPage(),
        '/forgotPassword':(context)=> ForgotPasswordPage(),
        '/editProfile': (context) => EditProfilePage(),
        '/tripDetails': (context) => TripDetails(tripId: ''),
        '/viewBookingsPage': (context) => ViewBookingsPage(),
        '/tripPage': (context) => TripPage(),


        '/staffHome': (context) => StaffHomePage(),
        '/managePoi': (context) => ManagePoi(),
        '/staffEditProfilePage': (context) => StaffEditProfilePage(),
        '/staffAccountPage': (context) => StaffAccountPage(),

        '/adminHome': (context) => AdminHomePage(),
        '/adminAccountPage': (context) => AdminAccountPage(),
        '/adminEditProfilePage': (context) => AdminEditProfilePage(),
        '/manageStaff': (context) => ManageStaff(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    TripPage(),
    AccountPage(),
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
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Theme.of(context).primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.airplanemode_active),
            label: 'Trips',
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

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class POI {
  final String poiID;
  final String poiType;
  final String poiName;
  final String poiAddress;
  final String poiLocation;
  final String poiUrl;
  final String poiPriceRange;
  final String poiPrice;
  final String poiPhone;
  final String poiTag;
  final String poiOperatingHours;
  final String poiRating;
  final String poiNoOfReviews;
  final String poiDescription;
  final double poiLatitude;
  final double poiLongitude;
  String imageUrl;

  POI({
    required this.poiID,
    required this.poiType,
    required this.poiName,
    required this.poiAddress,
    required this.poiLocation,
    required this.poiUrl,
    required this.poiPriceRange,
    required this.poiPrice,
    required this.poiPhone,
    required this.poiTag,
    required this.poiOperatingHours,
    required this.poiRating,
    required this.poiNoOfReviews,
    required this.poiDescription,
    required this.poiLatitude,
    required this.poiLongitude,
    required this.imageUrl,
  });
}

class StateListItem extends StatelessWidget {
  final String stateName;

  StateListItem({required this.stateName});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to the ViewStatePoi page and pass the stateName
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewStatePoi(stateName: stateName),
          ),
        );
      },
      child: Hero(
        tag: 'stateTag_$stateName',
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 260,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/${stateName.toLowerCase()}.png'), // Convert to lowercase
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(1.0),
                BlendMode.dstATop,
              ),
            ),
          ),
          child: Center(
            child: Text(
              stateName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}



class _HomeScreenState extends State<HomeScreen> {
  // final List<PlaceDetails> poiList = [];
  final List<POI> demographicPoiList = [];
  final List<POI> topRatedPoiList = [];
  List<POI> allPOIs = [];
  List<POI> hotelList = [];
  List<POI> restaurantList = [];
  List<POI> attractionList = [];
  List<String> poiIDList = [];
  String errorMessage = '';
  String searchQuery = '';
  String name='';
  String userID='';
  String country='';
  String gender='';
  String age='';
  String email='';
  String dateOfBirth='';
  TextEditingController searchController = TextEditingController();
  final List<POI> contentBasedListRestaurant = [];
  final List<POI> contentBasedListAttractions = [];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    await loadUserData();
    fetchPointsOfInterest();
    // fetchTopRatedPoi();
    // fetchDemographicRecommendations(country, age, gender);
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email') ?? '';

    print('${email}is found');
    if (email.isNotEmpty) {
      await fetchUserDataFromFirestore(email);
    }
  }


  Future<void> fetchUserDataFromFirestore(String email) async {
    try {
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('user');

      // Fetch the user data using the user's email
      QuerySnapshot querySnapshot = await usersCollection.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;

        // Convert the data to a Map<String, dynamic>
        Map<String, dynamic> userData = documentSnapshot.data() as Map<String, dynamic>;

        setState(() {
          name = userData['name']?.toString() ?? '';
          country = userData['country']?.toString() ?? '';
          gender = userData['gender']?.toString() ?? '';
          age = userData['age']?.toString() ?? '';
          dateOfBirth = userData['dateOfBirth']?.toString() ?? '';
          userID=userData['userID']?.toString() ?? '';
        });
      } else {
        print('User not found.');
      }
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
    }
  }

  List<POI> filterPOIs(String query) {
    return allPOIs
        .where((poi) =>
    poi.poiName.toLowerCase().contains(query.toLowerCase()) ||
        poi.poiType.toLowerCase().contains(query.toLowerCase()) ||
        poi.poiAddress.toLowerCase().contains(query.toLowerCase()) ||
        poi.poiTag.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void showSearchResults(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final searchQuery = searchController.text;
        final searchResults = filterPOIs(searchQuery);

        return AlertDialog(
          title: Text('Search Results for "$searchQuery"'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(searchResults[index].poiName),
                  onTap: () {
                    Navigator.pop(context); // Close the search results dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewPoiDetailsPage(poiID: searchResults[index].poiID),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchImageForPOIString(Map<String, dynamic> poiDetails) async {
    // Use Google Places API to fetch additional details, including images
    const apiKey = 'AIzaSyDz9pepBSYg90CZXK1WZkucemlJxlSinuY';
    final placeName = poiDetails['poiName'];

    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$placeName'
            '&inputtype=textquery'
            '&fields=photos'
            '&key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final List<dynamic> candidates = data['candidates'];

        if (candidates != null && candidates.isNotEmpty) {
          final String photoReference = candidates[0]['photos'][0]['photo_reference'];
          final imageUrl =
              'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';

          poiDetails['imageUrl'] = imageUrl;
        }
      }
    }
  }

  Future<void> fetchImageForPOI(POI poiDetails) async {
    const apiKey = 'AIzaSyDz9pepBSYg90CZXK1WZkucemlJxlSinuY';
    final placeName = poiDetails.poiName;

    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$placeName'
            '&inputtype=textquery'
            '&fields=photos'
            '&key=$apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final List<dynamic> candidates = data['candidates'];

        if (candidates != null && candidates.isNotEmpty) {
          final String photoReference = candidates[0]['photos'][0]['photo_reference'];

          if (photoReference != null && photoReference.isNotEmpty) {
            final imageUrl =
                'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';

            setState(() {
              poiDetails.imageUrl = imageUrl;
            });
          }
        }
      }
    }
  }


  String handleNaN(dynamic value) {
    return (value is double || value is int) ? value.toString() : '-1';
  }

  Future<void> fetchPointsOfInterest() async {
    try {
      // Fetch JSON data from the Flask API
      final response =
      await http.get(Uri.parse('http://34.124.197.131:5000/get_all_poi_df'));

      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);
        allPOIs.clear();
        setState(() {
          allPOIs.addAll(dataList.map((item) => POI(
            poiID: item['poiID']?.toString() ?? '',
            poiType: item['poiType']?.toString() ?? '',
            poiName: item['poiName']?.toString() ?? '',
            poiAddress: item['poiAddress']?.toString() ?? '',
            poiLocation: item['poiLocation']?.toString() ?? '',
            poiUrl: item['poiUrl']?.toString() ?? '',
            poiPriceRange: item['poiPriceRange']?.toString() ?? '',
            poiPrice: item['poiPrice']?.toString() ?? '',
            poiPhone: item['poiPhone']?.toString() ?? '',
            poiTag: item['poiTag']?.toString() ?? '',
            poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
            poiRating: item['poiRating']?.toString() ?? '',
            poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
            poiDescription: item['poiDescription']?.toString() ?? '',
            poiLatitude: item['poiLatitude']?.toDouble() ?? 0.0,
            poiLongitude: item['poiLongitude']?.toDouble() ?? 0.0,
            imageUrl: '',
          )));
        });

        allPOIs.sort((a, b) => b.poiRating.compareTo(a.poiRating));

        // Create separate lists for each poiType
        hotelList = allPOIs.where((poi) => poi.poiType == 'Hotel').toList();
        restaurantList =
            allPOIs.where((poi) => poi.poiType == 'Restaurant').toList();
        attractionList =
            allPOIs.where((poi) => poi.poiType == 'Attraction').toList();

        hotelList = hotelList.take(8).toList();
        restaurantList = restaurantList.take(8).toList();
        attractionList = attractionList.take(8).toList();

        // Call the function to retrieve the image for each POI in the lists
        for (final poiDetails in attractionList) {
          fetchImageForPOI(poiDetails);
        }
        for (final poiDetails in restaurantList) {
          fetchImageForPOI(poiDetails);
        }
        for (final poiDetails in hotelList) {
          fetchImageForPOI(poiDetails);
        }

        await retrievePoiIDs();
        await fetchContentBasedListForRestaurants();
        await fetchContentBasedListForAttractions();

        // Update the UI
        setState(() {});
      } else {
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyTravelMate'),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: errorMessage.isNotEmpty
          ? Center(
        child: Text(errorMessage),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Search for a POI',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                    },
                  ),
                ),
                onSubmitted: (value) {
                  showSearchResults(context);
                },
              ),
            ),
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Popular Destinations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final stateName in ['Kuala Lumpur', 'Penang', 'Perak', 'Melaka', 'Pahang', 'Johor'])
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 260,
                      child: StateListItem(stateName: stateName),
                    ),
                  // Add more StateListItem widgets as needed
                ],
              ),
            ),
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Places to Eat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final placeDetails in restaurantList)
                    buildPoiCard(placeDetails),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Popular Attractions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final placeDetails in attractionList)
                    buildPoiCard(placeDetails),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Where to Stay',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final placeDetails in hotelList)
                    buildPoiCard(placeDetails),
                ],
              ),
            ),
            if ((contentBasedListRestaurant != null && contentBasedListRestaurant.isNotEmpty) ||
                (contentBasedListAttractions != null && contentBasedListAttractions.isNotEmpty))
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Based on your history',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final placeDetails in contentBasedListRestaurant)
                    buildPoiCard(placeDetails),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final placeDetails in contentBasedListAttractions)
                    buildPoiCard(placeDetails),
                ],
              ),
            ),
          ],

        ),
      ),
    );
  }



  Widget buildPoiCard(POI placeDetails) {
    return Card(
      child: InkWell(
        onTap: () {
          // Navigate to viewPoiDetails page when a POI is clicked
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewPoiDetailsPage(poiID: placeDetails.poiID),
            ),
          );
        },
        child: Container(
          width: 150,
          height: 200,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (placeDetails.imageUrl != null)
                Image.network(
                  placeDetails.imageUrl,
                  width: 75,
                  height: 75,
                  fit: BoxFit.cover,
                ),
              Expanded(
                child: Text(
                  placeDetails.poiName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  Text(
                    ' ${double.parse(placeDetails.poiRating).toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> fetchTopRatedPoi() async {
    try {
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_top_rated_poi'));

      if (response.statusCode == 200) {
        final List<dynamic> dataList = json.decode(response.body);

        // Fetch details for each POI
        for (final item in dataList) {
          await fetchImageForPOI(item);
        }

        setState(() {
          topRatedPoiList.addAll(dataList.map((item) => POI(
            poiID: item['poiID']?.toString() ?? '',
            poiType: item['poiType']?.toString() ?? '',
            poiName: item['poiName']?.toString() ?? '',
            poiAddress: item['poiAddress']?.toString() ?? '',
            poiLocation: item['poiLocation']?.toString() ?? '',
            poiUrl: item['poiUrl']?.toString() ?? '',
            poiPriceRange: item['poiPriceRange']?.toString() ?? '',
            poiPrice: item['poiPrice']?.toString() ?? '',
            poiPhone: item['poiPhone']?.toString() ?? '',
            poiTag: item['poiTag']?.toString() ?? '',
            poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
            poiRating: item['poiRating']?.toString() ?? '',
            poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
            poiDescription: item['poiDescription']?.toString() ?? '',
            poiLatitude: item['poiLatitude']?.toDouble() ?? '',
            poiLongitude: item['poiLongitude']?.toDouble() ?? '',
            imageUrl: item['imageUrl']?.toString() ?? '',
          )));
        });
      } else {
        setState(() {
          errorMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> fetchDemographicRecommendations(String country, String age, String gender) async {
    try {
      final String apiUrl = 'http://34.124.197.131:5000/get_demographic_recommendations';

      Map<String, dynamic> data = {
        'country': country,
        'age': age,
        'gender': gender,
      };

      // Fetch JSON data from the Flask API using a POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);

        // Check if the dataMap contains a key representing the list of POIs
        if (dataMap.containsKey('error')) {
          print('Error: ${dataMap['error']}');
        } else {
          final List<dynamic> dataList = dataMap['top_10_demo'];
          demographicPoiList.clear();

          for (var item in dataList) {
            await fetchImageForPOI(item); // Fetch image for each POI
            demographicPoiList.add(POI(
              poiID: item['poiID']?.toString() ?? '',
              poiType: item['poiType']?.toString() ?? '',
              poiName: item['poiName']?.toString() ?? '',
              poiAddress: item['poiAddress']?.toString() ?? '',
              poiLocation: item['poiLocation']?.toString() ?? '',
              poiUrl: item['poiUrl']?.toString() ?? '',
              poiPriceRange: item['poiPriceRange']?.toString() ?? '',
              poiPrice: item['poiPrice']?.toString() ?? '',
              poiPhone: item['poiPhone']?.toString() ?? '',
              poiTag: item['poiTag']?.toString() ?? '',
              poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
              poiRating: item['poiRating']?.toString() ?? '',
              poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
              poiDescription: item['poiDescription']?.toString() ?? '',
              poiLatitude: item['poiLatitude']?.toDouble() ?? '',
              poiLongitude: item['poiLongitude']?.toDouble() ?? '',
              imageUrl: item['imageUrl']?.toString() ?? '',
            ));
          }
          // Update the UI
          setState(() {});
        }
      } else {
        // Handle error, e.g., print an error message
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }

  Future<void> retrievePoiIDs() async {
    try {
      // Retrieve all trips for the current userID
      final tripQuerySnapshot = await FirebaseFirestore.instance
          .collection('trip')
          .where('userID', isEqualTo: userID)
          .get();

      for (final tripDoc in tripQuerySnapshot.docs) {
        final tripID = tripDoc.id;

        // Retrieve all days for the current trip
        final dayQuerySnapshot = await FirebaseFirestore.instance
            .collection('day')
            .where('tripID', isEqualTo: tripID)
            .get();

        for (final dayDoc in dayQuerySnapshot.docs) {
          final dayID = dayDoc.id;

          // Retrieve all activities for the current day
          final activityQuerySnapshot = await FirebaseFirestore.instance
              .collection('activity')
              .where('dayID', isEqualTo: dayID)
              .get();

          for (final activityDoc in activityQuerySnapshot.docs) {
            // Ensure activityRating is treated as a double
            final activityRating = double.tryParse(activityDoc['activityRating']);

            if (activityRating != null && activityRating > 4.0) {
              final poiID = activityDoc['poiID'];

              // Store poiID in a list
              if (!poiIDList.contains(poiID)) {
                poiIDList.add(poiID);
              }
            }
          }
        }
      }

      print('Retrieved poiIDs: $poiIDList');
    } catch (e) {
      print('Error retrieving poiIDs: $e');
    }
  }



  Future<List<POI>> retrievePoiDetails(List<String> poiIDList) async {
    List<POI> poiDetailsList = [];

    try {
      for (final poiID in poiIDList) {
        final poiDetails = await searchPointsOfInterestById(poiID);

        // Add POI details to the list
        poiDetailsList.add(poiDetails);
      }

      // Now, poiDetailsList contains the POI details corresponding to the poiIDs
      return poiDetailsList;
    } catch (e) {
      print('Error retrieving POI details: $e');
      return [];
    }
  }

  Future<POI> searchPointsOfInterestById(String poiID) async {
    try {
      final response = await http.get(Uri.parse('http://34.124.197.131:5000/get_poi_based_on_id?query=$poiID'));

      if (response.statusCode == 200) {
        List<dynamic> responseDataList = json.decode(response.body);

        if (responseDataList.isNotEmpty) {
          dynamic responseData = responseDataList[0];

          if (responseData is Map<String, dynamic>) {
            return POI(
              poiID: responseData['poiID']?.toString() ?? '',
              poiType: responseData['poiType']?.toString() ?? '',
              poiName: responseData['poiName']?.toString() ?? '',
              poiAddress: responseData['poiAddress']?.toString() ?? '',
              poiLocation: responseData['poiLocation']?.toString() ?? '',
              poiUrl: responseData['poiUrl']?.toString() ?? '',
              poiPriceRange: responseData['poiPriceRange']?.toString() ?? '',
              poiPrice: responseData['poiPrice']?.toString() ?? '',
              poiPhone: responseData['poiPhone']?.toString() ?? '',
              poiTag: responseData['poiTag']?.toString() ?? '',
              poiOperatingHours: responseData['poiOperatingHours']?.toString() ?? '',
              poiRating: responseData['poiRating']?.toString() ?? '',
              poiNoOfReviews: responseData['poiNoOfReviews']?.toString() ?? '',
              poiDescription: responseData['poiDescription']?.toString() ?? '',
              poiLatitude: responseData['poiLatitude']?.toDouble() ?? 0.0,
              poiLongitude: responseData['poiLongitude']?.toDouble() ?? 0.0,
              imageUrl: '',
            );

          } else {
            print('Unexpected response format. First element is not a map: $responseData');
          }
        } else {
          print('Unexpected response format. Empty list.');
        }
      } else {
        print('Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data from database: $e');
    }

    // Return an empty POI object if there's an error
    return POI(
      poiID: '',
      poiType: '',
      poiName: '',
      poiAddress: '',
      poiLocation: '',
      poiUrl: '',
      poiPriceRange: '',
      poiPrice: '',
      poiPhone: '',
      poiTag: '',
      poiOperatingHours: '',
      poiRating: '',
      poiNoOfReviews: '',
      poiDescription: '',
      poiLatitude: 0.0,
      poiLongitude: 0.0,
      imageUrl: '',
    );
  }

  Future<void> fetchAttractionContentBased(String poiName) async {
    try {
      final response = await http.get(
          Uri.parse('http://34.124.197.131:5000/recommend_attraction_content_based?poiName=$poiName'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);

        if (dataMap.containsKey('error')) {
          print('Error: ${dataMap['error']}');
        } else if (dataMap.containsKey('content_based_attractions')) {
          final List<dynamic> dataList = dataMap['content_based_attractions'];

          for (var item in dataList) {
            if (item != null) {
              await fetchImageForPOIString(item); // Fetch image for each POI
              contentBasedListAttractions.add(POI(
                poiID: item['poiID']?.toString() ?? '',
                poiType: item['poiType']?.toString() ?? '',
                poiName: item['poiName']?.toString() ?? '',
                poiAddress: item['poiAddress']?.toString() ?? '', // Add null check for other properties
                poiLocation: item['poiLocation']?.toString() ?? '',
                poiUrl: item['poiUrl']?.toString() ?? '',
                poiPriceRange: item['poiPriceRange']?.toString() ?? '',
                poiPrice: item['poiPrice']?.toString() ?? '',
                poiPhone: item['poiPhone']?.toString() ?? '',
                poiTag: item['poiTag']?.toString() ?? '',
                poiOperatingHours: item['poiOperatingHours']?.toString() ?? '',
                poiRating: item['poiRating']?.toString() ?? '',
                poiNoOfReviews: item['poiNoOfReviews']?.toString() ?? '',
                poiDescription: item['poiDescription']?.toString() ?? '',
                poiLatitude: item['poiLatitude']?.toDouble() ?? 0.0,
                poiLongitude: item['poiLongitude']?.toDouble() ?? 0.0,
                imageUrl: item['imageUrl']?.toString() ?? '',
              ));
            }
          }

          // Update the UI
          setState(() {});
        } else {
          print('Invalid JSON format: missing expected key');
        }
      } else {
        // Handle error, e.g., print an error message
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }

  Future<void> fetchRestaurantContentBased(String poiName) async {
    try {
      final response = await http.get(
          Uri.parse('http://34.124.197.131:5000/recommend_restaurant_content_based?poiName=$poiName'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = json.decode(response.body);

        if (dataMap.containsKey('error')) {
          print('Error: ${dataMap['error']}');
        } else if (dataMap.containsKey('content_based_restaurants')) {
          final List<dynamic> dataList = dataMap['content_based_restaurants'];

          for (var item in dataList) {
            if (item != null) {
              await fetchImageForPOIString(item); // Fetch image for each POI
              contentBasedListRestaurant.add(POI(
                poiID: item['poiID']?.toString() ?? '',
                poiType: item['poiType']?.toString() ?? '',
                poiName: item['poiName']?.toString() ?? '',
                poiAddress: '',
                poiLocation: '',
                poiUrl: '',
                poiPriceRange: '',
                poiPrice: item['poiPrice']?.toString() ?? '',
                poiPhone: '',
                poiTag: item['poiTag']?.toString() ?? '',
                poiOperatingHours: '',
                poiRating: item['poiRating']?.toString() ?? '',
                poiNoOfReviews: '',
                poiDescription: '',
                poiLatitude: 0.0,
                poiLongitude: 0.0,
                imageUrl: item['imageUrl']?.toString() ?? '',
              ));
            }
          }

          // Update the UI
          setState(() {});

        } else {
          print('Invalid JSON format: missing expected key');
        }
      } else {
        // Handle error, e.g., print an error message
        print('Failed to fetch JSON data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading POIs from JSON: $e');
    }
  }

  Future<void> fetchContentBasedListForAttractions() async {
    try {
      // Retrieve poi details for the poiIDList
      final poiDetailsList = await retrievePoiDetails(poiIDList);

      // Filter out attractions
      final attractionDetailsList =
      poiDetailsList.where((poi) => poi.poiType == 'Attraction').toList();

      // Call fetchRestaurantContentBased for each restaurant
      for (final poiDetails in attractionDetailsList) {
        await fetchAttractionContentBased(poiDetails.poiName);
      }

      // Update the UI
      setState(() {});
    } catch (e) {
      print('Error fetching contentBasedList for attractions: $e');
    }
  }

  Future<void> fetchContentBasedListForRestaurants() async {
    try {
      // Retrieve poi details for the poiIDList
      final poiDetailsList = await retrievePoiDetails(poiIDList);

      // Filter out restaurants
      final restaurantDetailsList =
      poiDetailsList.where((poi) => poi.poiType == 'Restaurant').toList();

      // Call fetchRestaurantContentBased for each restaurant
      for (final poiDetails in restaurantDetailsList) {
        await fetchRestaurantContentBased(poiDetails.poiName);
      }

      // Update the UI
      setState(() {});
    } catch (e) {
      print('Error fetching contentBasedList for restaurants: $e');
    }
  }
}