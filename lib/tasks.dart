import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام المهام',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal',
      ),
      home: const TasksScreen(),
    );
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // مسافة 5 بيكسل من أعلى الصفحة
          const SizedBox(height: 50),
          
          // شريط البحث
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن مهمة',
                  hintStyle: GoogleFonts.tajawal(),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          // قائمة المهام
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('tasks').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ في تحميل البيانات',
                      style: GoogleFonts.tajawal(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد مهام متاحة حالياً',
                          style: GoogleFonts.tajawal(
                              fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                final tasks = snapshot.data!.docs;

                // تصفية المهام النشطة (غير منتهية وغير مكتملة)
                final currentTime = DateTime.now();
                final activeTasks = tasks.where((task) {
                  try {
                    final deadline = _getDeadline(task);
                    final isCompleted = task['isCompleted'] as bool? ?? false;
                    return deadline.isAfter(currentTime) && !isCompleted;
                  } catch (_) {
                    return false;
                  }
                }).toList();

                // تطبيق البحث على المهام النشطة
                final filteredTasks = _searchQuery.isEmpty
                    ? activeTasks
                    : activeTasks.where((task) {
                        final title = task['title'] as String? ?? '';
                        return title.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (filteredTasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'لا توجد مهام نشطة حالياً'
                              : 'لا توجد نتائج للبحث',
                          style: GoogleFonts.tajawal(
                              fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        if (_searchQuery.isEmpty)
                          Text(
                            'جميع المهام منتهية أو مكتملة',
                            style: GoogleFonts.tajawal(
                                fontSize: 14, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    final title = task['title'] as String? ?? 'بدون عنوان';
                    final booksCount = task['booksCount'] as int? ?? 0;
                    final summaryStrength = task['summaryStrength'] as int? ?? 0;

                    final deadline = _getDeadline(task);
                    final formattedDate =
                        DateFormat("yyyy/MM/dd - hh:mm a").format(deadline);

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // العنوان
                            Text(
                              title,
                              style: GoogleFonts.tajawal(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5a3297),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // معلومات مختصرة (عدد الكتب + قوة التلخيص)
                            Row(
                              children: [
                                _buildInfoItem(
                                  Icons.menu_book,
                                  'عدد الكتب',
                                  '$booksCount',
                                  const Color(0xFF5a3297),
                                ),
                                const SizedBox(width: 8),
                                _buildInfoItem(
                                  Icons.auto_awesome,
                                  'قوة التلخيص',
                                  '$summaryStrength/10',
                                  Colors.orange,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // موعد الانتهاء
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ينتهي في: $formattedDate',
                                    style: GoogleFonts.tajawal(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // مؤشر التقدم الدائم (يعرض فقط إذا كان المستخدم مشاركاً)
                            _buildUserParticipationSection(
                              taskId: task.id,
                              requiredBooks: booksCount,
                            ),
                          ],
                        ),
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

  /// قسم مشاركة المستخدم (مؤشر التقدم أو زر الانضمام)
  Widget _buildUserParticipationSection({
    required String taskId,
    required int requiredBooks,
  }) {
    final uid = _auth.currentUser?.uid;
    
    // إذا لم يكن المستخدم مسجلاً دخولاً، لا نعرض أي شيء
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('tasks')
          .doc(taskId)
          .collection('participants')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        // إذا كان التحميل جارياً، نعرض مؤشر تحميل صغير
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5a3297))));
        }

        // إذا كان المستخدم مشاركاً بالفعل، نعرض مؤشر التقدم فقط
        if (snap.hasData && snap.data!.exists) {
          final participantData = snap.data!.data() as Map<String, dynamic>;
          final joinedAt = participantData['joinedAt'] as Timestamp?;
          
          return FutureBuilder<int>(
            future: _calculateCompletedBooks(taskId, uid, joinedAt),
            builder: (context, bookSnapshot) {
              if (bookSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5a3297))));
              }
              
              final completed = bookSnapshot.data ?? 0;
              return _progressBar(completed: completed, required: requiredBooks);
            },
          );
        }

        // إذا لم يكن المستخدم مشاركاً، نعرض زر الانضمام فقط
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _joinTask(taskId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5a3297),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'التحق بالمهمة',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  /// حساب عدد الكتب المكتملة (التي أنشئت بعد وقت الانضمام)
  Future<int> _calculateCompletedBooks(String taskId, String userId, Timestamp? joinedAt) async {
    if (joinedAt == null) return 0;

    try {
      // جلب جميع الكتب الخاصة بالمستخدم في هذه المهمة
      final booksSnapshot = await _firestore
          .collection('tasks')
          .doc(taskId)
          .collection('participants')
          .doc(userId)
          .collection('books')
          .get();

      int completedCount = 0;

      for (final bookDoc in booksSnapshot.docs) {
        final bookData = bookDoc.data();
        final createdAt = bookData['createdAt'] as Timestamp?;
        
        // إذا كان وقت إنشاء الكتاب بعد وقت الانضمام، نعتبره مكتملاً
        if (createdAt != null && createdAt.compareTo(joinedAt) > 0) {
          completedCount++;
        }
      }

      return completedCount;
    } catch (e) {
      print('Error calculating completed books: $e');
      return 0;
    }
  }

  /// انضمام "صامت" بدون Dialog/SnackBars
  Future<void> _joinTask(String taskId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // الحصول على بيانات المهمة
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) throw Exception('المهمة غير موجودة');

      final taskData = taskDoc.data() as Map<String, dynamic>;
      final taskTitle = taskData['title'] as String? ?? '';
      final taskBooksCount = taskData['booksCount'] as int? ?? 0;
      if (taskTitle.isEmpty) throw Exception('عنوان المهمة غير موجود');

      // التحقق إن كان مشاركاً بالفعل (تحقق إضافي للتأكد)
      final participantRef = _firestore
          .collection('tasks')
          .doc(taskId)
          .collection('participants')
          .doc(currentUser.uid);

      final participantSnap = await participantRef.get();
      if (participantSnap.exists) return;

      // بيانات المستخدم
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) throw Exception('بيانات المستخدم غير موجودة');

      final userData = userDoc.data() as Map<String, dynamic>;
      final name = userData['name'] as String? ?? '';
      final governorate = userData['governorate'] as String? ?? '';
      final department = userData['department'] as String? ?? '';
      final school = userData['school'] as String? ?? '';
      final userId = userData['userId'] as String? ?? currentUser.uid;

      // إنشاء مستند المشارك ببداية 0/required
      await participantRef.set({
        'name': name,
        'governorate': governorate,
        'department': department,
        'school': school,
        'userId': userId,
        'taskTitle': taskTitle,
        'joinedAt': FieldValue.serverTimestamp(),
        'requiredBooks': taskBooksCount,
      });

      // لا نعرض أي رسائل — الشريط سيظهر/يتحدث تلقائياً عبر الـ StreamBuilder
    } catch (_) {
      // صامت: يمكنك استخدام Crashlytics/Logs لاحقاً لو أحببت
    }
  }

  /// استخراج تاريخ الانتهاء سواء كان Timestamp أو String
  DateTime _getDeadline(QueryDocumentSnapshot task) {
    try {
      final timestamp = task['deadline'] as Timestamp?;
      if (timestamp != null) return timestamp.toDate();

      final deadlineStr = task['deadline'] as String?;
      if (deadlineStr != null && deadlineStr.isNotEmpty) {
        return DateFormat("MMMM dd, yyyy 'at' hh:mm:ss a Z").parse(deadlineStr);
      }

      return DateTime.now().add(const Duration(days: 30));
    } catch (_) {
      return DateTime.now().add(const Duration(days: 30));
    }
  }

  /// عنصر معلومات صغير
  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.tajawal(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              value,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// واجهة شريط التقدم (X/Y + نسبة)
  Widget _progressBar({required int completed, required int required}) {
    final total = required <= 0 ? 1 : required;
    final value = (completed / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5a3297)),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[700]),
            ),
            Text(
              '$completed/$required كتاب',
              style: GoogleFonts.tajawal(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ],
    );
  }
}