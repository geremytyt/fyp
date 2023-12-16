import 'package:flutter/material.dart';

class SearchBarFunction extends StatelessWidget {
  final VoidCallback onTap;

  SearchBarFunction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.search),
            SizedBox(width: 8.0),
            Expanded(
              child: Text(
                'Search...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
