import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double? height; // Make the height optional
  final double? width; // Make the width optional

  MapView({required this.latitude, required this.longitude, this.height, this.width});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: widget.height ?? MediaQuery.of(context).size.height * 0.3,
        width: widget.width ?? MediaQuery.of(context).size.width, // Default to full width
        child: GoogleMap(
          onMapCreated: (controller) {
            setState(() {
              mapController = controller;
            });
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.latitude, widget.longitude),
            zoom: 15.0,
          ),
          markers: Set<Marker>.from([
            Marker(
              markerId: MarkerId('poi_marker'),
              position: LatLng(widget.latitude, widget.longitude),
              infoWindow: InfoWindow(
                title: 'POI Location',
                snippet: 'This is your Point of Interest',
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
