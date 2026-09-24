import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
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
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF4F6FA),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: InterviewListScreen(),
      ),
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

  Future<void> _addToCalendar(InterviewItem item) async {
    final startTime = item.dateTime.millisecondsSinceEpoch;
    final endTime = item.dateTime.add(const Duration(hours: 1)).millisecondsSinceEpoch;
    final title = Uri.encodeComponent('ראיון: ${item.company} - ${item.position}');
    final desc = Uri.encodeComponent('איש קשר: ${item.contactName} ${item.contactPhone}\n${item.notes}');
    final loc = Uri.encodeComponent(item.locationOrLink);

    final calendarUri = Uri.parse(
      'content://com.android.calendar/time/$startTime?action=android.intent.action.INSERT&title=$title&description=$desc&eventLocation=$loc&beginTime=$startTime&endTime=$endTime',
    );

    if (await canLaunchUrl(calendarUri)) {
      await launchUrl(calendarUri);
    } else {
      final googleUrl = Uri.parse(
        'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&details=$desc&location=$loc',
      );
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _addOrEditInterview([InterviewItem? item]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: InterviewFormScreen(item: item),
        ),
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
        return const Color(0xFF10B981);
      case 'בוטל/נדחה':
        return const Color(0xFFEF4444);
      case 'ממתין לתשובה':
        return const Color(0xFFF59E0B);
      case 'התקיים':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Widget _buildDashboard() {
    final total = _interviews.length;
    final success = _interviews.where((i) => i.status == 'עבר בהצלחה').length;
    final pending = _interviews.where((i) => i.status == 'ממתין לתשובה' || i.status == 'נקבע').length;
    final rejected = _interviews.where((i) => i.status == 'בוטל/נדחה').length;

    final successRate = total > 0 ? ((success / total) * 100).toStringAsFixed(0) : '0';

    InterviewItem? nextInterview;
    final now = DateTime.now();
    for (var item in _interviews) {
      if (item.dateTime.isAfter(now)) {
        nextInterview = item;
        break;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'לוח בקרה ומדדים',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'הצלחה: $successRate%',
                  style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('סך הכול', total.toString(), Icons.folder_open_rounded, Colors.blue),
              const SizedBox(width: 8),
              _buildStatCard('בתהליך', pending.toString(), Icons.hourglass_top_rounded, Colors.orange),
              const SizedBox(width: 8),
              _buildStatCard('הצלחה', success.toString(), Icons.check_circle_outline_rounded, Colors.green),
              const SizedBox(width: 8),
              _buildStatCard('נדחה', rejected.toString(), Icons.cancel_outlined, Colors.red),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (success > 0)
                      Expanded(flex: success, child: Container(color: const Color(0xFF10B981))),
                    if (pending > 0)
                      Expanded(flex: pending, child: Container(color: const Color(0xFFF59E0B))),
                    if (rejected > 0)
                      Expanded(flex: rejected, child: Container(color: const Color(0xFFEF4444))),
                    if (total - (success + pending + rejected) > 0)
                      Expanded(
                        flex: total - (success + pending + rejected),
                        child: Container(color: const Color(0xFF6366F1)),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (nextInterview != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm_on_rounded, color: Colors.indigo.shade600, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'הראיון הבא: ${nextInterview.company}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy • HH:mm').format(nextInterview.dateTime),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.shade700, size: 20),
            const SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.shade900),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: color.shade700, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('מעקב ראיונות עבודה', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildDashboard(),
          ),
          if (_interviews.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note_outlined, size: 64, color: Colors.indigo.shade200),
                    const SizedBox(height: 12),
                    const Text(
                      'אין ראיונות שמורים כרגע',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('הוסף ראיון כדי להפעיל את לוח המדדים', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _interviews[index];
                    final statusColor = _getStatusColor(item.status);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.business_rounded, color: Colors.indigo.shade700, size: 26),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.company,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                      ),
                                      Text(
                                        item.position,
                                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 22),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 15, color: Colors.indigo.shade400),
                                const SizedBox(width: 6),
                                Text(
                                  dateFormat.format(item.dateTime),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                            if (item.contactName.isNotEmpty || item.contactPhone.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 15, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item.contactName} ${item.contactPhone.isNotEmpty ? '• ${item.contactPhone}' : ''}',
                                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                            if (item.locationOrLink.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.place_outlined, size: 15, color: Colors.grey.shade600),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.locationOrLink,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (item.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.notes,
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _addToCalendar(item),
                                  icon: const Icon(Icons.event_available_rounded, size: 18),
                                  label: const Text('ליומן'),
                                ),
                                if (item.contactPhone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.phone_rounded, color: Colors.green),
                                    tooltip: 'התקשר',
                                    onPressed: () => _callPhone(item.contactPhone),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'ערוך',
                                  onPressed: () => _addOrEditInterview(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'מחק',
                                  onPressed: () => _deleteInterview(item.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _interviews.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditInterview(),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('ראיון חדש', style: TextStyle(fontWeight: FontWeight.bold)),
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
        title: Text(widget.item == null ? 'הוספת ראיון חדש' : 'עריכת פרטי ראיון'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _company,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'שם החברה *',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.business),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'שדה חובה' : null,
                onSaved: (val) => _company = val!.trim(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: _position,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'תפקיד *',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.work_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'שדה חובה' : null,
                onSaved: (val) => _position = val!.trim(),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('מועד הראיון', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              dateFormat.format(_dateTime),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_calendar, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _status,
                isExpanded: true,
                alignment: AlignmentDirectional.centerStart,
                decoration: const InputDecoration(
                  labelText: 'סטטוס',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.flag_outlined),
                ),
                items: _statusOptions
                    .map((s) => DropdownMenuItem(
                          value: s,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(s, textAlign: TextAlign.right),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: _contactName,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'איש / אשת קשר',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.person_outline),
                ),
                onSaved: (val) => _contactName = val?.trim() ?? '',
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: _contactPhone,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'טלפון איש קשר',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.phone_outlined),
                ),
                onSaved: (val) => _contactPhone = val?.trim() ?? '',
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: _locationOrLink,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'מיקום פיזי / קישור לפגישה (Zoom, Teams)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.link_rounded),
                ),
                onSaved: (val) => _locationOrLink = val?.trim() ?? '',
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: _notes,
                maxLines: 3,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'דגשים, ציפיות שכר והערות',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  suffixIcon: Icon(Icons.note_alt_outlined),
                ),
                onSaved: (val) => _notes = val?.trim() ?? '',
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                child: const Text('שמור ראיון', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
