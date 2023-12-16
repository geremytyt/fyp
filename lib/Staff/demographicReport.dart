import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demographic Data',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DemographicPage(),
    );
  }
}

class DemographicPage extends StatefulWidget {
  @override
  _DemographicPageState createState() => _DemographicPageState();
}

class _DemographicPageState extends State<DemographicPage> {
  Map<String, dynamic>? demographicData;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
          Uri.parse('http://34.124.197.131:5000/get_demographic_report_data'));

      if (response.statusCode == 200) {
        // Decode the response body as JSON
        Map<String, dynamic>? decodedData = json.decode(
            utf8.decode(response.bodyBytes));

        setState(() {
          // Store the decoded JSON data
          demographicData = decodedData;
        });
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to load demographic data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Demographic Report'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Center(
        child: demographicData == null
            ? CircularProgressIndicator()
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Text(
                'Gender Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                width: 300.0, // Adjust the width as needed
                height: 250.0, // Adjust the height as needed
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.blue,
                        value: demographicData!['gender_data']['male_percentage']
                            .toDouble(),
                        title: 'Male',

                      ),
                      PieChartSectionData(
                        color: Colors.pink,
                        value: demographicData!['gender_data']['female_percentage']
                            .toDouble(),
                        title: 'Female',
                        // Display female percentage when hovered
                        // onTooltipShow: (tooltip) => 'Female: ${demographicData!['gender_data']['total_female']}',
                      ),
                    ],
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              Text('Male: ${demographicData!['gender_data']['total_male']}'),
              Text('Female: ${demographicData!['gender_data']['total_female']}'),
              SizedBox(height: 40),
              Text(
                'Age Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Container(
                width: 300.0, // Adjust the width as needed
                height: 300.0, // Adjust the height as needed
                child: BarChart(
                  BarChartData(
                    groupsSpace: 12,
                    barGroups: demographicData!['age_data'].keys.map<BarChartGroupData>((ageCategory) {
                      return BarChartGroupData(
                        x: _getXValue(ageCategory),
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            fromY: 0,
                            toY: demographicData!['age_data'][ageCategory].toDouble(),
                            color: Colors.blue,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  int _getXValue(String ageCategory) {
    // Manually list out the x-axis values for each age category
    switch (ageCategory) {
      case '0-18':
        return 0;
      case '19-25':
        return 1;
      case '26-35':
        return 2;
      case '36-45':
        return 3;
      case '46-55':
        return 4;
      case '56-65':
        return 5;
      case '66+':
        return 6;
      default:
        return 0;
    }
  }

  String _getAgeCategory(int xValue) {
    // Convert the numeric x-axis value back to the age category
    switch (xValue) {
      case 0:
        return '0-18';
      case 1:
        return '19-25';
      case 2:
        return '26-35';
      case 3:
        return '36-45';
      case 4:
        return '46-55';
      case 5:
        return '56-65';
      case 6:
        return '66+';
      default:
        return '';
    }
  }
}

