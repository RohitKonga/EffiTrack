import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class AnnouncementsManagementScreen extends StatefulWidget {
  const AnnouncementsManagementScreen({super.key});

  @override
  State<AnnouncementsManagementScreen> createState() =>
      _AnnouncementsManagementScreenState();
}

class _AnnouncementsManagementScreenState
    extends State<AnnouncementsManagementScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _title, _message;
  bool _showForm = false;

  List<Map<String, dynamic>> announcements = [];
  bool _loading = true;
  String? _error;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final response = await apiService.get('/announcements');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Fetched announcements data: $data'); // Temporary debug
        setState(() {
          announcements = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() {
          _error =
              'Failed to fetch announcements (Status: ${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch announcements: $e';
        _loading = false;
      });
    }
  }

  Future<void> _addAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final res = await apiService.post('/announcements', {
          'title': _title,
          'message': _message,
          'priority': 'Medium',
        });

        if (res.statusCode == 200 || res.statusCode == 201) {
          // Refresh announcements from backend
          await _fetchAnnouncements();

          setState(() {
            _title = null;
            _message = null;
            _showForm = false;
          });
          _formKey.currentState!.reset();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Announcement added successfully!',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to add announcement (Status: ${res.statusCode})\nResponse: ${res.body}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Network error while adding announcement: $e',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            Text(
              'Delete Announcement',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this announcement?',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                print('Calling delete API with ID: $id'); // Temporary debug
                final res = await apiService.delete('/announcements/$id');
                print(
                  'Delete API response: ${res.statusCode} - ${res.body}',
                ); // Temporary debug

                if (res.statusCode == 200 || res.statusCode == 204) {
                  // Remove from local list
                  setState(() {
                    announcements.removeWhere((ann) => ann['_id'] == id);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'Announcement deleted successfully',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'Failed to delete announcement',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Network error while deleting announcement',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade50,
              Colors.indigo.shade50,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.announcement,
                            color: Colors.purple.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Announcements',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              Text(
                                'Stay updated with company announcements',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _fetchAnnouncements,
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.purple.shade600,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _showForm ? Icons.close : Icons.add,
                              color: Colors.purple.shade600,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _showForm = !_showForm;
                                if (!_showForm) {
                                  _formKey.currentState?.reset();
                                  _title = null;
                                  _message = null;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add Announcement Form
                  if (_showForm) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.add_circle,
                                    color: Colors.purple.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Add New Announcement',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Title Field
                            TextFormField(
                              onSaved: (value) => _title = value,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please enter a title'
                                  : null,
                              decoration: InputDecoration(
                                hintText: 'Enter announcement title',
                                prefixIcon: Icon(
                                  Icons.title,
                                  color: Colors.purple.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.purple.shade600,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),

                            const SizedBox(height: 16),

                            // Message Field
                            TextFormField(
                              onSaved: (value) => _message = value,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please enter a message'
                                  : null,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Enter announcement message',
                                prefixIcon: Icon(
                                  Icons.message,
                                  color: Colors.purple.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.purple.shade600,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),

                            const SizedBox(height: 20),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _addAnnouncement,
                                icon: Icon(Icons.send, size: 20),
                                label: Text(
                                  'Add Announcement',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  shadowColor: Colors.purple.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Announcements List
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Announcements',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _showForm
                              ? Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.add_circle,
                                                color: Colors.purple.shade600,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Add New Announcement',
                                              style: GoogleFonts.poppins(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.purple.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),

                                        // Title Field
                                        TextFormField(
                                          onSaved: (value) => _title = value,
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                              ? 'Please enter a title'
                                              : null,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Enter announcement title',
                                            prefixIcon: Icon(
                                              Icons.title,
                                              color: Colors.purple.shade600,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.purple.shade600,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                          ),
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Message Field
                                        TextFormField(
                                          onSaved: (value) => _message = value,
                                          validator: (value) =>
                                              value == null || value.isEmpty
                                              ? 'Please enter a message'
                                              : null,
                                          maxLines: 4,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Enter announcement message',
                                            prefixIcon: Icon(
                                              Icons.message,
                                              color: Colors.purple.shade600,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: Colors.purple.shade600,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 16,
                                                ),
                                          ),
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        // Action Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: _addAnnouncement,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.purple.shade600,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Add Announcement',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _showForm = false;
                                                    _title = null;
                                                    _message = null;
                                                  });
                                                  _formKey.currentState!
                                                      .reset();
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.grey.shade600,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  side: BorderSide(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Cancel',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchAnnouncements,
                                  child: _loading
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.purple.shade600,
                                          ),
                                        )
                                      : _error != null
                                      ? Center(
                                          child: Text(
                                            _error!,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.red.shade600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : announcements.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No announcements yet',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                          ),
                                          itemCount: announcements.length,
                                          itemBuilder: (context, index) {
                                            final ann = announcements[index];
                                            final priorityColor =
                                                _getPriorityColor(
                                                  ann['priority']?.toString() ??
                                                      'Medium',
                                                );
                                            return _buildAnnouncementCard(ann);
                                          },
                                        ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> ann) {
    final priorityColor = _getPriorityColor(
      ann['priority']?.toString() ?? 'Medium',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.announcement, color: priorityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ann['title'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ann['date'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ann['time'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  ann['priority'] ?? 'Medium',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            ann['message'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  print(
                    'Delete button pressed for announcement: $ann',
                  ); // Temporary debug
                  // MongoDB uses _id field, not id
                  final announcementId = ann['_id']?.toString();
                  print(
                    'Resolved announcement ID: $announcementId',
                  ); // Temporary debug
                  if (announcementId != null && announcementId.isNotEmpty) {
                    _deleteAnnouncement(announcementId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Cannot delete: Invalid announcement ID',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: Colors.red.shade600,
                      ),
                    );
                  }
                },
                icon: Icon(Icons.delete, size: 18, color: Colors.red.shade600),
                label: Text(
                  'Delete',
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
