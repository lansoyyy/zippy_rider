import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zippy/screens/home_screen.dart';
import 'package:zippy/screens/pages/arrived_page.dart';
import 'package:zippy/screens/pages/profile_page.dart';
import 'package:zippy/screens/tabs/history_tab.dart';

import 'package:zippy/utils/colors.dart';
import 'package:zippy/widgets/button_widget.dart';
import 'package:zippy/widgets/text_widget.dart';

class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
}

class _SalesTabState extends State<SalesTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? riderName;
  String? profileImage;
  int orderCount = 0;
  double totalEarned = 0.0;
  String driverId = 'I7FTuyOuTNeo0xkCNjxfT0NBWxF3';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Riders')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            riderName = userDoc.get('name');
            profileImage = userDoc.get('profileImage');
          });
          fetchOrderCount();
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchOrderCount() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'Delivered')
          .get();

      double calculatedTotalPrice = 0.0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null &&
            data.containsKey('items') &&
            data['items'] is List) {
          for (var item in data['items']) {
            if (item.containsKey('price')) {
              calculatedTotalPrice += item['price'];
            }
          }
        }
      }

      setState(() {
        orderCount = querySnapshot.size;
        totalEarned = calculatedTotalPrice;
      });
    } catch (e) {
      print('Error fetching order count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                    padding:
                        const EdgeInsets.only(top: 25, left: 15, right: 15),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 300,
                            child: TextWidget(
                              text: 'Good day! Rider $riderName',
                              fontSize: 22,
                              fontFamily: 'Bold',
                              color: Colors.white,
                            ),
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
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, top: 15),
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
                                        builder: (context) =>
                                            const HomeScreen()),
                                  );
                                },
                                child: _buildCravingOption(
                                    Icons.home, 'Home', false)),
                            GestureDetector(
                              onTap: () {},
                              child: _buildCravingOption(
                                  Icons.add_chart_rounded, 'Sales', true),
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
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ButtonWidget(
                        height: 35,
                        width: 75,
                        fontSize: 14,
                        label: 'Weekly',
                        onPressed: () {},
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      ButtonWidget(
                        height: 35,
                        width: 75,
                        fontSize: 14,
                        label: 'Food',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.info,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < 6; i++)
                  Container(
                    width: 45,
                    height: 70,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: secondary,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        TextWidget(
                          text: 'Aug',
                          fontSize: 12,
                          fontFamily: 'Medium',
                          color: secondary,
                        ),
                        TextWidget(
                          text: '${i + 1}',
                          fontSize: 32,
                          fontFamily: 'Bold',
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            TextWidget(
              text: '₱${totalEarned.toStringAsFixed(2)}',
              fontSize: 64,
              fontFamily: 'Bold',
              color: secondary,
            ),
            TextWidget(
              text: 'total earned this week',
              fontSize: 18,
              fontFamily: 'Medium',
              color: secondary,
            ),
            const SizedBox(
              height: 20,
            ),
            StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Orders')
                    .where('driverId',
                        isEqualTo: 'I7FTuyOuTNeo0xkCNjxfT0NBWxF3')
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
                  double calculatedTotalPrice = 0.0;
                  for (var doc in orders) {
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data != null &&
                        data.containsKey('items') &&
                        data['items'] is List) {
                      for (var item in data['items']) {
                        if (item.containsKey('price')) {
                          calculatedTotalPrice += item['price'];
                        }
                      }
                    }
                  }

                  orderCount = orders.length;
                  totalEarned = calculatedTotalPrice;

                  if (orders.isEmpty) {
                    return const Center(child: Text('No orders found.'));
                  }
                  return Container(
                    decoration: const BoxDecoration(
                      color: secondary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    height: MediaQuery.of(context).size.height - 500,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: orderCount == 1
                                    ? '1 order'
                                    : '$orderCount orders',
                                fontSize: 40,
                                fontFamily: 'Bold',
                                color: Colors.white,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  TextWidget(
                                    text: '15.2%',
                                    fontSize: 24,
                                    fontFamily: 'Regular',
                                    color: Colors.white,
                                  ),
                                  TextWidget(
                                    text: 'higher than last week',
                                    fontSize: 8,
                                    fontFamily: 'Regular',
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 10, 20, 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextWidget(
                                            text: 'Missions',
                                            fontSize: 40,
                                            fontFamily: 'Bold',
                                            color: secondary,
                                          ),
                                          TextWidget(
                                            text:
                                                'complete missions to earn rewards',
                                            fontSize: 16,
                                            fontFamily: 'Regular',
                                            color: secondary,
                                          ),
                                        ],
                                      ),
                                      Image.asset(
                                        'assets/images/star.png',
                                        height: 35,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Center(
                                  child: Container(
                                    height: 65,
                                    width: 320,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: secondary,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextWidget(
                                                text: 'Deliver 10 orders',
                                                fontSize: 16,
                                                fontFamily: 'Bold',
                                                color: secondary,
                                              ),
                                              TextWidget(
                                                text: '5/10',
                                                fontSize: 16,
                                                fontFamily: 'Bold',
                                                color: secondary,
                                              ),
                                            ],
                                          ),
                                          TextWidget(
                                            text:
                                                'Prize: Jollibee food voucher',
                                            fontSize: 12,
                                            fontFamily: 'Medium',
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                })
          ],
        ),
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
