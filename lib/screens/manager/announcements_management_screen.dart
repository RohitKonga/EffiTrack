import 'package:flutter/material.dart';

class AnnouncementsManagementScreen extends StatefulWidget {
  const AnnouncementsManagementScreen({super.key});

  @override
  State<AnnouncementsManagementScreen> createState() =>
      _AnnouncementsManagementScreenState();
}

class _AnnouncementsManagementScreenState
    extends State<AnnouncementsManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _title, _message;
  List<Map<String, String>> announcements = [
    {
      'title': 'Holiday Notice',
      'message': 'Office will be closed on 2024-07-30.',
    },
  ];

  void _addAnnouncement() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        announcements.insert(0, {'title': _title!, 'message': _message!});
        _title = null;
        _message = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Announcement added!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Title'),
                    onSaved: (value) => _title = value,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter title' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Message'),
                    onSaved: (value) => _message = value,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter message' : null,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _addAnnouncement,
                    child: const Text('Add Announcement'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Announcements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final ann = announcements[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(ann['title'] ?? ''),
                      subtitle: Text(ann['message'] ?? ''),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
