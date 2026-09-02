import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/core/theme/app_theme.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/home/models/doctor.dart';
import 'package:medilink/features/home/models/booking.dart';
import 'package:medilink/features/home/providers/doctor_provider.dart';
import 'package:medilink/features/home/providers/booking_provider.dart';

class DoctorHomeScreen extends ConsumerStatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  ConsumerState<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends ConsumerState<DoctorHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Doctor? _currentDoctor;
  String? _hospitalId;
  String? _doctorId;
  bool _isLoadingDoctor = true;

  // In-memory / Realtime ERP state for Tasks, Meetings, Vitals & Thoughts
  final List<Map<String, dynamic>> _clinicalTasks = [
    {'title': 'Review Post-Op Labs for Bed 4', 'done': false, 'priority': 'High'},
    {'title': 'Sign Discharge Summary (Ward 2B)', 'done': true, 'priority': 'Normal'},
    {'title': 'Verify CT Angiography Results', 'done': false, 'priority': 'High'},
    {'title': 'Order Pre-Op Blood Crossmatch', 'done': false, 'priority': 'Urgent'},
  ];

  final List<Map<String, dynamic>> _wardPatients = [
    {
      'bed': 'ICU-02',
      'name': 'Ramesh Kumar',
      'age': '58',
      'condition': 'Post-CABG Day 2',
      'bp': '124/82',
      'pulse': '76 bpm',
      'spo2': '99%',
      'checked': true,
    },
    {
      'bed': 'Ward-14',
      'name': 'Sunita Devi',
      'age': '42',
      'condition': 'Acute Appendicitis',
      'bp': '118/76',
      'pulse': '80 bpm',
      'spo2': '98%',
      'checked': false,
    },
    {
      'bed': 'Ward-21',
      'name': 'Amit Verma',
      'age': '35',
      'condition': 'Knee Arthroscopy Post-Op',
      'bp': '120/80',
      'pulse': '72 bpm',
      'spo2': '99%',
      'checked': false,
    },
  ];

  final List<Map<String, String>> _meetings = [
    {'title': 'Morning Clinical Huddle', 'time': '08:30 AM', 'venue': 'Conference Hall A'},
    {'title': 'MDT Tumor Board Review', 'time': '02:00 PM', 'venue': 'Virtual / Room 3'},
    {'title': 'Hospital Mortality & Morbidity Audit', 'time': '04:30 PM', 'venue': 'Auditorium'},
  ];

  final List<Map<String, dynamic>> _thoughts = [
    {
      'title': 'Protocol Optimization for Sepsis',
      'content': 'Initiating early broad-spectrum antibiotics within 60 mins of triage shows 25% better recovery rate in Ward 3.',
      'date': 'Today, 10:15 AM',
    },
    {
      'title': 'Post-Op Mobilization Note',
      'content': 'Early ambulation for laparoscopic cases decreases length of stay by 1.2 days.',
      'date': 'Yesterday',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadDoctorProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingDoctor = false);
      return;
    }

    try {
      final db = FirebaseDatabase.instance.ref();
      final userSnap = await db.child('users').child(user.uid).get();

      if (userSnap.exists && userSnap.value is Map) {
        final userData = Map<String, dynamic>.from(userSnap.value as Map);
        _hospitalId = userData['hospitalId'] as String?;
        _doctorId = userData['doctorId'] as String?;
      }

      // If not in users node, check doctors across hospitals
      if (_doctorId == null || _hospitalId == null) {
        final docsSnap = await db.child('doctors').get();
        if (docsSnap.exists && docsSnap.value is Map) {
          final hospitalsMap = Map<dynamic, dynamic>.from(docsSnap.value as Map);
          for (final hKey in hospitalsMap.keys) {
            final docList = hospitalsMap[hKey];
            if (docList is Map) {
              for (final dKey in docList.keys) {
                final dData = docList[dKey];
                if (dData is Map) {
                  final email = dData['email']?.toString().toLowerCase();
                  final authUid = dData['authUid']?.toString();
                  if (email == user.email?.toLowerCase() || authUid == user.uid) {
                    _hospitalId = hKey.toString();
                    _doctorId = dKey.toString();
                    break;
                  }
                }
              }
            }
            if (_doctorId != null) break;
          }
        }
      }

      if (_hospitalId != null && _doctorId != null) {
        final doc = await ref
            .read(doctorRepositoryProvider)
            .getDoctorById(_hospitalId!, _doctorId!);
        if (mounted) {
          setState(() {
            _currentDoctor = doc;
            _isLoadingDoctor = false;
          });
        }
      } else {
        // Fallback dummy profile so doctor screen never breaks
        if (mounted) {
          setState(() {
            _currentDoctor = Doctor(
              id: 'doc_self',
              hospitalId: 'default',
              name: user.displayName ?? 'Dr. Specialist',
              specialization: 'General Medicine',
              startTime: '09:00',
              endTime: '17:00',
              slotDurationMinutes: 30,
              email: user.email,
              isAbsent: false,
            );
            _isLoadingDoctor = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDoctor = false);
    }
  }

  Future<void> _toggleAttendance(bool isAbsent) async {
    if (_currentDoctor == null) return;

    final newDoctor = _currentDoctor!.copyWith(isAbsent: isAbsent);
    setState(() => _currentDoctor = newDoctor);

    if (_hospitalId != null && _doctorId != null) {
      await ref.read(doctorControllerProvider.notifier).updateDoctorAbsentStatus(
            hospitalId: _hospitalId!,
            doctorId: _doctorId!,
            isAbsent: isAbsent,
            reason: isAbsent ? 'Doctor marked absent on app' : null,
          );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAbsent
                ? '🔴 Marked Absent: Patient bookings are halted for your schedule.'
                : '🟢 Marked Present: You are active and on-duty.',
          ),
          backgroundColor: isAbsent ? AppColors.error : AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDoctor) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final doctor = _currentDoctor!;
    final isAbsent = doctor.isAbsent;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.cardLight,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  doctor.name,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAbsent
                        ? AppColors.error.withOpacity(0.15)
                        : AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAbsent ? 'ABSENT' : 'ON DUTY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAbsent ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${doctor.specialization} • Hospital Physician ERP',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'OPD Queue'),
            Tab(icon: Icon(Icons.medication_outlined), text: 'Digital Rx'),
            Tab(icon: Icon(Icons.airline_seat_flat_outlined), text: 'Ward Rounds'),
            Tab(icon: Icon(Icons.monetization_on_outlined), text: 'Salary & ERP'),
            Tab(icon: Icon(Icons.hub_outlined), text: 'Clinical Hub'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Attendance & Duty Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAbsent
                  ? AppColors.error.withOpacity(0.08)
                  : AppColors.success.withOpacity(0.08),
              border: Border(
                bottom: BorderSide(
                  color: isAbsent
                      ? AppColors.error.withOpacity(0.3)
                      : AppColors.success.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAbsent ? Icons.event_busy : Icons.verified_user,
                  color: isAbsent ? AppColors.error : AppColors.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAbsent ? 'You are marked Absent' : 'You are Active & Present',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isAbsent ? AppColors.error : AppColors.success,
                        ),
                      ),
                      Text(
                        isAbsent
                            ? 'Patient booking is closed. Mark Present when back.'
                            : 'Accepting OPD appointments and ward consultations.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isAbsent ? AppColors.error : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _toggleAttendance(!isAbsent),
                  icon: Icon(
                    isAbsent ? Icons.check_circle : Icons.block,
                    size: 16,
                  ),
                  label: Text(isAbsent ? 'Mark Present' : 'Mark Absent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAbsent ? AppColors.success : AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Overview Metrics Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: AppColors.cardLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Today OPD', '8', Icons.calendar_today, AppColors.primary),
                _buildStatItem('Pending', '3', Icons.pending_actions, AppColors.warning),
                _buildStatItem('Completed', '5', Icons.check_circle_outline, AppColors.success),
                _buildStatItem('In-Patients', '3', Icons.hotel, Colors.indigo),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOpdQueueTab(),
                _buildDigitalRxTab(),
                _buildWardRoundsTab(),
                _buildSalaryErpTab(doctor),
                _buildClinicalHubTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  // ==================== TAB 1: OPD QUEUE ====================
  Widget _buildOpdQueueTab() {
    if (_doctorId == null || _hospitalId == null) {
      return _buildSampleOpdList();
    }

    final bookingsAsync = ref.watch(watchBookingsByDoctorProvider((_hospitalId!, _doctorId!)));

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return _buildSampleOpdList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildAppointmentCard(
              name: 'Patient #${booking.userId.substring(0, booking.userId.length > 5 ? 5 : booking.userId.length)}',
              time: booking.time,
              date: booking.date,
              status: booking.status,
              bookingId: booking.id,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildSampleOpdList(),
    );
  }

  Widget _buildSampleOpdList() {
    final samplePatients = [
      {'name': 'Vikram Mehra', 'time': '09:30 AM', 'reason': 'Hypertension Follow-up', 'status': 'Waiting'},
      {'name': 'Pooja Sharma', 'time': '10:00 AM', 'reason': 'Chest Tightness Evaluation', 'status': 'In-Consultation'},
      {'name': 'Rajesh Gupta', 'time': '10:30 AM', 'reason': 'Routine Annual Physical', 'status': 'Completed'},
      {'name': 'Neha Patel', 'time': '11:00 AM', 'reason': 'Migraine & Vertigo', 'status': 'Waiting'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: samplePatients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = samplePatients[index];
        final isCompleted = p['status'] == 'Completed';
        final isConsulting = p['status'] == 'In-Consultation';

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isCompleted
                      ? AppColors.success.withOpacity(0.12)
                      : (isConsulting ? AppColors.warning.withOpacity(0.12) : AppColors.primary.withOpacity(0.12)),
                  child: Text(
                    p['name']!.substring(0, 1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? AppColors.success
                          : (isConsulting ? AppColors.warning : AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['name']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p['time']} • ${p['reason']}',
                        style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Consultation recorded for ${p['name']}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? Colors.grey : AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(isCompleted ? 'Done' : 'Consult'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard({
    required String name,
    required String time,
    required String date,
    required String status,
    String? bookingId,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$date • $time • Status: $status'),
        trailing: OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Appointment marked Completed')),
            );
          },
          child: const Text('Complete'),
        ),
      ),
    );
  }

  // ==================== TAB 2: DIGITAL RX ====================
  Widget _buildDigitalRxTab() {
    final patientController = TextEditingController();
    final diagnosisController = TextEditingController();
    final medController = TextEditingController();
    final dosageController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Digital Prescription Pad',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Write and dispatch prescriptions directly to the patient & pharmacy EHR.',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: patientController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name / ID',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Diagnosis',
                      prefixIcon: Icon(Icons.health_and_safety_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: medController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name (e.g. Tab Amoxicillin 500mg)',
                      prefixIcon: Icon(Icons.medication),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage & Frequency (e.g. 1-0-1 after meals, 5 days)',
                      prefixIcon: Icon(Icons.schedule),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Digital Prescription dispatched to Patient EHR & Pharmacy!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        patientController.clear();
                        diagnosisController.clear();
                        medController.clear();
                        dosageController.clear();
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Issue & Sign Digital Rx'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 3: WARD ROUNDS ====================
  Widget _buildWardRoundsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'In-Patient Ward Rounds',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${_wardPatients.where((p) => p['checked'] == true).length}/${_wardPatients.length} Done',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._wardPatients.map((p) {
          final isDone = p['checked'] == true;
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p['bed'],
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isDone ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isDone ? AppColors.success : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            p['checked'] = !isDone;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p['name']} (${p['age']} yrs)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    p['condition'],
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('BP: ${p['bp']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('Pulse: ${p['pulse']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('SpO2: ${p['spo2']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==================== TAB 4: SALARY & ERP ====================
  Widget _buildSalaryErpTab(Doctor doctor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Doctor Compensation & ERP',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        // Salary Breakdown Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Monthly Payout', style: TextStyle(fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('On Track', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '₹ 1,85,000',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 14),
                const Divider(),
                _buildPayoutRow('Base Hospital Retainer', '₹ 1,20,000'),
                _buildPayoutRow('OPD Consultation Share (86 pts)', '₹ 43,000'),
                _buildPayoutRow('In-Patient Rounds Bonus', '₹ 15,000'),
                _buildPayoutRow('Emergency On-Call Stipend', '₹ 7,000'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Duty Roster & Schedule Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hospital Duty Roster', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                _buildRosterItem('Mon - Sat', '${doctor.startTime} - ${doctor.endTime}', 'Regular OPD & Wards'),
                _buildRosterItem('Sundays', 'Closed / Off', 'No routine consultations'),
                _buildRosterItem('Slot Interval', '${doctor.slotDurationMinutes} mins / patient', 'Auto-managed slots'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutRow(String item, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(item, style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildRosterItem(String day, String time, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(note, style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  // ==================== TAB 5: CLINICAL HUB ====================
  Widget _buildClinicalHubTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Daily Tasks
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Daily Clinical Tasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: _openAddTaskDialog,
            ),
          ],
        ),
        ..._clinicalTasks.map((t) {
          final done = t['done'] as bool;
          return CheckboxListTile(
            value: done,
            dense: true,
            title: Text(
              t['title'] as String,
              style: TextStyle(
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? Colors.grey : AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text('Priority: ${t['priority']}', style: const TextStyle(fontSize: 11)),
            onChanged: (val) {
              setState(() => t['done'] = val ?? false);
            },
          );
        }),
        const Divider(height: 24),

        // Hospital Meetings
        const Text('Hospital Meetings & Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ..._meetings.map((m) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.event_note, color: AppColors.primary),
              title: Text(m['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('${m['time']} • ${m['venue']}'),
              trailing: const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.warning),
            ),
          );
        }),
        const Divider(height: 24),

        // Thoughts to Share
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Clinical Notes & Thoughts to Share', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            IconButton(
              icon: const Icon(Icons.post_add, color: AppColors.primary),
              onPressed: _openAddThoughtDialog,
            ),
          ],
        ),
        ..._thoughts.map((th) {
          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(th['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(th['date'] as String, style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(th['content'] as String, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _openAddTaskDialog() async {
    final c = TextEditingController();
    final added = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Clinical Task'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'e.g. Check Bed 10 MRI report'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Add')),
        ],
      ),
    );

    if (added != null && added.isNotEmpty) {
      setState(() {
        _clinicalTasks.add({'title': added, 'done': false, 'priority': 'Normal'});
      });
    }
  }

  Future<void> _openAddThoughtDialog() async {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Clinical Observation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            TextField(controller: bodyC, maxLines: 3, decoration: const InputDecoration(labelText: 'Observation / Note')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Share')),
        ],
      ),
    );

    if (added == true && titleC.text.isNotEmpty) {
      setState(() {
        _thoughts.insert(0, {
          'title': titleC.text.trim(),
          'content': bodyC.text.trim(),
          'date': 'Just now',
        });
      });
    }
  }
}
