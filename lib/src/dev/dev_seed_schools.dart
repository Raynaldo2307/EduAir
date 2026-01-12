// lib/src/dev/dev_seed_schools.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedTestSchools() async {
  final db = FirebaseFirestore.instance;

  final schools = [
    {
      'id': 'stony_hill_heart',
      'data': {
        'name': 'Stony Hill HEART Academy',
        'lat': 18.0827,
        'lng': -76.7905,
        'radiusMeters': 150.0,
        'timezone': 'America/Jamaica',
      },
    },
    {
      'id': 'kingston_high',
      'data': {
        'name': 'Kingston High School',
        'lat': 17.9770,
        'lng': -76.7936,
        'radiusMeters': 200.0,
        'timezone': 'America/Jamaica',
      },
    },
    {
      'id': 'montego_bay_high',
      'data': {
        'name': 'Montego Bay High School',
        'lat': 18.4716,
        'lng': -77.9188,
        'radiusMeters': 220.0,
        'timezone': 'America/Jamaica',
      },
    },
    {
      'id': 'spanish_town_high',
      'data': {
        'name': 'Spanish Town High School',
        'lat': 17.9937,
        'lng': -76.9574,
        'radiusMeters': 200.0,
        'timezone': 'America/Jamaica',
      },
    },
    {
      'id': 'manchester_high',
      'data': {
        'name': 'Manchester High School',
        'lat': 18.0500,
        'lng': -77.5000,
        'radiusMeters': 200.0,
        'timezone': 'America/Jamaica',
      },
    },
    {
      'id': 'clarendon_college',
      'data': {
        'name': 'Clarendon College',
        'lat': 18.0530,
        'lng': -77.2440,
        'radiusMeters': 220.0,
        'timezone': 'America/Jamaica',
      },
    },
    {
      'id': 'campion_college',
      'data': {
        'name': 'Campion College',
        'lat': 18.0203,
        'lng': -76.7500,
        'radiusMeters': 180.0,
        'timezone': 'America/Jamaica',
      },
    },
    {
      'id': 'port_of_spain_college',
      'data': {
        'name': 'Port of Spain College',
        'lat': 10.6600,
        'lng': -61.5160,
        'radiusMeters': 220.0,
        'timezone': 'America/Port_of_Spain',
      },
    },
  ];

  final batch = db.batch();

  for (final school in schools) {
    final id = school['id'] as String;
    final data = school['data'] as Map<String, dynamic>;
    final docRef = db.collection('schools').doc(id);
    batch.set(docRef, data, SetOptions(merge: true));
  }

  await batch.commit();
  // print('✅ Seeded ${schools.length} schools');
}