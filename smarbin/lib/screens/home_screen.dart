import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smarbin/screens/signin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {}; // Added set of polylines
  String _fillStatus = "";
  String _fillStatusB = "";
  double _latA = 0.0;
  double _lngA = 0.0;
  double _latB = 0.0;
  double _lngB = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            myLocationEnabled: true,
            initialCameraPosition: CameraPosition(
              target: LatLng(27.7343226, 85.3161379),
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: {..._markers},
            polylines: _polylines, // Added polylines to GoogleMap widget
            onTap: (LatLng latLng) {
              print(
                  'Tapped location - Latitude: ${latLng.latitude}, Longitude: ${latLng.longitude}');
              print('A loc: ${_latA} ${_lngA}');
              print('B loc: ${_latB} ${_lngB}');

              double distanceToA = calculateDistance(
                  latLng.latitude, latLng.longitude, _latA, _lngA);
              double distanceToB = calculateDistance(
                  latLng.latitude, latLng.longitude, _latB, _lngB);

              if (distanceToA < distanceToB) {
                print('Dustbin A is closer to the user.');
                _showDistanceDialog();
              } else if (distanceToB < distanceToA) {
                print('Dustbin B is closer to the user.');
                _showDistanceDialogB();
              } else {
                print(
                    'Both Dustbin A and Dustbin B are at the same distance from the user.');
              }
              // _showDistanceDialog();
              // _showDistanceDialogB();
            },
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _goToUserLocation,
              child: Icon(Icons.my_location),
            ),
          ),
          Center(
            child: ElevatedButton(
              child: const Text("Logout"),
              onPressed: () {
                FirebaseAuth.instance.signOut().then((value) {
                  print("Signed Out");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInScreen()),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToUserLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(_latA, _lngA),
        zoom: 15,
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    fetchAndListenToLocationUpdates();
    fetchAndListenToLocationUpdatesB();
  }

  void fetchAndListenToLocationUpdates() async {
    FirebaseFirestore.instance
        .collection('Dustbin_A')
        .doc('GPS')
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        _latA = snapshot['lat'];
        _lngA = snapshot['lng'];
        updateMarker(_latA, _lngA);
      }
    });
  }

  void fetchAndListenToLocationUpdatesB() async {
    FirebaseFirestore.instance
        .collection('Dustbin_B')
        .doc('GPS_B')
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        _latB = snapshot['latB'];
        _lngB = snapshot['lngB'];
        updateMarkerB(_latB, _lngB);
      }
    });
  }

  void updateMarker(double lat, double lng) async {
    final GoogleMapController controller = await _controller.future;
    LatLng newPosition = LatLng(lat, lng);

    BitmapDescriptor markerIcon = getMarkerIcon();

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId("location"),
          position: newPosition,
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: 'Dustbin_A',
            snippet: 'Tap to see Dustbin Status',
          ),
        ),
      );
    });

    controller.animateCamera(CameraUpdate.newLatLng(newPosition));
  }

  void updateMarkerB(double lat, double lng) async {
    final GoogleMapController controller = await _controller.future;
    LatLng newPosition = LatLng(lat, lng);

    BitmapDescriptor markerIconB = getMarkerIconB();

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId("locationB"),
          position: newPosition,
          icon: markerIconB,
          infoWindow: InfoWindow(
            title: 'Dustbin_B',
            snippet: 'Tap to see Dustbin B Status',
          ),
        ),
      );
    });

    controller.animateCamera(CameraUpdate.newLatLng(newPosition));
    _drawPolyline(); // Draw polyline after updating marker B
  }

  BitmapDescriptor getMarkerIcon() {
    switch (_fillStatus) {
      case "Empty":
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case "Partially filled":
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  BitmapDescriptor getMarkerIconB() {
    switch (_fillStatusB) {
      case "Empty":
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case "Partially filled":
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  void _showDistanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Dustbin A Status"),
          content: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Dustbin_A')
                .doc('UltraSonic_A')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }

              var data = snapshot.data;
              if (data == null ||
                  !data.exists ||
                  (data.data() as Map<String, dynamic>)['Constant_A'] == null ||
                  (data.data() as Map<String, dynamic>)['Distance1'] == null ||
                  (data.data() as Map<String, dynamic>)['Distance2'] == null) {
                return Text("Dustbin A status not available");
              }

              var constantA =
                  (data.data() as Map<String, dynamic>)['Constant_A'];
              var distance1 =
                  (data.data() as Map<String, dynamic>)['Distance1'];
              var distance2 =
                  (data.data() as Map<String, dynamic>)['Distance2'];

              var distanceA = (distance1 + distance2) / 2;

              if (distanceA <= constantA / 3) {
                _fillStatus = "Empty";
              } else if (distanceA > constantA / 3 &&
                  distanceA <= (2 * constantA) / 3) {
                _fillStatus = "Partially filled";
              } else {
                _fillStatus = "Full";
              }

              updateMarker(_latA, _lngA);

              return Text("Dustbin A Status: $_fillStatus");
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showDistanceDialogB() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Dustbin B Status"),
          content: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Dustbin_B')
                .doc('UltraSonic_B')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }

              var data = snapshot.data;
              if (data == null ||
                  !data.exists ||
                  (data.data() as Map<String, dynamic>)['Constant_B'] == null ||
                  (data.data() as Map<String, dynamic>)['Distance3'] == null ||
                  (data.data() as Map<String, dynamic>)['Distance4'] == null) {
                return Text("Dustbin B status not available");
              }

              var constantB =
                  (data.data() as Map<String, dynamic>)['Constant_B'];
              var distance3 =
                  (data.data() as Map<String, dynamic>)['Distance3'];
              var distance4 =
                  (data.data() as Map<String, dynamic>)['Distance4'];

              var distanceB = (distance3 + distance4) / 2;

              if (distanceB <= constantB / 3) {
                _fillStatusB = "Empty";
              } else if (distanceB > constantB / 3 &&
                  distanceB <= (2 * constantB) / 3) {
                _fillStatusB = "Partially filled";
              } else {
                _fillStatusB = "Full";
              }

              updateMarkerB(_latB, _lngB);

              return Text("Dustbin B Status: $_fillStatusB");
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _drawPolyline() {
    setState(() {
      _polylines.clear();
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        visible: true,
        points: [
          LatLng(_latA, _lngA),
          LatLng(_latB, _lngB),
        ],
        color: Colors.blue,
        width: 3,
      ));
    });
  }
}

double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  double dLat = degreesToRadians(lat2 - lat1);
  double dLon = degreesToRadians(lon2 - lon1);

  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(degreesToRadians(lat1)) *
          cos(degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return 6371.0 * c;
}
