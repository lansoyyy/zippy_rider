import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zippy/screens/pages/profile_page.dart';
import 'package:zippy/screens/tabs/history_tab.dart';
import 'package:zippy/screens/tabs/sales_tab.dart';
import 'package:zippy/utils/colors.dart';
import 'package:zippy/utils/const.dart';
import 'package:zippy/utils/my_location.dart';
import 'package:zippy/widgets/button_widget.dart';
import 'package:zippy/widgets/text_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? userData;

  String? riderName;
  File? _image;
  String? profileImage;
  String? merchantId;
  int orderCount = 0;
  double totalEarned = 0.0;

  late Polyline _poly = const Polyline(polylineId: PolylineId('new'));
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  bool isPickedUp = false;
  bool isPickedUpUser = false;
  bool hasLoaded = false;
  bool hasAccepted = false;

  double mylat = 0;
  double mylng = 0;

  Set<Marker> markers = {};
  Timer? _timer;

  String orderId = '';
  String driverId = 'I7FTuyOuTNeo0xkCNjxfT0NBWxF3';

  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    determinePosition();
    fetchUserData();
    getCurrentLocation();
  }

  @override
  void dispose() {
    mapController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('Riders').doc(user?.uid);

      userDoc.snapshots().listen((docSnapshot) {
        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          setState(() {
            userData = data;
            profileImage = data['profileImage'];
          });
        }
      });
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void getCurrentLocation() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .then((value) async {
        await FirebaseFirestore.instance
            .collection('Riders')
            .doc(driverId)
            .update({
          'lat': value.latitude,
          'lng': value.longitude,
        });
        setState(() {
          mylat = value.latitude;
          mylng = value.longitude;
          hasLoaded = true;
        });
      });
    });
  }

  void plotPolylines(double merchantLat, double merchantLng) async {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .then((value) async {
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          kGoogleApiKey,
          PointLatLng(value.latitude, value.longitude),
          PointLatLng(merchantLat, merchantLng),
        );

        if (result.points.isNotEmpty) {
          polylineCoordinates = result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        }

        mapController?.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(value.latitude, value.longitude), 18.0));
        setState(() {
          markers.clear();
          _poly = Polyline(
            color: primary,
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            width: 4,
          );

          mylat = value.latitude;
          mylng = value.longitude;

          markers.add(Marker(
            draggable: true,
            icon: BitmapDescriptor.defaultMarker,
            markerId: const MarkerId("pickup"),
            position: LatLng(merchantLat, merchantLng),
            infoWindow: const InfoWindow(title: "Merchant's Location"),
          ));
        });
      });
    });
  }

  void plotPolylinesUser(double userLat, double userLng) async {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .then((value) async {
        PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          kGoogleApiKey,
          PointLatLng(value.latitude, value.longitude),
          PointLatLng(userLat, userLng),
        );

        if (result.points.isNotEmpty) {
          polylineCoordinates = result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        }

        mapController?.animateCamera(CameraUpdate.newLatLngZoom(
            LatLng(value.latitude, value.longitude), 18.0));
        setState(() {
          markers.clear();
          _poly = Polyline(
            color: Colors.red,
            polylineId: const PolylineId('route'),
            points: polylineCoordinates,
            width: 4,
          );

          mylat = value.latitude;
          mylng = value.longitude;

          markers.add(Marker(
            draggable: true,
            icon: BitmapDescriptor.defaultMarker,
            markerId: const MarkerId("pickup"),
            position: LatLng(userLat, userLng),
            infoWindow: const InfoWindow(title: "User's Location"),
          ));
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: hasLoaded
          ? Stack(
              children: [
                Expanded(
                  child: GoogleMap(
                    polylines: {_poly},
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    markers: markers,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(mylat, mylng),
                      zoom: 14.4746,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                      _controller.complete(controller);
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.25,
                  decoration: const BoxDecoration(
                    color: secondary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(
                        40,
                      ),
                      bottomRight: Radius.circular(
                        40,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 25, left: 15, right: 15),
                        child: SafeArea(
                            child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('Riders')
                                    .doc(_auth.currentUser?.uid)
                                    .snapshots(),
                                builder: (context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()));
                                  } else if (snapshot.hasError) {
                                    return const Center(
                                        child: Text('Something went wrong'));
                                  } else if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()));
                                  }

                                  final data = snapshot.data!.data()
                                      as Map<String, dynamic>?;

                                  if (data == null) {
                                    return const Center(
                                        child: Text('No data found.'));
                                  }
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: 300,
                                        child: TextWidget(
                                          align: TextAlign.start,
                                          text:
                                              'Good day! Rider ${data['name']}',
                                          fontSize: 20,
                                          fontFamily: 'Bold',
                                          color: Colors.white,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const ProfilePage()),
                                          );
                                        },
                                        child: CircleAvatar(
                                          maxRadius: 25,
                                          minRadius: 25,
                                          backgroundImage: data[
                                                      'profileImage'] !=
                                                  null
                                              ? NetworkImage(profileImage ??
                                                  'https://cdn-icons-png.flaticon.com/256/149/149071.png')
                                              : const NetworkImage(
                                                  'https://cdn-icons-png.flaticon.com/256/149/149071.png'),
                                        ),
                                      ),
                                    ],
                                  );
                                })),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 15, right: 15, top: 15),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                GestureDetector(
                                    onTap: () {},
                                    child: _buildCravingOption(
                                        Icons.home, 'Home', true)),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const SalesTab()),
                                    );
                                  },
                                  child: _buildCravingOption(
                                      Icons.add_chart_rounded, 'Sales', false),
                                ),
                                GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const HistoryScreen()),
                                      );
                                    },
                                    child: _buildCravingOption(
                                        Icons.history, 'History', false)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          20,
                        ),
                        topRight: Radius.circular(
                          20,
                        ),
                      ),
                      color: Colors.white,
                    ),
                    child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: hasAccepted
                            ? StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('Orders')
                                    .doc(orderId)
                                    .snapshots(),
                                builder: (context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()));
                                  } else if (snapshot.hasError) {
                                    return const Center(
                                        child: Text('Something went wrong'));
                                  } else if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()));
                                  }

                                  final userData = snapshot.data!.data()
                                      as Map<String, dynamic>?;

                                  if (userData == null) {
                                    return const Center(
                                        child: Text('No data found.'));
                                  }
                                  return ButtonWidget(
                                    color: userData['status'] == 'On the way'
                                        ? Colors.green
                                        : secondary,
                                    label: userData['status'] == 'On the way'
                                        ? 'Mark as Completed'
                                        : userData['status'] == 'For Pick-up'
                                            ? 'Order Picked Up'
                                            : 'Preparing Food...',
                                    onPressed: () async {
                                      if (userData['status'] == 'For Pick-up') {
                                        await FirebaseFirestore.instance
                                            .collection('Orders')
                                            .doc(orderId)
                                            .update({'status': 'On the way'});

                                        final user = await FirebaseFirestore
                                            .instance
                                            .collection('Users')
                                            .doc(userData['userId'])
                                            .get();
                                        plotPolylinesUser(
                                            userData['isHome']
                                                ? user['homeLat']
                                                : user['officeLat'],
                                            userData['isHome']
                                                ? user['homeLng']
                                                : user['officeLng']);
                                        setState(() {
                                          _timer!.cancel();
                                        });
                                      } else if (userData['status'] ==
                                          'On the way') {
                                        await FirebaseFirestore.instance
                                            .collection('Orders')
                                            .doc(orderId)
                                            .update({
                                          'status': 'Delivered',
                                          'completedAt':
                                              FieldValue.serverTimestamp()
                                        }).whenComplete(
                                          () async {
                                            await FirebaseFirestore.instance
                                                .collection('Riders')
                                                .doc(driverId)
                                                .update({
                                              'isActive': true
                                            }).whenComplete(
                                              () {
                                                Navigator.of(context)
                                                    .pushAndRemoveUntil(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const HomeScreen(),
                                                  ),
                                                  (route) {
                                                    return true;
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        );
                                      }
                                    },
                                  );
                                })
                            : ButtonWidget(
                                color: secondary,
                                label: 'Search Bookings',
                                onPressed: () {
                                  showOrderListDialog();
                                },
                              )),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(
                color: secondary,
              ),
            ),
    );
  }

  showOrderListDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Orders')
                      .where('driverId', isEqualTo: driverId)
                      .where('status', isEqualTo: 'For Pick-up')
                      .snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: Text('Loading'));
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('Something went wrong'));
                    } else if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final orders = snapshot.data!.docs;

                    if (orders.isEmpty) {
                      return const Center(child: Text('No bookings found.'));
                    }

                    return SizedBox(
                      height: 300,
                      width: 500,
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          var order = orders[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                                left: 5, right: 5, bottom: 5, top: 5),
                            child: GestureDetector(
                              onTap: () {
                                showOrderDialog(order);
                              },
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.13,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: secondary),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        maxLines: 2,
                                        text: '${order['merchantName']}',
                                        fontSize: 14,
                                        fontFamily: 'Bold',
                                        color: secondary,
                                      ),
                                      TextWidget(
                                        text:
                                            '₱${order['total'].toStringAsFixed(2)}',
                                        fontSize: 22,
                                        fontFamily: 'Medium',
                                        color: Colors.black,
                                      ),
                                      StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('Users')
                                              .doc(order['userId'])
                                              .snapshots(),
                                          builder: (context,
                                              AsyncSnapshot<DocumentSnapshot>
                                                  snapshot) {
                                            if (!snapshot.hasData) {
                                              return const Center(
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator()));
                                            } else if (snapshot.hasError) {
                                              return const Center(
                                                  child: Text(
                                                      'Something went wrong'));
                                            } else if (snapshot
                                                    .connectionState ==
                                                ConnectionState.waiting) {
                                              return const Center(
                                                  child: Center(
                                                      child:
                                                          CircularProgressIndicator()));
                                            }

                                            final userData =
                                                snapshot.data!.data()
                                                    as Map<String, dynamic>?;

                                            if (userData == null) {
                                              return const Center(
                                                  child:
                                                      Text('No data found.'));
                                            }
                                            return TextWidget(
                                              maxLines: 1,
                                              text: order['isHome']
                                                  ? '${userData['homeAddress']}'
                                                  : '${userData['officeAddress']}',
                                              fontSize: 12,
                                              fontFamily: 'Bold',
                                              align: TextAlign.start,
                                              color: Colors.black,
                                            );
                                          }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
            ],
          ),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
              decoration: BoxDecoration(
                  border: Border.all(color: secondary, width: 1),
                  borderRadius: BorderRadius.circular(10)),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: TextWidget(
                  text: 'Close',
                  fontSize: 18,
                  color: black,
                  fontFamily: "Medium",
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  showOrderDialog(dynamic randomOrder) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                TextWidget(
                    text: "Food Delivery",
                    fontSize: 25,
                    fontFamily: "Bold",
                    color: secondary),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                          text: "Reference Code: ",
                          fontSize: 18,
                          fontFamily: "Bold",
                          color: black),
                      TextWidget(
                          text: '${randomOrder.id ?? 'N/A'}',
                          fontSize: 20,
                          fontFamily: "Bold",
                          color: secondary),
                      const Divider(
                        color: secondary,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                          text: "Shop: ",
                          fontSize: 18,
                          fontFamily: "Bold",
                          color: black),
                      TextWidget(
                          text: '${randomOrder?['merchantName'] ?? 'N/A'}',
                          fontSize: 20,
                          fontFamily: "Bold",
                          color: secondary),
                      const Divider(
                        color: secondary,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextWidget(
                          text: "Address: ",
                          fontSize: 18,
                          fontFamily: "Bold",
                          color: black),
                      TextWidget(
                          align: TextAlign.start,
                          text: '${randomOrder?['deliveryAdd'] ?? 'N/A'}',
                          fontSize: 20,
                          fontFamily: "Bold",
                          color: secondary),
                      const Divider(
                        color: secondary,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextWidget(
                          text: "Order List: ",
                          fontSize: 23,
                          fontFamily: "Bold",
                          color: secondary),
                      Column(
                        children: randomOrder?['items'] != null
                            ? (randomOrder!['items'] as List<dynamic>)
                                .fold<Map<String, int>>({}, (acc, order) {
                                  acc.update(
                                      order['name'], (value) => value + 1,
                                      ifAbsent: () => 1);
                                  return acc;
                                })
                                .entries
                                .map((entry) {
                                  final order = randomOrder!['items']
                                      .firstWhere(
                                          (item) => item['name'] == entry.key);
                                  final totalPrice =
                                      (order['price'] as num) * entry.value;
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextWidget(
                                          text: 'x${entry.value} ${entry.key} ',
                                          fontSize: 20,
                                          fontFamily: "Bold",
                                          color: black),
                                      TextWidget(
                                          text: totalPrice != ''
                                              ? '₱ ${totalPrice.toStringAsFixed(2)}'
                                              : 'N/A',
                                          fontSize: 20,
                                          fontFamily: "Bold",
                                          color: secondary),
                                    ],
                                  );
                                })
                                .toList()
                            : [
                                TextWidget(
                                    text: 'No order details available',
                                    fontSize: 18,
                                    fontFamily: "Medium",
                                    color: black)
                              ],
                      ),
                      const Divider(
                        color: secondary,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                              text: "Payment: ",
                              fontSize: 18,
                              fontFamily: "Bold",
                              color: black),
                          TextWidget(
                              text: '${randomOrder?['mop'] ?? 'N/A'}',
                              fontSize: 20,
                              fontFamily: "Bold",
                              color: secondary),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                              text: 'Subtotal: ',
                              fontSize: 20,
                              fontFamily: "Bold",
                              color: black),
                          TextWidget(
                              text: randomOrder != null &&
                                      randomOrder?['subtotal'] != null
                                  ? '₱${(randomOrder?['subtotal'] as num).toStringAsFixed(2)}'
                                  : 'N/A',
                              fontSize: 20,
                              fontFamily: "Bold",
                              color: secondary),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                              text: "Delivery Fee: ",
                              fontSize: 20,
                              fontFamily: "Bold",
                              color: black),
                          TextWidget(
                              text: randomOrder != null &&
                                      randomOrder?['deliveryFee'] != null
                                  ? '₱${(randomOrder?['deliveryFee'] as num).toStringAsFixed(2)}'
                                  : 'N/A',
                              fontSize: 20,
                              fontFamily: "Bold",
                              color: secondary),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                              text: "Tip: ",
                              fontSize: 20,
                              fontFamily: "Bold",
                              color: black),
                          TextWidget(
                              text: randomOrder != null &&
                                      randomOrder?['tip'] != null
                                  ? '₱${(randomOrder?['tip'] as num).toStringAsFixed(2)}'
                                  : 'N/A',
                              fontSize: 20,
                              fontFamily: "Bold",
                              color: secondary),
                        ],
                      ),
                      const Divider(
                        color: secondary,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextWidget(
                              text: "Amount to pay: ",
                              fontSize: 20,
                              fontFamily: "Bold",
                              color: black),
                          TextWidget(
                            text: randomOrder != null &&
                                    randomOrder?['total'] != null
                                ? '₱${(randomOrder?['total'] as num).toStringAsFixed(2)}'
                                : 'N/A',
                            fontSize: 20,
                            fontFamily: "Bold",
                            color: secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 10),
                    decoration: BoxDecoration(
                        border: Border.all(color: secondary, width: 1),
                        borderRadius: BorderRadius.circular(10)),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: TextWidget(
                        text: 'Cancel',
                        fontSize: 18,
                        color: black,
                        fontFamily: "Medium",
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 10),
                    decoration: BoxDecoration(
                        color: secondary,
                        borderRadius: BorderRadius.circular(10)),
                    child: GestureDetector(
                      onTap: () async {
                        final merchant = await FirebaseFirestore.instance
                            .collection('Merchant')
                            .doc(randomOrder['merchantId'])
                            .get();
                        await FirebaseFirestore.instance
                            .collection('Riders')
                            .doc(driverId)
                            .update({'isActive': false});

                        mapController!.animateCamera(CameraUpdate.newLatLngZoom(
                            LatLng(merchant['lat'], merchant['lng']), 18.0));

                        plotPolylines(merchant['lat'], merchant['lng']);
                        setState(() {
                          orderId = randomOrder.id;
                          hasAccepted = true;
                        });

                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: TextWidget(
                        text: 'Accept',
                        fontSize: 18,
                        color: white,
                        fontFamily: "Medium",
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        });
  }

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  Widget _buildCravingOption(IconData icon, String label, bool selected) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 5.0),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontFamily: 'Medium'),
        ),
        if (selected)
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            height: 2.0,
            width: 40.0,
            color: Colors.white,
          ),
      ],
    );
  }
}
