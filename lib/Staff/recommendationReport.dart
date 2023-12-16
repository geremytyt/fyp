import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecommendationPage extends StatefulWidget {
  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  late CollectionReference<Map<String, dynamic>> _recommendationsCollection;

  @override
  void initState() {
    super.initState();
    _recommendationsCollection = FirebaseFirestore.instance.collection('recommendation');
  }

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Factor Accuracy Report'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final pickedStartDate = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now(),
                    );

                    if (pickedStartDate != null && pickedStartDate != _startDate) {
                      setState(() {
                        _startDate = pickedStartDate;
                      });
                    }
                  },
                  child: Text('Select Start Date'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pickedEndDate = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2022),
                      lastDate: DateTime.now(),
                    );

                    if (pickedEndDate != null && pickedEndDate != _endDate) {
                      setState(() {
                        _endDate = pickedEndDate;
                      });
                    }
                  },
                  child: Text('Select End Date'),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Recommendation Factor Accuracy Report\n'
                  'between\n ${_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'N/A'} and ${_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'N/A'}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _getFilteredRecommendationsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              final recommendations = snapshot.data?.docs ?? [];
              final groupedRecommendations = _groupRecommendations(recommendations);

              return DataTable(
                columns: [
                  DataColumn(
                    label: Container(
                      constraints: BoxConstraints(maxWidth: 90),
                      child: Text(
                        'Factor',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      constraints: BoxConstraints(maxWidth: 50),
                      child: Text(
                        'Total',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      constraints: BoxConstraints(maxWidth: 120),
                      child: Text(
                        'Average Rating',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                rows: groupedRecommendations.map((group) {
                  final recommendationFactor = group['recommendationFactor'];
                  final totalOccurrences = group['totalOccurrences'];
                  final averageRating = group['averageRating'];

                  return DataRow(
                    cells: [
                      DataCell(
                        Flexible(
                          child: Text(recommendationFactor, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(
                        Flexible(
                          child: Text(totalOccurrences.toString(), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(
                        Flexible(
                          child: Text(averageRating.toStringAsFixed(2), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getFilteredRecommendationsStream() {
    // Ensure that _startDate and _endDate are not null before applying the filter
    if (_startDate != null && _endDate != null) {
      final formattedStartDate = DateFormat('yyyy-MM-dd').format(_startDate!);
      final formattedEndDate = DateFormat('yyyy-MM-dd').format(_endDate!);

      return _recommendationsCollection
          .where('recommendationDate', isGreaterThanOrEqualTo: formattedStartDate)
          .where('recommendationDate', isLessThanOrEqualTo: formattedEndDate)
          .snapshots();
    } else {
      return _recommendationsCollection.snapshots();
    }
  }

  List<Map<String, dynamic>> _groupRecommendations(List<DocumentSnapshot<Map<String, dynamic>>> recommendations) {
    final groupedMap = <String, Map<String, dynamic>>{};

    for (final recommendation in recommendations) {
      final data = recommendation.data()!;
      final recommendationFactor = data['recommendationFactor'];

      // Convert 'recommendationRating' from string to double
      final rating = double.tryParse(data['recommendationRating']) ?? 0.0;

      if (!groupedMap.containsKey(recommendationFactor)) {
        groupedMap[recommendationFactor] = {
          'recommendationFactor': recommendationFactor,
          'totalOccurrences': 0,
          'totalRating': 0.0,
        };
      }

      groupedMap[recommendationFactor]!['totalOccurrences']++;
      groupedMap[recommendationFactor]!['totalRating'] += rating;
    }

    return groupedMap.values.toList()
      ..forEach((group) {
        final totalRating = group['totalRating'];
        final totalOccurrences = group['totalOccurrences'];
        group['averageRating'] = totalOccurrences > 0 ? totalRating / totalOccurrences : 0.0;
      });
  }
}
