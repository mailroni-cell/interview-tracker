import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const InterviewTrackerApp());
}

class InterviewTrackerApp extends StatelessWidget {
  const InterviewTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'מעקב ראיונות',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomeScreen(),
      ),
    );
  }
}

class Interview {
  String id;
  String company;
  String role;
  DateTime dateTime;
  String type;
  String contact;
  String locationOrLink;
  String status;
  String notes;

  Interview({
    required this.id,
    required this.company,
    required this.role,
    required this.dateTime,
    required this.type,
    required this.contact,
    required this.locationOrLink,
    required this.status,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'company': company,
        'role': role,
        'dateTime': dateTime.toIso8601String(),
        'type': type,
        'contact': contact,
        'locationOrLink': locationOrLink,
        'status': status,
        'notes': notes,
      };

  factory Interview.fromMap(Map<String, dynamic> map) => Interview(
        id: map['id'],
        company: map['company'],
        role: map['role'],
        dateTime: DateTime.parse(map['dateTime']),
        type: map['type'],
        contact: map['contact'] ?? '',
        locationOrLink: map['locationOrLink'] ?? '',
        status: map['status'] ?? 'נקבע ראיון ראשוני',
        notes: map['notes'] ?? '',
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Interview> _interviews = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('interviews');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        _interviews = decoded.map((e) => Interview.fromMap(e)).toList();
        _interviews.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_interviews.map((e) => e.toMap()).toList());
    await prefs.setString('interviews', encoded);
  }

  void _addOrEditInterview([Interview? item]) async {
    final result = await showModalBottomSheet<Interview>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: InterviewFormModal(item: item),
      ),
    );

    if (result != null) {
      setState(() {
        if (item == null) {
          _interviews.add(result);
        } else {
          final index = _interviews.indexWhere((e) => e.id == item.id);
          if (index != -1) _interviews[index] = result;
        }
        _interviews.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      });
      _saveData();
    }
  }

  void _deleteInterview(String id) {
    setState(() {
      _interviews.removeWhere((e) => e.id == id);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _interviews.where((e) => e.dateTime.isAfter(DateTime.now())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: const Text('מעקב ראיונות עבודה', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E2E),
        centerTitle: true,
      ),
      body: _interviews.isEmpty
          ? const Center(
              child: Text(
                'אין עדיין ראיונות ברשימה.\nלחץ על + למטה כדי להוסיף ראיון ראשון!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  Card(
                    color: Colors.indigo.shade900.withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 20),
                              SizedBox(width: 8),
                              Text('הראיון הקרוב ביותר', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text('${upcoming.first.company} - ${upcoming.first.role}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, dd/MM/yyyy HH:mm', 'he').format(upcoming.first.dateTime),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('כל הראיונות', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._interviews.map((item) => _buildInterviewCard(item)),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditInterview(),
        backgroundColor: Colors.indigoAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ראיון חדש', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInterviewCard(Interview item) {
    final isUpcoming = item.dateTime.isAfter(DateTime.now());

    return Card(
      color: const Color(0xFF1E1E2E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(item.company, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.role, style: const TextStyle(color: Colors.indigoAccent, fontSize: 15)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: isUpcoming ? Colors.greenAccent : Colors.white38),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(item.dateTime),
                  style: TextStyle(color: isUpcoming ? Colors.greenAccent : Colors.white38),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text(item.status, style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: Colors.white12,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            if (item.contact.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('איש קשר: ${item.contact}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
            if (item.locationOrLink.isNotEmpty) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final uri = Uri.tryParse(item.locationOrLink);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                child: Text(
                  item.locationOrLink,
                  style: const TextStyle(color: Colors.lightBlueAccent, decoration: TextDecoration.underline, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (item.notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('דגשים: ${item.notes}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
            ]
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white60),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('ערוך')),
            const PopupMenuItem(value: 'delete', child: Text('מחק', style: TextStyle(color: Colors.redAccent))),
          ],
          onSelected: (val) {
            if (val == 'edit') _addOrEditInterview(item);
            if (val == 'delete') _deleteInterview(item.id);
          },
        ),
      ),
    );
  }
}

class InterviewFormModal extends StatefulWidget {
  final Interview? item;
  const InterviewFormModal({super.key, this.item});

  @override
  State<InterviewFormModal> createState() => _InterviewFormModalState();
}

class _InterviewFormModalState extends State<InterviewFormModal> {
  final _formKey = GlobalKey<FormState>();
  late String _company;
  late String _role;
  late DateTime _dateTime;
  late String _type;
  late String _contact;
  late String _locationOrLink;
  late String _status;
  late String _notes;

  @override
  void initState() {
    super.initState();
    _company = widget.item?.company ?? '';
    _role = widget.item?.role ?? '';
    _dateTime = widget.item?.dateTime ?? DateTime.now().add(const Duration(days: 1));
    _type = widget.item?.type ?? 'זום';
    _contact = widget.item?.contact ?? '';
    _locationOrLink = widget.item?.locationOrLink ?? '';
    _status = widget.item?.status ?? 'נקבע ראיון ראשוני';
    _notes = widget.item?.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.item == null ? 'הוספת ראיון חדש' : 'עריכת ראיון',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _company,
                decoration: const InputDecoration(labelText: 'שם החברה', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'נא להזין חברה' : null,
                onSaved: (val) => _company = val!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'תפקיד', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'נא להזין תפקיד' : null,
                onSaved: (val) => _role = val!,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('מועד: ${DateFormat('dd/MM/yyyy HH:mm').format(_dateTime)}'),
                trailing: const Icon(Icons.edit_calendar, color: Colors.indigoAccent),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateTime,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_dateTime),
                    );
                    if (time != null) {
                      setState(() {
                        _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'סטטוס', border: OutlineInputBorder()),
                items: ['נקבע ראיון ראשוני', 'ראיון טכני', 'ראיון הנהלה', 'ממתין לתשובה', 'התקבלה הצעה', 'לא רלוונטי']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _contact,
                decoration: const InputDecoration(labelText: 'איש קשר / טלפון', border: OutlineInputBorder()),
                onSaved: (val) => _contact = val ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _locationOrLink,
                decoration: const InputDecoration(labelText: 'קישור לשיחה או כתובת', border: OutlineInputBorder()),
                onSaved: (val) => _locationOrLink = val ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'דגשים והערות לחזרה', border: OutlineInputBorder()),
                onSaved: (val) => _notes = val ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.indigoAccent,
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final item = Interview(
                      id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      company: _company,
                      role: _role,
                      dateTime: _dateTime,
                      type: _type,
                      contact: _contact,
                      locationOrLink: _locationOrLink,
                      status: _status,
                      notes: _notes,
                    );
                    Navigator.pop(context, item);
                  }
                },
                child: const Text('שמור ראיון', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
