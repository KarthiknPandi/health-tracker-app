import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'HomePage.dart';
import 'login_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final fullNameController = TextEditingController();
  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final medicalHistoryController = TextEditingController();
  final chronicController = TextEditingController();

  String? gender;
  String? activityLevel;
  String? dietaryPreference;
  String? smokingStatus;

  final genderOptions   = ['Male', 'Female', 'Other'];
  final activityOptions = [
    'Sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
    'Super active'
  ];
  final dietaryOptions  = [
    'Vegetarian',
    'Vegan',
    'Omnivore',
    'Pescatarian',
    'Keto',
    'Other'
  ];
  final smokingOptions  = ['Yes', 'No'];

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('questionnaires')
          .doc(user.uid)
          .set({
        'fullName'        : fullNameController.text.trim(),
        'age'             : int.parse(ageController.text),
        'gender'          : gender,
        'height_cm'       : int.parse(heightController.text),
        'weight_kg'       : int.parse(weightController.text),
        'activityLevel'   : activityLevel,
        'medicalHistory'  : medicalHistoryController.text.trim(),
        'dietaryPreference': dietaryPreference,
        'smokingStatus'   : smokingStatus,
        'chronicConditions': chronicController.text.trim(),
        'submittedAt'     : Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Questionnaire submitted!')),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
            (route) => false,
      );

    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  // Convenience builders
  Widget _numField(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration:
      InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    ),
  );

  Widget _txtField(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: c,
      decoration:
      InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    ),
  );

  Widget _drop<T>(
      String label,
      String? value,
      List<String> opts,
      void Function(String?) onChanged,
      ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DropdownButtonFormField<String>(
          value: value,
          hint: Text('Select $label'),
          decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
          items: opts
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select $label' : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Questionnaire"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _txtField('Full Name', fullNameController),
              _numField('Age', ageController),
              _drop('Gender', gender, genderOptions,
                      (v) => setState(() => gender = v)),
              _numField('Height (cm)', heightController),
              _numField('Weight (kg)', weightController),
              _drop('Physical Activity Level', activityLevel, activityOptions,
                      (v) => setState(() => activityLevel = v)),
              _txtField('Medical History', medicalHistoryController),
              _drop('Dietary Preference', dietaryPreference, dietaryOptions,
                      (v) => setState(() => dietaryPreference = v)),
              _drop('Smoking Status', smokingStatus, smokingOptions,
                      (v) => setState(() => smokingStatus = v)),
              _txtField('Chronic Conditions', chronicController),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text('Submit')),
            ],
          ),
        ),
      ),
    );
  }

}
