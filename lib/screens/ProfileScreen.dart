import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
      await FirebaseFirestore.instance.collection('questionnaires').doc(uid).get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildItem(String label, String? value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value ?? "Not available"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("No profile data found."))
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildItem("Full Name", userData!['fullName']),
          _buildItem("Age", userData!['age']?.toString()),
          _buildItem("Gender", userData!['gender']),
          _buildItem("Height (cm)", userData!['height_cm']?.toString()),
          _buildItem("Weight (kg)", userData!['weight_kg']?.toString()),
          _buildItem("Physical Activity Level", userData!['activityLevel']),
          _buildItem("Medical History", userData!['medicalHistory']),
          _buildItem("Dietary Preference", userData!['dietaryPreference']),
          _buildItem("Smoking Status", userData!['smokingStatus']),
          _buildItem("Chronic Conditions", userData!['chronicConditions']),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
