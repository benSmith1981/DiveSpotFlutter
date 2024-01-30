import 'package:flutter/material.dart';
import 'fish.dart';
class FishDetailsWidget extends StatelessWidget {
  final Fish fish;

  FishDetailsWidget({required this.fish});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Name: ${fish.name}', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Species: ${fish.species}'),
            Text('Description: ${fish.description}'),
            Text('Location: ${fish.location}'),
            Text('Endangered: ${fish.endangered}'),
            // Add any other fields here
            // Example:
            // Text('Habitat: ${fish.habitat}'),
            // Text('Size: ${fish.size}'),
          ],
        ),
      ),
    );
  }
}
