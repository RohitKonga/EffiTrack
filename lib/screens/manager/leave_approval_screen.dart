import 'package:flutter/material.dart';

class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  List<Map<String, String>> leaveRequests = [
    {
      'employee': 'Alice',
      'type': 'Sick Leave',
      'dates': '2024-07-10 to 2024-07-12',
      'status': 'Pending',
    },
    {
      'employee': 'Bob',
      'type': 'Casual Leave',
      'dates': '2024-06-20 to 2024-06-21',
      'status': 'Pending',
    },
  ];

  void _updateStatus(int index, String newStatus) {
    setState(() {
      leaveRequests[index]['status'] = newStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Approval')),
      body: ListView.builder(
        itemCount: leaveRequests.length,
        itemBuilder: (context, index) {
          final req = leaveRequests[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text('${req['employee']} - ${req['type']}'),
              subtitle: Text(
                'Dates: ${req['dates']}\nStatus: ${req['status']}',
              ),
              trailing: req['status'] == 'Pending'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _updateStatus(index, 'Approved'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _updateStatus(index, 'Rejected'),
                        ),
                      ],
                    )
                  : Text(req['status'] ?? ''),
            ),
          );
        },
      ),
    );
  }
}
