import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RunningStatsPage extends StatefulWidget {
  const RunningStatsPage({super.key});

  @override
  _RunningStatsPageState createState() => _RunningStatsPageState();
}

class _RunningStatsPageState extends State<RunningStatsPage> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _timeController = TextEditingController();

  void _addRun() {
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final distance = double.parse(_distanceController.text);
      final time = int.parse(_timeController.text);
      final speed = (distance / time * 60).round(); // m/min

      final runData = {
        'distance': distance,
        'time': time,
        'speed': speed,
        'timestamp': FieldValue.serverTimestamp(),
      };

      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('runs')
          .add(runData);

      _distanceController.clear();
      _timeController.clear();
    }
  }

  void _deleteRun(String docId) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('runs')
        .doc(docId)
        .delete();
  }

  void _editRun(String docId, Map<String, dynamic> currentData) {
    showDialog(
      context: context,
      builder: (context) {
        final distanceController =
            TextEditingController(text: currentData['distance'].toString());
        final timeController =
            TextEditingController(text: currentData['time'].toString());

        return AlertDialog(
          title: Text('Edit Run'),
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: distanceController,
                  decoration: InputDecoration(labelText: 'Distance (km)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: timeController,
                  decoration: InputDecoration(labelText: 'Time (minutes)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                final userId = FirebaseAuth.instance.currentUser!.uid;
                final distance = double.parse(distanceController.text);
                final time = int.parse(timeController.text);
                final speed = (distance / time * 60).round(); // m/min

                FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('runs')
                    .doc(docId)
                    .update({
                  'distance': distance,
                  'time': time,
                  'speed': speed,
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text('Running Stats'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _distanceController,
                      decoration: InputDecoration(labelText: 'Distance (km)'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter distance' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: InputDecoration(labelText: 'Time (minutes)'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter time' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    child: Text('Add Run'),
                    onPressed: _addRun,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('runs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final runs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: runs.length,
                  itemBuilder: (context, index) {
                    final run = runs[index].data() as Map<String, dynamic>;
                    final runMessage = _getRunMessage(runs, index);
                    return ListTile(
                      title: Text(
                          'Distance: ${run['distance']} km, Time: ${run['time']} min'),
                      subtitle:
                          Text('Speed: ${run['speed']} m/min\n$runMessage'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editRun(runs[index].id, run),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteRun(runs[index].id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getRunMessage(List<QueryDocumentSnapshot> runs, int index) {
    if (runs.length == 1) return "Great First Run!";

    final currentRun = runs[index].data() as Map<String, dynamic>;
    final currentSpeed = currentRun['speed'] as int;

    final fasterRuns = runs.where((run) {
      final runData = run.data() as Map<String, dynamic>;
      return (runData['speed'] as int) > currentSpeed;
    }).length;

    if (fasterRuns == 0) return "This was your fastest run ever!";
    if (fasterRuns == 1) return "2nd fastest run!";
    if (fasterRuns == 2) return "3rd fastest run!";
    return "${fasterRuns + 1}th fastest run";
  }
}
