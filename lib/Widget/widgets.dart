import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

const List<String> statesOfMalaysia = [
  'Johor',
  'Kedah',
  'Kelantan',
  'Kuala Lumpur',
  'Labuan',
  'Melaka',
  'Negeri Sembilan',
  'Pahang',
  'Perak',
  'Perlis',
  'Penang',
  'Putrajaya',
  'Sabah',
  'Sarawak',
  'Selangor',
  'Terengganu',
];

void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}