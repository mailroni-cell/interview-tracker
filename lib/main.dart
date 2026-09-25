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
      title: 'Job Tracker Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: SplashScreen(),
      ),
    );
  }
}

// ----------------------------------------------------
// מסך פתיחה - 5 שניות
// ----------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Directionality(
              textDirection: TextDirection.rtl,
              child: InterviewListScreen(),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.work_history_rounded,
                size: 76,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Job Tracker Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ניהול ומעקב ראיונות עבודה חכם',
              style: TextStyle(
                color: Colors.indigo.shade100,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.only(bottom: 36),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Text(
                'פותח ע"י רוני שניידר • גרסה 1.2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// מודל נתונים מעודכן
// ----------------------------------------------------
class InterviewItem {
  String id;
  String company;
  String position;
  DateTime dateTime;
  String status;
  String platform;
  String contactName;
  String contactPhone;
  String locationOrLink;
  String notes;
  bool isOnline;
  bool hasHomeAssignment;
  bool salaryCoordinated;
  String agreedSalary;
  bool isHybrid;
  int homeDaysPerWeek;
  int totalWorkDaysPerWeek;
  String workHours;
  String vehicleBenefit;
  bool hasStudyFund;
  String studyFundStart;
  String mealBenefit; // "תן ביס / סיבוס", "חדר אוכל", "אש\"ל / החזר יומי", "ללא סבסוד"

  InterviewItem({
    required this.id,
    required this.company,
    required this.position,
    required this.dateTime,
    this.status = 'נקבע',
    this.platform = 'זום',
    this.contactName = '',
    this.contactPhone = '',
    this.locationOrLink = '',
    this.notes = '',
    this.isOnline = true,
    this.hasHomeAssignment = false,
    this.salaryCoordinated = false,
    this.agreedSalary = '',
    this.isHybrid = false,
    this.homeDaysPerWeek = 2,
    this.totalWorkDaysPerWeek = 5,
    this.workHours = 'משרה מלאה (8:00–17:00)',
    this.vehicleBenefit = 'ללא רכב',
    this.hasStudyFund = false,
    this.studyFundStart = 'מהיום הראשון',
    this.mealBenefit = 'ללא סבסוד',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'position': position,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'platform': platform,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'locationOrLink': locationOrLink,
      'notes': notes,
      'isOnline': isOnline,
      'hasHomeAssignment': hasHomeAssignment,
      'salaryCoordinated': salaryCoordinated,
      'agreedSalary': agreedSalary,
      'isHybrid': isHybrid,
      'homeDaysPerWeek': homeDaysPerWeek,
      'totalWorkDaysPerWeek': totalWorkDaysPerWeek,
      'workHours': workHours,
      'vehicleBenefit': vehicleBenefit,
      'hasStudyFund': hasStudyFund,
      'studyFundStart': studyFundStart,
      'mealBenefit': mealBenefit,
    };
  }

  factory InterviewItem.fromMap(Map<String, dynamic> map) {
    return InterviewItem(
      id: map['id'],
      company: map['company'],
      position: map['position'],
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'נקבע',
      platform: map['platform'] ?? (map['isOnline'] == false ? 'פרונטלי' : 'זום'),
      contactName: map['contactName'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      locationOrLink: map['locationOrLink'] ?? '',
      notes: map['notes'] ?? '',
      isOnline: map['isOnline'] ?? true,
      hasHomeAssignment: map['hasHomeAssignment'] ?? false,
      salaryCoordinated: map['salaryCoordinated'] ?? false,
      agreedSalary: map['agreedSalary'] ?? '',
      isHybrid: map['isHybrid'] ?? false,
      homeDaysPerWeek: map['homeDaysPerWeek'] ?? 2,
      totalWorkDaysPerWeek: map['totalWorkDaysPerWeek'] ?? 5,
      workHours: map['workHours'] ?? 'משרה מלאה (8:00–17:00)',
      vehicleBenefit: map['vehicleBenefit'] ?? 'ללא רכב',
      hasStudyFund: map['hasStudyFund'] ?? false,
      studyFundStart: map['studyFundStart'] ?? 'מהיום הראשון',
      mealBenefit: map['mealBenefit'] ?? 'ללא סבסוד',
    );
  }
}

// ----------------------------------------------------
// המסך הראשי
// ----------------------------------------------------
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

  String _getHebrewDateString(DateTime date) {
    const days = ['שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת', 'ראשון'];
    const months = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return 'יום $dayName, ${date.day} ב$monthName ${date.year}';
  }

  Future<void> _addToCalendar(InterviewItem item) async {
    final startTime = item.dateTime.millisecondsSinceEpoch;
    final endTime = item.dateTime.add(const Duration(hours: 1)).millisecondsSinceEpoch;
    final title = Uri.encodeComponent('ראיון (${item.platform}): ${item.company} - ${item.position}');

    String descText = 'פלטפורמה: ${item.platform}\n';
    if (item.contactName.isNotEmpty) descText += 'איש קשר: ${item.contactName} ${item.contactPhone}\n';
    if (item.salaryCoordinated && item.agreedSalary.isNotEmpty) descText += 'שכר: ${item.agreedSalary}\n';
    if (item.vehicleBenefit != 'ללא רכב') descText += 'רכב: ${item.vehicleBenefit}\n';
    if (item.mealBenefit != 'ללא סבסוד') descText += 'הסעדה: ${item.mealBenefit}\n';
    if (item.hasStudyFund) descText += 'קרן השתלמות: ${item.studyFundStart}\n';
    if (item.isHybrid) descText += 'מתכונת: היברידי (${item.homeDaysPerWeek} ימים מהבית)\n';
    if (item.notes.isNotEmpty) descText += 'הערות: ${item.notes}\n';

    final desc = Uri.encodeComponent(descText);
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

  Future<void> _openMeetingLink(String link) async {
    if (link.isEmpty) return;
    String cleanUrl = link.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final uri = Uri.parse(cleanUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
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

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'זום':
        return Colors.blue.shade700;
      case 'טימס':
        return Colors.deepPurple.shade600;
      case 'Google Meet':
        return Colors.teal.shade700;
      default:
        return Colors.brown.shade700;
    }
  }

  Widget _buildWelcomeHero() {
    final now = DateTime.now();
    final todayCount = _interviews.where((i) {
      return i.dateTime.year == now.year &&
          i.dateTime.month == now.month &&
          i.dateTime.day == now.day;
    }).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'מעקב ראיונות עבודה',
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getHebrewDateString(now),
                    style: TextStyle(color: Colors.indigo.shade100, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  todayCount > 0 ? Icons.notification_important_rounded : Icons.check_circle_outline_rounded,
                  color: Colors.amberAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  todayCount > 0 ? 'יש לך $todayCount ראיונות מתוכננים להיום!' : 'אין ראיונות מתוכננים להיום',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final total = _interviews.length;
    final success = _interviews.where((i) => i.status == 'עבר בהצלחה').length;
    final pending = _interviews.where((i) => i.status == 'ממתין לתשובה' || i.status == 'נקבע').length;
    final rejected = _interviews.where((i) => i.status == 'בוטל/נדחה').length;
    final successRate = total > 0 ? ((success / total) * 100).toStringAsFixed(0) : '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'מדדי גיוס והתקדמות',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$successRate% מעבר',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStat('סך הכל', total.toString(), Icons.folder_shared_outlined, Colors.indigo),
              const SizedBox(width: 8),
              _buildStat('בתהליך', pending.toString(), Icons.hourglass_empty_rounded, Colors.orange),
              const SizedBox(width: 8),
              _buildStat('הצלחה', success.toString(), Icons.verified_outlined, Colors.green),
              const SizedBox(width: 8),
              _buildStat('נדחה', rejected.toString(), Icons.cancel_outlined, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.shade700, size: 18),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color.shade900)),
            Text(label, style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.w600)),
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
        title: const Text('Job Tracker Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildWelcomeHero()),
          SliverToBoxAdapter(child: _buildDashboard()),
          if (_interviews.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_outline_rounded, size: 60, color: Colors.indigo.shade200),
                    const SizedBox(height: 12),
                    const Text('אין ראיונות ברשימה', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('לחץ על "ראיון חדש" כדי להתחיל לתעד בקלות!', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _interviews[index];
                    final statusColor = _getStatusColor(item.status);
                    final platformColor = _getPlatformColor(item.platform);

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
                                  child: Icon(Icons.business_rounded, color: Colors.indigo.shade700, size: 24),
                                ),
                                const SizedBox(width: 10),
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
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 15, color: Colors.indigo.shade400),
                                const SizedBox(width: 6),
                                Text(dateFormat.format(item.dateTime), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: platformColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        item.platform == 'פרונטלי' ? Icons.location_on_outlined : Icons.videocam_rounded,
                                        size: 13,
                                        color: platformColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.platform,
                                        style: TextStyle(fontSize: 11, color: platformColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
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
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (item.salaryCoordinated)
                                  Chip(
                                    avatar: const Icon(Icons.payments_outlined, size: 14, color: Colors.teal),
                                    label: Text(
                                      item.agreedSalary.isNotEmpty ? 'שכר: ${item.agreedSalary}' : 'שכר: סוכם',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                                    ),
                                    backgroundColor: Colors.teal.shade50,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (item.vehicleBenefit != 'ללא רכב')
                                  Chip(
                                    avatar: const Icon(Icons.directions_car_rounded, size: 14, color: Colors.indigo),
                                    label: Text(
                                      item.vehicleBenefit,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
                                    ),
                                    backgroundColor: Colors.indigo.shade50,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (item.mealBenefit != 'ללא סבסוד')
                                  Chip(
                                    avatar: const Icon(Icons.restaurant_rounded, size: 14, color: Colors.deepOrange),
                                    label: Text(
                                      item.mealBenefit,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                                    ),
                                    backgroundColor: Colors.deepOrange.shade50,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (item.hasStudyFund)
                                  Chip(
                                    avatar: const Icon(Icons.savings_outlined, size: 14, color: Colors.amber.shade900),
                                    label: Text(
                                      'קרן השתלמות: ${item.studyFundStart}',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                    ),
                                    backgroundColor: Colors.amber.shade50,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (item.isHybrid)
                                  Chip(
                                    avatar: const Icon(Icons.home_work_outlined, size: 14, color: Colors.deepPurple),
                                    label: Text(
                                      'היברידי (${item.homeDaysPerWeek} ימים מהבית)',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                    ),
                                    backgroundColor: Colors.deepPurple.shade50,
                                    visualDensity: VisualDensity.compact,
                                  )
                                else
                                  Chip(
                                    avatar: const Icon(Icons.apartment_rounded, size: 14, color: Colors.blueGrey),
                                    label: const Text('מהמשרד בלבד', style: TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.blueGrey.shade50,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                Chip(
                                  avatar: const Icon(Icons.calendar_view_week_rounded, size: 14, color: Colors.blueGrey),
                                  label: Text('${item.totalWorkDaysPerWeek} ימים בשבוע', style: const TextStyle(fontSize: 11)),
                                  backgroundColor: Colors.grey.shade100,
                                  visualDensity: VisualDensity.compact,
                                ),
                                if (item.hasHomeAssignment)
                                  Chip(
                                    label: const Text('מבחן בית: הוגש', style: TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.amber.shade50,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (item.locationOrLink.contains('http'))
                                  TextButton.icon(
                                    onPressed: () => _openMeetingLink(item.locationOrLink),
                                    icon: const Icon(Icons.video_call_rounded, size: 18, color: Colors.indigo),
                                    label: Text(
                                      'כנס ל-${item.platform}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                    ),
                                  ),
                                TextButton.icon(
                                  onPressed: () => _addToCalendar(item),
                                  icon: const Icon(Icons.event_available_rounded, size: 18),
                                  label: const Text('ליומן'),
                                ),
                                if (item.contactPhone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.phone_rounded, color: Colors.green),
                                    onPressed: () => _callPhone(item.contactPhone),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _addOrEditInterview(item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
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
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 24, bottom: 120),
              child: Center(
                child: Text(
                  'פותח ע"י רוני שניידר • גרסה 1.2',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
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

// ----------------------------------------------------
// טופס מהיר עם שכר, רכב, הסעדה, קרן השתלמות, היברידיות ושעות
// ----------------------------------------------------
class InterviewFormScreen extends StatefulWidget {
  final InterviewItem? item;
  const InterviewFormScreen({super.key, this.item});

  @override
  State<InterviewFormScreen> createState() => _InterviewFormScreenState();
}

class _InterviewFormScreenState extends State<InterviewFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyController;
  late TextEditingController _positionController;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _salaryController;

  late DateTime _dateTime;
  late String _status;
  late String _platform;
  late bool _hasHomeAssignment;
  late bool _salaryCoordinated;
  late bool _isHybrid;
  late int _homeDaysPerWeek;
  late int _totalWorkDaysPerWeek;
  late String _workHours;
  late String _vehicleBenefit;
  late bool _hasStudyFund;
  late String _studyFundStart;
  late String _mealBenefit;

  final List<String> _statusOptions = ['נקבע', 'התקיים', 'ממתין לתשובה', 'עבר בהצלחה', 'בוטל/נדחה'];
  final List<String> _platformOptions = ['זום', 'טימס', 'Google Meet', 'פרונטלי'];
  final List<String> _vehicleOptions = ['ללא רכב', 'רכב חברה / ליסינג', 'אחזקת רכב'];
  final List<String> _mealOptions = ['ללא סבסוד', 'תן ביס / סיבוס', 'חדר אוכל', 'אש"ל / החזר יומי'];
  final List<String> _studyFundOptions = ['מהיום הראשון', 'אחרי 3 חודשים', 'אחרי 6 חודשים'];
  final List<String> _workHoursOptions = [
    'משרה מלאה (8:00–17:00)',
    'משרה מלאה (9:00–18:00)',
    'גמיש / לפי משימות',
    'משמרות / כוננויות'
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _companyController = TextEditingController(text: item?.company ?? '');
    _positionController = TextEditingController(text: item?.position ?? '');
    _contactNameController = TextEditingController(text: item?.contactName ?? '');
    _contactPhoneController = TextEditingController(text: item?.contactPhone ?? '');
    _locationController = TextEditingController(text: item?.locationOrLink ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _salaryController = TextEditingController(text: item?.agreedSalary ?? '');

    _dateTime = item?.dateTime ?? DateTime.now().add(const Duration(days: 1));
    _status = item?.status ?? 'נקבע';
    _platform = item?.platform ?? 'זום';
    _hasHomeAssignment = item?.hasHomeAssignment ?? false;
    _salaryCoordinated = item?.salaryCoordinated ?? false;
    _isHybrid = item?.isHybrid ?? false;
    _homeDaysPerWeek = item?.homeDaysPerWeek ?? 2;
    _totalWorkDaysPerWeek = item?.totalWorkDaysPerWeek ?? 5;
    _workHours = item?.workHours ?? 'משרה מלאה (8:00–17:00)';
    _vehicleBenefit = item?.vehicleBenefit ?? 'ללא רכב';
    _hasStudyFund = item?.hasStudyFund ?? false;
    _studyFundStart = item?.studyFundStart ?? 'מהיום הראשון';
    _mealBenefit = item?.mealBenefit ?? 'ללא סבסוד';
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _salaryController.dispose();
    super.dispose();
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
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _companyController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'שם החברה *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'שדה חובה' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _positionController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'תפקיד *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline_rounded),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'שדה חובה' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Colors.indigo),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('מועד הראיון', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(dateFormat.format(_dateTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_calendar, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('סוג הפגישה:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _platformOptions.map((plat) {
                  final isSelected = _platform == plat;
                  return ChoiceChip(
                    avatar: Icon(
                      plat == 'פרונטלי' ? Icons.location_on : Icons.videocam,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.indigo,
                    ),
                    label: Text(plat),
                    selected: isSelected,
                    selectedColor: Colors.indigo,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _platform = plat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: _platform == 'פרונטלי' ? 'כתובת הגעה / משרד' : 'קישור לפגישה (Zoom / Teams / Meet)',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_platform == 'פרונטלי' ? Icons.place_outlined : Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const Text('סטטוס הראיון:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _statusOptions.map((st) {
                  final isSelected = _status == st;
                  return ChoiceChip(
                    label: Text(st),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _status = st);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // תנאי משרה: שכר, רכב, אש"ל, קרן השתלמות והיברידיות
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.indigo.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'תנאי העסקה ושכר',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('סוכמו ציפיות שכר?'),
                      value: _salaryCoordinated,
                      onChanged: (val) => setState(() => _salaryCoordinated = val),
                    ),
                    if (_salaryCoordinated) ...[
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _salaryController,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: 'השכר שנקבע (למשל: 30,000 ש"ח ברוטו / נטו)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payments_outlined, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Divider(),
                    const Text('תנאי רכב:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _vehicleOptions.map((veh) {
                        final isSel = _vehicleBenefit == veh;
                        return ChoiceChip(
                          avatar: Icon(
                            veh == 'ללא רכב' ? Icons.money_off_rounded : Icons.directions_car_rounded,
                            size: 16,
                            color: isSel ? Colors.white : Colors.indigo,
                          ),
                          label: Text(veh),
                          selected: isSel,
                          selectedColor: Colors.indigo,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _vehicleBenefit = veh);
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(),
                    const Text('תנאי הסעדה ואש"ל:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: _mealOptions.map((meal) {
                        final isSel = _mealBenefit == meal;
                        return ChoiceChip(
                          avatar: Icon(
                            meal == 'ללא סבסוד' ? Icons.no_meals_rounded : Icons.restaurant_rounded,
                            size: 16,
                            color: isSel ? Colors.white : Colors.deepOrange,
                          ),
                          label: Text(meal),
                          selected: isSel,
                          selectedColor: Colors.deepOrange,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _mealBenefit = meal);
                          },
                        );
                      }).toList(),
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('כולל קרן השתלמות?'),
                      value: _hasStudyFund,
                      onChanged: (val) => setState(() => _hasStudyFund = val),
                    ),
                    if (_hasStudyFund) ...[
                      const SizedBox(height: 4),
                      const Text('מועד תחילת ההפרשה:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _studyFundOptions.map((opt) {
                          final isSel = _studyFundStart == opt;
                          return ChoiceChip(
                            label: Text(opt),
                            selected: isSel,
                            selectedColor: Colors.amber.shade700,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _studyFundStart = opt);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('משרה היברידית?'),
                      value: _isHybrid,
                      onChanged: (val) => setState(() => _isHybrid = val),
                    ),
                    if (_isHybrid) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('כמה ימים מהבית בשבוע: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Wrap(
                            spacing: 4,
                            children: [1, 2, 3, 4, 5].map((d) {
                              final sel = _homeDaysPerWeek == d;
                              return ChoiceChip(
                                label: Text('$d'),
                                selected: sel,
                                onSelected: (s) {
                                  if (s) setState(() => _homeDaysPerWeek = d);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    const Divider(),
                    Row(
                      children: [
                        const Text('סה"כ ימי עבודה בשבוע: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Wrap(
                          spacing: 6,
                          children: [5, 6].map((days) {
                            final sel = _totalWorkDaysPerWeek == days;
                            return ChoiceChip(
                              label: Text('$days ימים'),
                              selected: sel,
                              onSelected: (s) {
                                if (s) setState(() => _totalWorkDaysPerWeek = days);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('מסגרת שעות עבודה:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _workHours,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _workHoursOptions.map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _workHours = val);
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('נמסר מבחן בית / משימה מקצועית?'),
                      value: _hasHomeAssignment,
                      onChanged: (val) => setState(() => _hasHomeAssignment = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _contactNameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'שם איש/אשת קשר או מגייס/ת',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'טלפון איש קשר',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'דגשים והערות נוספות',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
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
                    final newItem = InterviewItem(
                      id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      company: _companyController.text.trim(),
                      position: _positionController.text.trim(),
                      dateTime: _dateTime,
                      status: _status,
                      platform: _platform,
                      contactName: _contactNameController.text.trim(),
                      contactPhone: _contactPhoneController.text.trim(),
                      locationOrLink: _locationController.text.trim(),
                      notes: _notesController.text.trim(),
                      isOnline: _platform != 'פרונטלי',
                      hasHomeAssignment: _hasHomeAssignment,
                      salaryCoordinated: _salaryCoordinated,
                      agreedSalary: _salaryController.text.trim(),
                      isHybrid: _isHybrid,
                      homeDaysPerWeek: _homeDaysPerWeek,
                      totalWorkDaysPerWeek: _totalWorkDaysPerWeek,
                      workHours: _workHours,
                      vehicleBenefit: _vehicleBenefit,
                      hasStudyFund: _hasStudyFund,
                      studyFundStart: _studyFundStart,
                      mealBenefit: _mealBenefit,
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
