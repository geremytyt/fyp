
import 'package:flutter/material.dart';
import 'package:my_travel_mate/Staff/recommendationReport.dart';
import 'package:my_travel_mate/Staff/salesReport.dart';

import 'demographicReport.dart';

class ReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Report Page'),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: GridView.count(
        crossAxisCount: 2, // Set to 2 columns for the first row
        crossAxisSpacing: 16.0, // Adjust spacing as needed
        mainAxisSpacing: 16.0, // Adjust spacing as needed
        childAspectRatio: 1.5, // Adjust aspect ratio to control the height of the icons
        children: [
          ReportIcon(
            icon: Icons.person,
            label: 'Demographic Report',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DemographicPage()),
              );
            },
          ),
          // ReportIcon(
          //   icon: Icons.point_of_sale_sharp,
          //   label: 'Ticket Sales',
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => SalesReportPage()),
          //     );
          //   },
          // ),
          ReportIcon(
            icon: Icons.star,
            label: 'Accuracy Report',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecommendationPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}




class ReportIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ReportIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50),
          SizedBox(height: 10),
          Text(label),
        ],
      ),
    );
  }
}
