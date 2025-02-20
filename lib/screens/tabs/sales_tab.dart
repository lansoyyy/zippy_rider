import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:zippy/screens/home_screen.dart';
import 'package:zippy/screens/pages/profile_page.dart';
import 'package:zippy/screens/tabs/history_tab.dart';
import 'package:zippy/utils/colors.dart';
import 'package:zippy/utils/const.dart';
import 'package:zippy/widgets/text_widget.dart';

class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? profileImage;
  int orderCount = 0;
  double totalEarned = 0.0;

  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchOrderCount();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        FirebaseFirestore.instance
            .collection('Riders')
            .doc(user.uid)
            .snapshots()
            .listen((event) {
          if (event.exists) {
            final data = event.data() as Map<String, dynamic>;
            setState(() {
              userData = data;
              profileImage = data['profileImage'];
            });
          }
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> fetchOrderCount() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Orders')
          .where('driverId', isEqualTo: myId)
          .where('status', isEqualTo: 'Delivered')
          .get();

      double calculatedTotalPrice = 0.0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('deliveryFee')) {
          calculatedTotalPrice += data['deliveryFee'];
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
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.25,
              decoration: const BoxDecoration(
                color: secondary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
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
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return const Center(
                                child: Text('Something went wrong'));
                          }

                          final data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          if (data == null) {
                            return const Center(child: Text('No data found.'));
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(
                                width: 300,
                                child: TextWidget(
                                  align: TextAlign.left,
                                  text: 'Good Day! Rider ${data['name']}',
                                  fontSize: 20,
                                  fontFamily: 'Bold',
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ProfilePage(),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  maxRadius: 25,
                                  minRadius: 25,
                                  backgroundImage: data['profileImage'] != null
                                      ? NetworkImage(data['profileImage'])
                                      : const NetworkImage(
                                          'https://cdn-icons-png.flaticon.com/256/149/149071.png'),
                                ),
                              ),
                            ],
                          );
                        },
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
                            _buildCravingOption(Icons.home, 'Home', false, () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            }),
                            _buildCravingOption(
                                Icons.add_chart_rounded, 'Sales', true, () {}),
                            _buildCravingOption(Icons.history, 'History', false,
                                () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HistoryScreen(),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Weekly Calendar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                DateTime date = startOfWeek.add(Duration(days: index));
                bool isToday = date.day == now.day &&
                    date.month == now.month &&
                    date.year == now.year;
                return _buildDayContainer(context, date, isToday);
              }),
            ),
            const SizedBox(height: 25),

            // Sales Chart and Total Earnings
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Orders')
                  .where('driverId', isEqualTo: myId)
                  .where('status', isEqualTo: 'Delivered')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                final orders = snapshot.data!.docs;
                List<SalesData> chartData = List.generate(7, (index) {
                  DateTime day = startOfWeek.add(Duration(days: index));
                  double sales = orders.length.toDouble(); // Example sales data
                  return SalesData(day, sales);
                });

                return Column(
                  children: [
                    TextWidget(
                      text: '₱${totalEarned.toStringAsFixed(2)}',
                      fontSize: 64,
                      fontFamily: 'Bold',
                      color: secondary,
                    ),
                    TextWidget(
                      text: 'total earned',
                      fontSize: 18,
                      fontFamily: 'Medium',
                      color: secondary,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SfCartesianChart(
                        primaryXAxis: DateTimeAxis(
                          intervalType: DateTimeIntervalType.days,
                          dateFormat: DateFormat.E(),
                          majorGridLines: const MajorGridLines(width: 0),
                        ),
                        primaryYAxis: const NumericAxis(
                          title: AxisTitle(text: "Bookings"),
                        ),
                        series: <CartesianSeries>[
                          LineSeries<SalesData, DateTime>(
                            dataSource: chartData,
                            xValueMapper: (SalesData sales, _) => sales.year,
                            yValueMapper: (SalesData sales, _) => sales.sales,
                            color: secondary,
                            markerSettings:
                                const MarkerSettings(isVisible: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayContainer(BuildContext context, DateTime date, bool isToday) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.12,
      height: MediaQuery.of(context).size.width * 0.2,
      decoration: BoxDecoration(
        color: isToday ? secondary : Colors.transparent,
        border: Border.all(color: secondary),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextWidget(
            text: DateFormat.MMM().format(date),
            fontSize: 12,
            fontFamily: 'Medium',
            color: isToday ? Colors.white : secondary,
          ),
          TextWidget(
            text: '${date.day}',
            fontSize: 25,
            fontFamily: 'Bold',
            color: isToday ? Colors.white : Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildCravingOption(
      IconData icon, String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}

class SalesData {
  SalesData(this.year, this.sales);
  final DateTime year;
  final double sales;
}
