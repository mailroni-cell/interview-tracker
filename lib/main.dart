import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const InterviewApp());
}

class InterviewApp extends StatelessWidget {
  const InterviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'מעקב ראיונות עבודה',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const InterviewListScreen(),
    );
  }
}

class InterviewItem {
  String id;
  String company;
  String position;
  DateTime dateTime;
  String status;
  String contactName;
  String contactPhone;
  String locationOrLink;
  String notes;

  InterviewItem({
    required this.id,
    required this.company,
    required this.position,
    required this.dateTime,
    this.status = 'נקבע',
    this.contactName = '',
    this.contactPhone = '',
    this.locationOrLink = '',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'position': position,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'locationOrLink': locationOrLink,
      'notes': notes,
    };
  }

  factory InterviewItem.fromMap(Map<String, dynamic> map) {
    return InterviewItem(
      id: map['id'],
      company: map['company'],
      position: map['position'],
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'נקבע',
      contactName: map['contactName'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      locationOrLink: map['locationOrLink'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}

class InterviewListScreen extends StatefulWidget {
  const InterviewListScreen({super.key});

  @override
  State<InterviewListScreen> createState() => _InterviewListScreenState();
}

class _InterviewListScreenState extends State<InterviewListScreen> {
  List<InterviewItem> _interviews = [];

  @override
  void initState() {
    super.initState();
    _loadInterviews();
  }

  Future<void> _loadInterviews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('saved_interviews');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        _interviews = decoded.map((e) => InterviewItem.fromMap(e)).toList();
        _interviews.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
    }
  }

  Future<void> _saveInterviews() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_interviews.map((e) => e.toMap()).toList());
    await prefs.setString('saved_interviews', encoded);
  }

  void _addOrEditInterview([InterviewItem? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewFormScreen(item: item),
      ),
    );

    if (result != null && result is InterviewItem) {
      setState(() {
        if (item != null) {
          final index = _interviews.indexWhere((e) => e.id == item.id);
          if (index != -1) _interviews[index] = result;
        } else {
          _interviews.add(result);
        }
        _interviews.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
      _saveInterviews();
    }
  }

  void _deleteInterview(String id) {
    setState(() {
      _interviews.removeWhere((item) => item.id == id);
    });
    _saveInterviews();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'עבר בהצלחה':
        return Colors.green;
      case 'בוטל/נדחה':
        return Colors.red;
      case 'ממתין לתשובה':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מעקב ראיונות עבודה'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _interviews.isEmpty
          ? const Center(
              child: Text(
                'אין כרגע ראיונות ברשימה.\nלחץ על הפלוס כדי להוסיף ראיון חדש!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _interviews.length,
              itemBuilder: (context, index) {
                final item = _interviews[index];
                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.company,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(item.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              color: _getStatusColor(item.status),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('תפקיד: ${item.position}', style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(dateFormat.format(item.dateTime), style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        if (item.contactName.isNotEmpty || item.contactPhone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('איש קשר: ${item.contactName} (${item.contactPhone})'),
                        ],
                        if (item.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('הערות: ${item.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                    trailing: PopupMenuButton(
                      onSelected: (val) {
                        if (val == 'edit') _addOrEditInterview(item);
                        if (val == 'delete') _deleteInterview(item.id);
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('ערוך')),
                        const PopupMenuItem(value: 'delete', child: Text('מחק')),
                      ],
                    ),
                    onTap: () => _addOrEditInterview(item),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditInterview(),
        icon: const Icon(Icons.add),
        label: const Text('ראיון חדש'),
      ),
    );
  }
}

class InterviewFormScreen extends StatefulWidget {
  final InterviewItem? item;
  const InterviewFormScreen({super.key, this.item});

  @override
  State<InterviewFormScreen> createState() => _InterviewFormScreenState();
}

class _InterviewFormScreenState extends State<InterviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _company;
  late String _position;
  late DateTime _dateTime;
  late String _status;
  late String _contactName;
  late String _contactPhone;
  late String _locationOrLink;
  late String _notes;

  final List<String> _statusOptions = [
    'נקבע',
    'התקיים',
    'ממתין לתשובה',
    'עבר בהצלחה',
    'בוטל/נדחה',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _company = item?.company ?? '';
    _position = item?.position ?? '';
    _dateTime = item?.dateTime ?? DateTime.now().add(const Duration(days: 1));
    _status = item?.status ?? 'נקבע';
    _contactName = item?.contactName ?? '';
    _contactPhone = item?.contactPhone ?? '';
    _locationOrLink = item?.locationOrLink ?? '';
    _notes = item?.notes ?? '';
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (pickedTime == null) return;

    setState(() {
      _dateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'הוספת ראיון' : 'עריכת ראיון'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _company,
                decoration: const InputDecoration(labelText: 'שם החברה *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'שדה חובה' : null,
                onSaved: (val) => _company = val!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _position,
                decoration: const InputDecoration(labelText: 'תפקיד *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.trim().isEmpty ? 'שדה חובה' : null,
                onSaved: (val) => _position = val!.trim(),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                leading: const Icon(Icons.calendar_today),
                title: Text('מועד הראיון: ${dateFormat.format(_dateTime)}'),
                trailing: TextButton(
                  onPressed: _pickDateTime,
                  child: const Text('שנה מועד'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'סטטוס', border: OutlineInputBorder()),
                items: _statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _contactName,
                decoration: const InputDecoration(labelText: 'שם איש קשר / מגייסת', border: OutlineInputBorder()),
                onSaved: (val) => _contactName = val?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _contactPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'טלפון איש קשר', border: OutlineInputBorder()),
                onSaved: (val) => _contactPhone = val?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _locationOrLink,
                decoration: const InputDecoration(labelText: 'מיקום / קישור ל-Zoom או Teams', border: OutlineInputBorder()),
                onSaved: (val) => _locationOrLink = val?.trim() ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'הערות ודגשים לקראת הראיון', border: OutlineInputBorder()),
                onSaved: (val) => _notes = val?.trim() ?? '',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final newItem = InterviewItem(
                        id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        company: _company,
                        position: _position,
                        dateTime: _dateTime,
                        status: _status,
                        contactName: _contactName,
                        contactPhone: _contactPhone,
                        locationOrLink: _locationOrLink,
                        notes: _notes,
                      );
                      Navigator.pop(context, newItem);
                    }
                  },
                  child: const Text('שמור ראיון', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
