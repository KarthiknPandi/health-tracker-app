import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Health _health = Health();

  String _steps = "Not synced yet";
  String _heartRate = "Not synced yet";
  String _activeEnergy = "Not synced yet";
  String _sleep = "Not synced yet";
  bool _isSyncing = false;

  static final _healthDataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static final _dataTypeUnits = {
    HealthDataType.STEPS: 'steps',
    HealthDataType.HEART_RATE: 'bpm',
    HealthDataType.ACTIVE_ENERGY_BURNED: 'kcal',
    HealthDataType.SLEEP_ASLEEP: 'hours',
  };

  Future<void> _syncHealthData() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    try {

      if (Platform.isAndroid) {
        // For Android (Health Connect)
        await _handleAndroidPermissions();
      } else if (Platform.isIOS) {
        // For iOS (HealthKit)
        await _handleIOSPermissions();
      }

      final authorized = await _health.requestAuthorization(
        _healthDataTypes,
        permissions:
            List.filled(_healthDataTypes.length, HealthDataAccess.READ),
      );

      if (!authorized) {
        _showError('Authorization not granted for health data');
        return;
      }

      final hasPermissions = await _health.hasPermissions(
        _healthDataTypes,
        permissions:
            List.filled(_healthDataTypes.length, HealthDataAccess.READ),
      );

      if (hasPermissions == null || !hasPermissions) {
        _showError('Required health permissions not granted');
        return;
      }

      final Map<HealthDataType, dynamic> healthData = {};

      for (final type in _healthDataTypes) {
        try {
          final data = await _health.getHealthDataFromTypes(
            startTime: yesterday,
            endTime: now,
            types: [type],
          );

          if (data.isNotEmpty) {
            // Process data based on type
            if (type == HealthDataType.STEPS ||
                type == HealthDataType.ACTIVE_ENERGY_BURNED) {

              final total =
                  data.fold(0.0, (sum, point) => sum + (point.value as num));
              healthData[type] = total.toStringAsFixed(1);
            } else if (type == HealthDataType.HEART_RATE) {

              data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
              healthData[type] = data.first.value.toString();
            } else if (type == HealthDataType.SLEEP_ASLEEP) {

              double totalSleep = 0;
              for (final point in data) {
                totalSleep +=
                    point.dateTo.difference(point.dateFrom).inMinutes / 60;
              }
              healthData[type] = totalSleep.toStringAsFixed(1);
            }
          }
        } catch (e) {
          debugPrint('Error fetching $type: $e');
          healthData[type] = null;
        }
      }

      setState(() {
        _steps = healthData[HealthDataType.STEPS]?.toString() ?? 'No data';
        _heartRate =
            healthData[HealthDataType.HEART_RATE]?.toString() ?? 'No data';
        _activeEnergy =
            healthData[HealthDataType.ACTIVE_ENERGY_BURNED]?.toString() ??
                'No data';
        _sleep =
            healthData[HealthDataType.SLEEP_ASLEEP]?.toString() ?? 'No data';
      });

      _showSuccess('Health data synced successfully');
    } catch (e) {
      debugPrint("Health sync error: $e");
      _showError('Error syncing health data: ${e.toString()}');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleAndroidPermissions() async {
    // Check if Health Connect is installed and available
    final isHealthConnectAvailable = await _health.isHealthConnectAvailable();
    if (!isHealthConnectAvailable) {
      _showError(
          'Health Connect not installed. Please install from Play Store.');
      return;
    }

    // Request Android permissions
    final statuses = await [
      Permission.activityRecognition,
      Permission.sensors,
      if (Platform.isAndroid) Permission.location,
    ].request();

    if (statuses[Permission.activityRecognition] != PermissionStatus.granted ||
        statuses[Permission.sensors] != PermissionStatus.granted) {
      _showError('Required permissions not granted');
      return;
    }

    try {
      final granted = await _health.requestAuthorization(
        _healthDataTypes,
        permissions:
            List.filled(_healthDataTypes.length, HealthDataAccess.READ),
      );

      if (!granted) {
        _showError('Please grant permissions in Health Connect');
      }
    } catch (e) {
      _showError('Failed to request Health Connect permissions: $e');
    }
  }

  Future<void> _handleIOSPermissions() async {
    try {
      final granted = await _health.requestAuthorization(
        _healthDataTypes,
        permissions: List.filled(_healthDataTypes.length, HealthDataAccess.READ),
      );

      if (!granted) {
        _showError('Please enable HealthKit permissions in Settings');
      }
    } catch (e) {
      _showError('Failed to request HealthKit permissions: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard("Step Count", _steps, 'steps'),
            _buildCard("Heart Rate", _heartRate, 'bpm'),
            _buildCard("Active Energy Burned", _activeEnergy, 'kcal'),
            _buildCard("Sleep Duration", _sleep, 'hours'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSyncing ? null : _syncHealthData,
              child: _isSyncing
                  ? const CircularProgressIndicator()
                  : const Text("Sync Health Connect / HealthKit Data"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, String unit) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value == 'No data' ? value : '$value $unit'),
        leading: const Icon(Icons.favorite, color: Colors.redAccent),
      ),
    );
  }
}
