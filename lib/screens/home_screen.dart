import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zippy/screens/pages/arrived_page.dart';
import 'package:zippy/screens/pages/completed_page.dart';
import 'package:zippy/screens/pages/profile_page.dart';
import 'package:zippy/screens/tabs/history_tab.dart';
import 'package:zippy/screens/tabs/sales_tab.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zippy/utils/colors.dart';
import 'package:zippy/widgets/button_widget.dart';
import 'package:zippy/widgets/text_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(8.4542, 124.6319),
    zoom: 14.4746,
  );
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? randomOrder;
  Map<String, dynamic>? userData;

  String? riderName;
  File? _image;
  String? profileImage;
  String? merchantId;
  int orderCount = 0;
  double totalEarned = 0.0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
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
          fetchRandomOrder();
        } else {}
      });
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> fetchRandomOrder() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('status', isEqualTo: 'On the way')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final randomIndex = Random().nextInt(querySnapshot.docs.length);
        final randomDoc = querySnapshot.docs[randomIndex];
        setState(() {
          randomOrder = randomDoc.data() as Map<String, dynamic>;
        });
      } else {
        // Handle case where no orders exist
        setState(() {
          randomOrder = null;
        });
      }
    } catch (e) {
      print('Error fetching random order: $e');
      setState(() {
        randomOrder = null;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      try {
        User? user = _auth.currentUser;

        if (user != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.uid}.jpg');

          await ref.putFile(_image!);

          final url = await ref.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('Riders')
              .doc(user.uid)
              .update({'profileImage': url});
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Expanded(
            child: GoogleMap(
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              initialCameraPosition: HomeScreen._kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
          Container(
            width: double.infinity,
            height: 190,
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
                  padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: 'Good Day! Rider ${userData!['name']}',
                          fontSize: 22,
                          fontFamily: 'Bold',
                          color: Colors.white,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => const ProfilePage()),
                            );
                          },
                          child: CircleAvatar(
                            maxRadius: 25,
                            minRadius: 25,
                            backgroundImage: profileImage != null
                                ? NetworkImage(profileImage!)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
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
                                    builder: (context) => const SalesTab()),
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
                child: ButtonWidget(
                  color: secondary,
                  label: 'Search Bookings',
                  onPressed: () {
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: TextWidget(
                                text: "Order is Ready for Pickup",
                                fontSize: 22,
                                fontFamily: "Bold",
                                color: secondary),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/Group 121 (2).png',
                                  height: 200,
                                ),
                                const SizedBox(height: 10),
                                TextWidget(
                                    text:
                                        "Tap on Pick-up to \nconfirm receive order",
                                    fontSize: 18,
                                    fontFamily: "Medium",
                                    color: secondary),
                                const SizedBox(height: 10),
                                ButtonWidget(
                                  color: secondary,
                                  label: 'Pick-up',
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    fetchRandomOrder();
                                    showDialog(
                                        barrierDismissible: true,
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
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TextWidget(
                                                        text:
                                                            "Reference Code: ",
                                                        fontSize: 18,
                                                        fontFamily: "Bold",
                                                        color: black),
                                                    TextWidget(
                                                        text:
                                                            '${randomOrder?['uid'] ?? 'N/A'}',
                                                        fontSize: 20,
                                                        fontFamily: "Bold",
                                                        color: secondary),
                                                    const Divider(
                                                      color: secondary,
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TextWidget(
                                                        text: "Shop: ",
                                                        fontSize: 18,
                                                        fontFamily: "Bold",
                                                        color: black),
                                                    TextWidget(
                                                        text:
                                                            '${randomOrder?['merchantName'] ?? 'N/A'}',
                                                        fontSize: 20,
                                                        fontFamily: "Bold",
                                                        color: secondary),
                                                    const Divider(
                                                      color: secondary,
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    TextWidget(
                                                        text: "Address: ",
                                                        fontSize: 18,
                                                        fontFamily: "Bold",
                                                        color: black),
                                                    TextWidget(
                                                        text:
                                                            '${randomOrder?['deliveryAdd'] ?? 'N/A'}',
                                                        fontSize: 20,
                                                        fontFamily: "Bold",
                                                        color: secondary),
                                                    const Divider(
                                                      color: secondary,
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TextWidget(
                                                        text: "Order List: ",
                                                        fontSize: 23,
                                                        fontFamily: "Bold",
                                                        color: secondary),
                                                    Column(
                                                      children: randomOrder?[
                                                                  'items'] !=
                                                              null
                                                          ? (randomOrder![
                                                                      'items']
                                                                  as List<
                                                                      dynamic>)
                                                              .fold<
                                                                      Map<String,
                                                                          int>>(
                                                                  {},
                                                                  (acc, order) {
                                                                acc.update(
                                                                    order[
                                                                        'name'],
                                                                    (value) =>
                                                                        value +
                                                                        1,
                                                                    ifAbsent:
                                                                        () =>
                                                                            1);
                                                                return acc;
                                                              })
                                                              .entries
                                                              .map((entry) {
                                                                final order = randomOrder![
                                                                        'items']
                                                                    .firstWhere((item) =>
                                                                        item[
                                                                            'name'] ==
                                                                        entry
                                                                            .key);
                                                                final totalPrice =
                                                                    (order['price']
                                                                            as num) *
                                                                        entry
                                                                            .value;
                                                                return Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    TextWidget(
                                                                        text:
                                                                            'x${entry.value} ${entry.key} ',
                                                                        fontSize:
                                                                            20,
                                                                        fontFamily:
                                                                            "Bold",
                                                                        color:
                                                                            black),
                                                                    TextWidget(
                                                                        text: totalPrice !=
                                                                                null
                                                                            ? '₱ ${totalPrice.toStringAsFixed(2)}'
                                                                            : 'N/A',
                                                                        fontSize:
                                                                            20,
                                                                        fontFamily:
                                                                            "Bold",
                                                                        color:
                                                                            secondary),
                                                                  ],
                                                                );
                                                              })
                                                              .toList()
                                                          : [
                                                              TextWidget(
                                                                  text:
                                                                      'No order details available',
                                                                  fontSize: 18,
                                                                  fontFamily:
                                                                      "Medium",
                                                                  color: black)
                                                            ],
                                                    ),
                                                    const Divider(
                                                      color: secondary,
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        TextWidget(
                                                            text: "Payment: ",
                                                            fontSize: 18,
                                                            fontFamily: "Bold",
                                                            color: black),
                                                        TextWidget(
                                                            text:
                                                                '${randomOrder?['mop'] ?? 'N/A'}',
                                                            fontSize: 20,
                                                            fontFamily: "Bold",
                                                            color: secondary),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        TextWidget(
                                                            text: 'Subtotal: ',
                                                            fontSize: 20,
                                                            fontFamily: "Bold",
                                                            color: black),
                                                        TextWidget(
                                                            text: randomOrder?[
                                                                        'items'] !=
                                                                    null
                                                                ? '₱ ${(randomOrder!['items'] as List<dynamic>).fold<num>(0, (sum, item) => sum + (item['price'] as num)).toStringAsFixed(2)}'
                                                                : 'N/A',
                                                            fontSize: 20,
                                                            fontFamily: "Bold",
                                                            color: secondary),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        TextWidget(
                                                            text:
                                                                "Delivery Fee: ",
                                                            fontSize: 20,
                                                            fontFamily: "Bold",
                                                            color: black),
                                                        TextWidget(
                                                            text: randomOrder !=
                                                                        null &&
                                                                    randomOrder?[
                                                                            'deliveryFee'] !=
                                                                        null
                                                                ? '₱${(randomOrder?['deliveryFee'] as num).toStringAsFixed(2)}'
                                                                : 'N/A',
                                                            fontSize: 20,
                                                            fontFamily: "Bold",
                                                            color: secondary),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        TextWidget(
                                                            text: "Tip: ",
                                                            fontSize: 20,
                                                            fontFamily: "Bold",
                                                            color: black),
                                                        TextWidget(
                                                            text: randomOrder !=
                                                                        null &&
                                                                    randomOrder?[
                                                                            'tip'] !=
                                                                        null
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
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        TextWidget(
                                                            text:
                                                                "Amount to pay: ",
                                                            fontSize: 20,
                                                            fontFamily: "Bold",
                                                            color: black),
                                                        TextWidget(
                                                          text: randomOrder !=
                                                                      null &&
                                                                  randomOrder?[
                                                                          'items'] !=
                                                                      null
                                                              ? '₱ ${((randomOrder!['items'] as List<dynamic>).fold<num>(0, (sum, item) => sum + (item['price'] as num)) + (randomOrder?['deliveryFee'] as num? ?? 0) + (randomOrder?['tip'] as num? ?? 0)).toStringAsFixed(2)}'
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
                                            actions: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 35,
                                                        vertical: 10),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: secondary,
                                                            width: 1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .pop();
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
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 35,
                                                        vertical: 10),
                                                    decoration: BoxDecoration(
                                                        color: secondary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10)),
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .push(
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  const ArrivedPage()),
                                                        );
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
                                  },
                                ),
                              ],
                            ),
                            actions: const [],
                          );
                        });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
