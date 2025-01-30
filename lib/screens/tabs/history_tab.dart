import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:zippy/screens/home_screen.dart';
import 'package:zippy/screens/pages/profile_page.dart';
import 'package:zippy/screens/tabs/sales_tab.dart';
import 'package:zippy/utils/colors.dart';
import 'package:zippy/widgets/text_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? riderName;
  String? profileImage;
  String driverId = 'I7FTuyOuTNeo0xkCNjxfT0NBWxF3';
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('Riders').doc(driverId);

      userDoc.snapshots().listen((event) {
        if (event.exists) {
          final data = event.data() as Map<String, dynamic>;
          setState(() {
            userData = data;
            profileImage = event.get('profileImage');
          });
        }
      });

      // if (user != null) {
      //   DocumentSnapshot userDoc = await FirebaseFirestore.instance
      //       .collection('Riders')
      //       .doc(user.uid)
      //       .get();

      //   if (userDoc.exists) {
      //     setState(() {
      //       riderName = userDoc.get('name');
      //       profileImage = userDoc.get('profileImage');
      //     });
      //   }
      // }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
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
                  padding: const EdgeInsets.only(top: 25, left: 15, right: 15),
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
                                      child: CircularProgressIndicator()));
                            } else if (snapshot.hasError) {
                              return const Center(
                                  child: Text('Something went wrong'));
                            } else if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: Center(
                                      child: CircularProgressIndicator()));
                            }

                            final data =
                                snapshot.data!.data() as Map<String, dynamic>?;

                            if (data == null) {
                              return const Center(
                                  child: Text('No data found.'));
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: TextWidget(
                                    align: TextAlign.start,
                                    text: 'Good day! Rider ${data['name']}',
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
                                    backgroundImage: data['profileImage'] !=
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
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                      builder: (context) => const HomeScreen()),
                                );
                              },
                              child: _buildCravingOption(
                                  Icons.home, 'Home', false)),
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
                              onTap: () {},
                              child: _buildCravingOption(
                                  Icons.history, 'History', true)),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          // const SizedBox(
          //   height: 20,
          // ),
          // Padding(
          //   padding: const EdgeInsets.only(left: 20, right: 20),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       ButtonWidget(
          //         height: 35,
          //         width: 75,
          //         fontSize: 14,
          //         label: 'Food',
          //         onPressed: () {},
          //       ),
          //       IconButton(
          //         onPressed: () {},
          //         icon: const Icon(
          //           Icons.info,
          //           color: secondary,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(
          //   height: 20,
          // ),
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Orders')
                  .where('driverId', isEqualTo: driverId)
                  .where('status', isEqualTo: 'Delivered')
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
                  return const Center(child: Text('No orders found.'));
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var order = orders[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigator.of(context).push(
                          //   MaterialPageRoute(
                          //       builder: (context) => const CompletedPage()),
                          // );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, bottom: 10),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.18,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: secondary),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextWidget(
                                        text: '${order['merchantName']}',
                                        fontSize: 28,
                                        fontFamily: 'Bold',
                                        color: secondary,
                                      ),
                                      TextWidget(
                                        text:
                                            '₱${order['total'].toStringAsFixed(2)}',
                                        fontSize: 19,
                                        fontFamily: 'Medium',
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                  TextWidget(
                                    text: 'Food Delivery',
                                    fontSize: 19,
                                    fontFamily: 'Medium',
                                    color: secondary,
                                  ),
                                  TextWidget(
                                    text: '${order['merchantId']}',
                                    fontSize: 19,
                                    fontFamily: 'Medium',
                                    color: Colors.black,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextWidget(
                                        text:
                                            'Completed on ${DateFormat('MMMM d, y \'at\' h:mm a').format(order['date'].toDate())}', // Need to put date completion in the db
                                        fontSize: 15,
                                        color: secondary,
                                        fontFamily: 'Medium',
                                      ),
                                    ],
                                  ),
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
    );
  }

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
