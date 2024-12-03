import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../home_screen.dart';
//import '../../widgets/distance_unit_as_string_provider.dart';

class RunningStatsPage extends StatefulWidget {
  final Map<String, dynamic>? newRunData;

  const RunningStatsPage({super.key, this.newRunData});

  @override
  _RunningStatsPageState createState() => _RunningStatsPageState();
}

class _RunningStatsPageState extends State<RunningStatsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.newRunData != null) {
      _saveRunToFirebase(widget.newRunData!);
    }
  }

  void _saveRunToFirebase(Map<String, dynamic> runData) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    runData['timestamp'] = FieldValue.serverTimestamp();
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('runs')
        .add(runData)
        .then((_) => print('Run saved successfully'))
        .catchError((error) => print('Failed to save run: $error'));
  }

  void _deleteRun(String docId) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('runs')
        .doc(docId)
        .delete()
        .then((_) => print('Run deleted successfully'))
        .catchError((error) => print('Failed to delete run: $error'));
  }

  @override
  Widget build(BuildContext context) {
    //december 3, 2024: added this popscope to prevent the user from going back to the current run screen
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Running Stats'),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              if (widget.newRunData != null)
                _displayCurrentRunStats(widget.newRunData!),
              Expanded(
                child: _buildRunList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _displayCurrentRunStats(Map<String, dynamic> runData) {
    return Container(
      margin: const EdgeInsets.all(16), //spacing around container
      padding: const EdgeInsets.all(16), //padding inside container
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8), //semi-transparent bg
        borderRadius: BorderRadius.circular(15), //rounder corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), //subtle shadow
            blurRadius: 10, //blur effect for the shadow
            offset: const Offset(0, 5), //shadow offset
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Run Summary:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
              'Distance: ${runData['distance'].toStringAsFixed(2)} ${runData['distanceUnitString']}'), //tested and works [nov 20, 2024]
          Text('Time: ${runData['time']}'),
          Text('Average Pace: ${runData['averagePace']}'),
        ],
      ),
    );
  }

  Widget _buildRunList() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('runs')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final runs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: runs.length,
          itemBuilder: (context, index) {
            final run = runs[index].data() as Map<String, dynamic>;
            final docId = runs[index].id;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  'Distance: ${run['distance'].toStringAsFixed(2)} ${run['distanceUnitString']}', //tested and works [nov 20, 2024]
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    'Time: ${run['time']} \nAverage Pace: ${run['averagePace']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteRun(docId),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
