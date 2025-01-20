import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zippy/screens/auth/login_screen.dart';
import 'package:zippy/widgets/button_widget.dart';
import 'package:zippy/widgets/toast_widget.dart';

import '../../utils/colors.dart';
import '../../widgets/text_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  File? _image;
  String? profileImage;
  Map<String, dynamic>? userData;
  bool isNameEditing = false;
  bool isNumEditing = false;
  bool isEmailEditing = false;
  bool isBdayEditing = false;
  bool isAddEditing = false;
  bool isVehEditing = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController bdayController = TextEditingController();
  TextEditingController addController = TextEditingController();
  TextEditingController vehController = TextEditingController();

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

      DocumentSnapshot docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          userData = data;
          profileImage = data['profileImage'];
        });
      } else {
        showToast('User data not found.');
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> updateName() async {
    try {
      User? user = _auth.currentUser;

      await FirebaseFirestore.instance
          .collection('Riders')
          .doc(user?.uid)
          .update({'name': nameController.text});
      setState(() {
        userData!['name'] = nameController.text;
        isNameEditing = false;
      });
    } catch (e) {}
  }

  Future<void> updateEmail() async {
    try {
      User? user = _auth.currentUser;

      await FirebaseFirestore.instance
          .collection('Riders')
          .doc(user?.uid)
          .update({'email': emailController.text});
      setState(() {
        userData!['email'] = emailController.text;
        isEmailEditing = false;
      });
    } catch (e) {}
  }

  Future<void> updateNumber() async {
    try {
      User? user = _auth.currentUser;

      await FirebaseFirestore.instance
          .collection('Riders')
          .doc(user?.uid)
          .update({'number': numberController.text});
      setState(() {
        userData!['number'] = numberController.text;
        isNumEditing = false;
      });
    } catch (e) {}
  }

  Future<void> updateBday() async {
    try {
      User? user = _auth.currentUser;

      await FirebaseFirestore.instance
          .collection('Riders')
          .doc(user?.uid)
          .update({'bday': bdayController.text});
      setState(() {
        userData!['bday'] = bdayController.text;
        isBdayEditing = false;
      });
    } catch (e) {}
  }

  Future<void> updateAdd() async {
    try {
      User? user = _auth.currentUser;

      await FirebaseFirestore.instance
          .collection('Riders')
          .doc(user?.uid)
          .update({'address': addController.text});
      setState(() {
        userData!['address'] = addController.text;
        isAddEditing = false;
      });
    } catch (e) {}
  }

  Future<void> updateVeh() async {
    try {
      User? user = _auth.currentUser;

      await FirebaseFirestore.instance
          .collection('Riders')
          .doc(user?.uid)
          .update({'vehicleModel': vehController.text});
      setState(() {
        userData!['vehicleModel'] = vehController.text;
        isVehEditing = false;
      });
    } catch (e) {}
  }

  // Future<void> fetchUserData() async {
  //   try {
  //     User? user = _auth.currentUser;

  //     if (user != null) {
  //       DocumentSnapshot userDoc = await FirebaseFirestore.instance
  //           .collection('Riders')
  //           .doc(user.uid)
  //           .get();

  //       if (userDoc.exists) {
  //         final data = docSnapshot.data() as Map<String, dynamic>;
  //         setState(() {
  //           userData = data;
  //           address = userDoc.get('address');
  //           expiry = userDoc.get('expiry');
  //           bday = userDoc.get('bday');
  //           email = userDoc.get('email');
  //           licenseNumber = userDoc.get('licenseNumber');
  //           name = userDoc.get('name');
  //           number = userDoc.get('number');
  //           plateNumber = userDoc.get('plateNumber');
  //           registrationNumber = userDoc.get('registrationNumber');
  //           vehicleModel = userDoc.get('vehicleModel');
  //           profileImage = userDoc.get('profileImage');
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }

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

          showToast('Profile Image Updated');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new,
                            color: secondary,
                            size: 18,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          TextWidget(
                            text: 'Back',
                            fontSize: 15,
                            color: secondary,
                            fontFamily: 'Medium',
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        TextWidget(
                          text: 'Logout',
                          fontSize: 15,
                          color: secondary,
                          fontFamily: 'Medium',
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: TextWidget(
                                      text: 'Are you sure you want to Logout?',
                                      fontSize: 20,
                                      color: secondary,
                                      fontFamily: 'Bold',
                                    ),
                                    actions: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 35, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: secondary,
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          child: TextWidget(
                                            text: 'Cancel',
                                            fontSize: 18,
                                            color: white,
                                            fontFamily: "Medium",
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 35, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            border:
                                                Border.all(color: secondary),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: GestureDetector(
                                          onTap: () async {
                                            await FirebaseAuth.instance
                                                .signOut();
                                            Navigator.of(context)
                                                .pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const LoginScreen()),
                                              (Route<dynamic> route) => false,
                                            );

                                            showToast(
                                                'Successfully logged out');
                                          },
                                          child: TextWidget(
                                            text: 'Logout',
                                            fontSize: 18,
                                            color: secondary,
                                            fontFamily: "Medium",
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                });
                          },
                          child: const Icon(
                            Icons.logout,
                            color: secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: secondary,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: CircleAvatar(
                        minRadius: 75,
                        maxRadius: 75,
                        backgroundImage: profileImage != null
                            ? NetworkImage(profileImage!)
                            : const AssetImage(
                                    'assets/images/Group 121 (2).png')
                                as ImageProvider,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 120, top: 110, bottom: 20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: secondary),
                      child: IconButton(
                        onPressed: () async {
                          await _pickImage();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.add_a_photo_rounded,
                          color: white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: isNameEditing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          child: TextField(
                            decoration:
                                const InputDecoration(border: InputBorder.none),
                            controller: nameController,
                            style: const TextStyle(
                              color: secondary,
                              fontSize: 28,
                              fontFamily: 'Bold',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: updateName, // Confirm update
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              isNameEditing = false;
                              nameController.text =
                                  userData!['name']; // Revert changes
                            });
                          },
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextWidget(
                          text: '${userData?['name']}' ?? '....',
                          fontSize: 28,
                          color: secondary,
                          fontFamily: 'Bold',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: secondary),
                          onPressed: () {
                            setState(() {
                              isNameEditing = true;
                            });
                          },
                        ),
                      ],
                    ),
            ),
            const SizedBox(
              height: 10,
            ),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height - 400,
                  decoration: const BoxDecoration(
                    color: secondary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 20, left: 25, right: 25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                              text: 'Personal Information',
                              fontSize: 25,
                              color: Colors.white,
                              fontFamily: 'Bold',
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isNumEditing = true;
                                  isEmailEditing = true;
                                  isBdayEditing = true;
                                  isAddEditing = true;
                                  isVehEditing = true;
                                  numberController.text =
                                      userData!['number'] ?? '';
                                  emailController.text =
                                      userData!['email'] ?? '';
                                  bdayController.text = userData!['bday'] ?? '';
                                  addController.text =
                                      userData!['address'] ?? '';
                                  vehController.text =
                                      userData!['vehicleModel'] ?? '';
                                });
                              },
                              child: TextWidget(
                                text: 'Edit',
                                fontSize: 20,
                                color: Colors.white,
                                fontFamily: 'Medium',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 60,
                  child: Container(
                    height: MediaQuery.of(context).size.height - 400,
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    width: double.infinity,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 30, top: 30, right: 70),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextWidget(
                                text: 'EMAIL ADDRESS',
                                fontSize: 16,
                                color: black,
                                fontFamily: 'Regular',
                              ),
                              // const SizedBox(
                              //   width: 120,
                              // ),
                              TextWidget(
                                text: 'MOBILE NUMBER',
                                fontSize: 16,
                                color: black,
                                fontFamily: 'Regular',
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              isEmailEditing
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            decoration: const InputDecoration(
                                                border: InputBorder.none),
                                            controller: emailController,
                                            style: const TextStyle(
                                              color: secondary,
                                              fontSize: 16,
                                              fontFamily: 'Medium',
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.check,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  updateEmail, // Confirm email update
                                              padding: EdgeInsets
                                                  .zero, // Remove default padding
                                              constraints:
                                                  const BoxConstraints(), // Remove default constraints
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                                size: 17,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  isEmailEditing = false;
                                                  emailController.text = userData![
                                                      'email']; // Revert changes
                                                });
                                              },
                                              padding: EdgeInsets
                                                  .zero, // Remove default padding
                                              constraints:
                                                  const BoxConstraints(), // Remove default constraints
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        TextWidget(
                                          text:
                                              '${userData?['email']}' ?? '....',
                                          fontSize: 16,
                                          color: secondary,
                                          fontFamily: 'Medium',
                                        ),
                                      ],
                                    ),
                              isNumEditing
                                  ? const SizedBox(
                                      width: 0,
                                    )
                                  : const SizedBox(
                                      width: 85,
                                    ),
                              isNumEditing
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            decoration: const InputDecoration(
                                                border: InputBorder.none),
                                            controller: numberController,
                                            style: const TextStyle(
                                              color: secondary,
                                              fontSize: 16,
                                              fontFamily: 'Medium',
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          onPressed:
                                              updateNumber, // Confirm number update
                                        ),
                                        const Padding(padding: EdgeInsets.zero),
                                        IconButton(
                                          icon: const Icon(Icons.cancel,
                                              color: Colors.red, size: 17),
                                          onPressed: () {
                                            setState(() {
                                              isNumEditing = false;
                                              numberController.text = userData![
                                                  'number']; // Revert changes
                                            });
                                          },
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        TextWidget(
                                          text: '${userData?['number']}' ??
                                              '....',
                                          fontSize: 14,
                                          color: secondary,
                                          fontFamily: 'Medium',
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 30, right: 30),
                            child: Divider(color: black)),
                        Padding(
                            padding: const EdgeInsets.only(left: 30, right: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: 'BIRTHDATE',
                                      fontSize: 16,
                                      color: black,
                                      fontFamily: 'Regular',
                                    ),
                                    isBdayEditing
                                        ? Row(
                                            children: [
                                              SizedBox(
                                                width: 80,
                                                child: TextField(
                                                  decoration:
                                                      const InputDecoration(
                                                          border:
                                                              InputBorder.none),
                                                  controller: bdayController,
                                                  style: const TextStyle(
                                                    color: secondary,
                                                    fontSize: 16,
                                                    fontFamily: 'Medium',
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.check,
                                                  color: Colors.green,
                                                  size: 20,
                                                ),
                                                onPressed:
                                                    updateBday, // Confirm number update
                                              ),
                                              const Padding(
                                                  padding: EdgeInsets.zero),
                                              IconButton(
                                                icon: const Icon(Icons.cancel,
                                                    color: Colors.red,
                                                    size: 17),
                                                onPressed: () {
                                                  setState(() {
                                                    isBdayEditing = false;
                                                    bdayController.text = userData![
                                                        'bday']; // Revert changes
                                                  });
                                                },
                                              ),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              TextWidget(
                                                text: '${userData?['bday']}' ??
                                                    '....',
                                                fontSize: 16,
                                                color: secondary,
                                                fontFamily: 'Medium',
                                              ),
                                            ],
                                          ),
                                  ],
                                ),
                              ],
                            )),
                        Padding(
                            padding: const EdgeInsets.only(left: 30, right: 30),
                            child: Divider(color: black)),
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'Address',
                                    fontSize: 16,
                                    color: black,
                                    fontFamily: 'Regular',
                                  ),
                                  isAddEditing
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              width: 80,
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                        border:
                                                            InputBorder.none),
                                                controller: addController,
                                                style: const TextStyle(
                                                  color: secondary,
                                                  fontSize: 16,
                                                  fontFamily: 'Medium',
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.check,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  updateAdd, // Confirm number update
                                            ),
                                            const Padding(
                                                padding: EdgeInsets.zero),
                                            IconButton(
                                              icon: const Icon(Icons.cancel,
                                                  color: Colors.red, size: 17),
                                              onPressed: () {
                                                setState(() {
                                                  isAddEditing = false;
                                                  addController.text = userData![
                                                      'address']; // Revert changes
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            TextWidget(
                                              text: '${userData?['address']}' ??
                                                  '....',
                                              fontSize: 16,
                                              color: secondary,
                                              fontFamily: 'Medium',
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 30, right: 30),
                            child: Divider(color: black)),
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'Vehicle Model',
                                    fontSize: 16,
                                    color: black,
                                    fontFamily: 'Regular',
                                  ),
                                  isVehEditing
                                      ? Row(
                                          children: [
                                            SizedBox(
                                              width: 80,
                                              child: TextField(
                                                decoration:
                                                    const InputDecoration(
                                                        border:
                                                            InputBorder.none),
                                                controller: vehController,
                                                style: const TextStyle(
                                                  color: secondary,
                                                  fontSize: 16,
                                                  fontFamily: 'Medium',
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.check,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  updateVeh, // Confirm number update
                                            ),
                                            const Padding(
                                                padding: EdgeInsets.zero),
                                            IconButton(
                                              icon: const Icon(Icons.cancel,
                                                  color: Colors.red, size: 17),
                                              onPressed: () {
                                                setState(() {
                                                  isVehEditing = false;
                                                  vehController.text = userData![
                                                      'vehicleModel']; // Revert changes
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            TextWidget(
                                              text:
                                                  '${userData?['vehicleModel']}' ??
                                                      '....',
                                              fontSize: 16,
                                              color: secondary,
                                              fontFamily: 'Medium',
                                            ),
                                          ],
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 30, right: 30),
                            child: Divider(color: black)),
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'Plate Number',
                                    fontSize: 16,
                                    color: black,
                                    fontFamily: 'Regular',
                                  ),
                                  SizedBox(
                                    child: TextWidget(
                                      align: TextAlign.start,
                                      text: '${userData?['plateNumber']}',
                                      fontSize: 16,
                                      color: secondary,
                                      fontFamily: 'Medium',
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'Registration No.',
                                    fontSize: 16,
                                    color: black,
                                    fontFamily: 'Regular',
                                  ),
                                  SizedBox(
                                    child: TextWidget(
                                      align: TextAlign.start,
                                      text:
                                          '${userData?['registrationNumber']}',
                                      fontSize: 16,
                                      color: secondary,
                                      fontFamily: 'Medium',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 30, right: 30),
                            child: Divider(color: black)),
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'License No.',
                                    fontSize: 16,
                                    color: black,
                                    fontFamily: 'Regular',
                                  ),
                                  SizedBox(
                                    child: TextWidget(
                                      align: TextAlign.start,
                                      text: '${userData?['licenseNumber']}',
                                      fontSize: 16,
                                      color: secondary,
                                      fontFamily: 'Medium',
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: 'Expiry',
                                    fontSize: 16,
                                    color: black,
                                    fontFamily: 'Regular',
                                  ),
                                  SizedBox(
                                    child: TextWidget(
                                      align: TextAlign.start,
                                      text: '${userData?['expiry']}',
                                      fontSize: 14,
                                      color: secondary,
                                      fontFamily: 'Medium',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget tileWidget(String title, Widget suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Center(
        child: Container(
          width: 320,
          height: 40,
          decoration: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 15, right: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: title,
                  fontSize: 15,
                  color: Colors.white,
                  fontFamily: 'Medium',
                ),
                suffix
              ],
            ),
          ),
        ),
      ),
    );
  }

  showPrivacy(context, String label, String caption) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 500,
          width: double.infinity,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: secondary,
                    size: 50,
                  ),
                  TextWidget(
                    text: label,
                    fontSize: 24,
                    color: secondary,
                    fontFamily: 'Bold',
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    height: 300,
                    width: 320,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: secondary,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: TextWidget(
                          align: TextAlign.start,
                          maxLines: 500,
                          text: caption,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ButtonWidget(
                    width: 320,
                    label: 'OKAY',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  showFavorites(context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 500,
          width: double.infinity,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: secondary,
                    size: 50,
                  ),
                  TextWidget(
                    text: 'Favorites',
                    fontSize: 24,
                    color: secondary,
                    fontFamily: 'Bold',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextWidget(
                    text: 'click on the heart to remove from favorites',
                    fontSize: 15,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    height: 375,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (int i = 0; i < 10; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Container(
                                width: 320,
                                height: 65,
                                decoration: BoxDecoration(
                                  color: secondary,
                                  borderRadius: BorderRadius.circular(
                                    20,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'assets/images/Rectangle 40.png',
                                      height: double.infinity,
                                      width: 120,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    TextWidget(
                                      text: 'Bluebird Coffee',
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontFamily: 'Bold',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
