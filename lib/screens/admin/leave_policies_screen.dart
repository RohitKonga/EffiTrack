import 'package:flutter/material.dart';

class LeavePoliciesScreen extends StatefulWidget {
  const LeavePoliciesScreen({super.key});

  @override
  State<LeavePoliciesScreen> createState() => _LeavePoliciesScreenState();
}

class _LeavePoliciesScreenState extends State<LeavePoliciesScreen> {
  Map<String, int> policies = {
    'Sick Leave': 10,
    'Casual Leave': 8,
    'Earned Leave': 15,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Policies')),
      body: ListView(
        children: policies.keys.map((type) {
          return ListTile(
            title: Text(type),
            trailing: SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: policies[type].toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    policies[type] = int.tryParse(value) ?? policies[type]!;
                  });
                },
                decoration: const InputDecoration(suffixText: 'days'),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
