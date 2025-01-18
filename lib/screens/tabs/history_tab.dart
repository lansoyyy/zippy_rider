import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zippy/screens/home_screen.dart';
import 'package:zippy/screens/pages/completed_page.dart';
import 'package:zippy/screens/pages/profile_page.dart';
import 'package:zippy/screens/tabs/sales_tab.dart';

import 'package:zippy/utils/colors.dart';
import 'package:zippy/widgets/button_widget.dart';
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
        }
      }
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
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ButtonWidget(
                  height: 35,
                  width: 75,
                  fontSize: 14,
                  label: 'Food',
                  onPressed: () {},
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
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CompletedPage()),
              );
            },
            child: Container(
              height: 125,
              width: 320,
              decoration: BoxDecoration(
                border: Border.all(color: secondary),
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: 'Bluebird Coffee',
                          fontSize: 24,
                          fontFamily: 'Bold',
                          color: secondary,
                        ),
                        TextWidget(
                          text: '₱570.00',
                          fontSize: 16,
                          fontFamily: 'Medium',
                          color: Colors.black,
                        ),
                      ],
                    ),
                    TextWidget(
                      text: 'Food Delivery',
                      fontSize: 16,
                      fontFamily: 'Medium',
                      color: secondary,
                    ),
                    TextWidget(
                      text: '111 2222 3333 444',
                      fontSize: 16,
                      fontFamily: 'Medium',
                      color: Colors.black,
                    ),
                    TextWidget(
                      text: 'Completed on 13/08/24 at 4:50PM ',
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
