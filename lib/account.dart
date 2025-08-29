import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:google_fonts/google_fonts.dart';
import 'create_account.dart';
import 'package:intl/intl.dart';

// تأكد من استيراد صفحة SignUpPage بشكل صحيح

class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text("محتاج تعمل تسجيل دخول الأول"),
      );
    }

    final userId = currentUser.uid;
    final users = FirebaseFirestore.instance.collection('users').doc(userId);
    final booksCol = users.collection('books');

    return  SingleChildScrollView(
        padding: const EdgeInsets.only(top: 64),
        child: FutureBuilder(
          future: Future.wait([
            users.get(),
            booksCol.get(),
            FirebaseFirestore.instance.collection('notficitions').get(),
            users.get(),
          ]),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userDoc =
                (snap.data![0] as DocumentSnapshot<Map<String, dynamic>>);
            final booksSnap =
                (snap.data![1] as QuerySnapshot<Map<String, dynamic>>);
            final notificationsSnap =
                (snap.data![2] as QuerySnapshot<Map<String, dynamic>>);
            final userDataSnap =
                (snap.data![3] as DocumentSnapshot<Map<String, dynamic>>);

            final name = userDoc.data()?['name'] ?? '—';
            final governorate = userDoc.data()?['governorate'] ?? '—';
            final department = userDoc.data()?['department'] ?? '—';
            final school = userDoc.data()?['school'] ?? '—';
            final phone = userDataSnap.data()?['phone'] ?? '—';

            final booksCount = booksSnap.size;
            
            // حساب متوسط قوة التلخيص
            double totalScore = 0;
            int evaluatedBooks = 0;
            
            for (var doc in booksSnap.docs) {
              final score = doc.data()['evaluation_score'];
              if (score != null) {
                // تحويل score إلى double بشكل آمن
                final scoreValue = score is int ? score.toDouble() : score as double;
                if (scoreValue > 0) {
                  totalScore += scoreValue;
                  evaluatedBooks++;
                }
              }
            }
            
            final averageScore = evaluatedBooks > 0 
                ? (totalScore / evaluatedBooks) * 10 
                : 0.0;

            final badgeAssets = <String>[
              'assets/red.png',
              'assets/green.png',
              'assets/blue.png',
              'assets/fedy.png',
              'assets/yellow.png',
              'assets/pink.png',
              'assets/greeny.png',
              'assets/yellowy.png',
            ];

            final thresholds = <int>[10, 20, 30, 40, 50, 75, 125, 200];

            int unlocked = 1;
            for (int i = 0; i < thresholds.length; i++) {
              if (booksCount <= thresholds[i]) {
                unlocked = i + 1;
                break;
              } else {
                unlocked = thresholds.length;
              }
            }

            int prev = 0;
            int next = thresholds.first;
            for (int i = 0; i < thresholds.length; i++) {
              if (booksCount <= thresholds[i]) {
                next = thresholds[i];
                prev = (i == 0) ? 0 : thresholds[i - 1];
                break;
              }
              if (i == thresholds.length - 1 && booksCount > thresholds[i]) {
                prev = thresholds[i];
                next = thresholds[i];
              }
            }

            final segmentTotal = (next - prev).clamp(1, 999999);
            final inSegment = (booksCount - prev).clamp(0, segmentTotal);
            final progress =
                (segmentTotal == 0) ? 1.0 : inSegment / segmentTotal;

            final currentIdx = (unlocked - 1).clamp(0, badgeAssets.length - 1);
            final nextIdx = (unlocked).clamp(0, badgeAssets.length - 1);
            final currentLevelAsset = badgeAssets[currentIdx];
            final nextLevelAsset = badgeAssets[nextIdx];

            // تصفية الإشعارات النشطة فقط
            final now = DateTime.now();
            final activeNotifications = notificationsSnap.docs.where((doc) {
              final data = doc.data();
              final expiresAt = data['expiresAt'] as Timestamp?;
              return expiresAt != null && expiresAt.toDate().isAfter(now);
            }).toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // عرض الإشعارات النشطة
                  if (activeNotifications.isNotEmpty)
                    ...activeNotifications.map((doc) {
                      final data = doc.data();
                      final backgroundColor = data['backgroundColor'] ?? 'fH45167c';
                      final textColor = data['textColor'] ?? 'ffH6200';
                      final message = data['message'] ?? '';
                      
                      return _NotificationCard(
                        docId: doc.id,
                        backgroundColor: backgroundColor,
                        textColor: textColor,
                        message: message,
                      );
                    }).toList(),
                  
                  _Card(
                    isLarge: true,
                    child: _ProfileBlock(
                      name: name,
                      governorate: governorate,
                      department: department,
                      school: school,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // إحصاءات الكتب
                        _StatsBlock(
                          booksCount: booksCount,
                          averageScore: averageScore,
                        ),
                        const SizedBox(height: 16),
                        // شارات الإنجازات
                       Text(
  ':مؤشِّر إنجازاتك',
  style: GoogleFonts.tajawal(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: Color(0xFFB68700),
  ),
  textAlign: TextAlign.right, // بيخلي الكلام يبدأ من اليمين
),

                        const SizedBox(height: 12),
                        _BadgesRow(
                          badgeAssets: badgeAssets,
                          unlocked: unlocked,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _Card(
                    title: ':تقدمك الحالي ',
                    child: _ProgressBlock(
                      progress: progress,
                      label: '$inSegment/$segmentTotal',
                      startAsset: currentLevelAsset,
                      endAsset: nextLevelAsset,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // عرض رقم التواصل
                  
                  // زر تسجيل الخروج
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        
                        // استخدام Navigator.pushReplacement للانتقال لصفحة التسجيل
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => SignUpPage(), // تأكد من أن اسم الفئة صحيح
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB68700),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        side: BorderSide.none,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'تسجيل الخروج',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: const Color(0xFFB68700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      
    );
  }
}

// -------------------------
// كارت الإشعار
// -------------------------
class _NotificationCard extends StatefulWidget {
  final String docId;
  final String backgroundColor;
  final String textColor;
  final String message;

  const _NotificationCard({
    required this.docId,
    required this.backgroundColor,
    required this.textColor,
    required this.message,
  });

  @override
  __NotificationCardState createState() => __NotificationCardState();
}

class __NotificationCardState extends State<_NotificationCard> {
  bool _isVisible = true;

  void _dismissNotification() async {
    setState(() {
      _isVisible = false;
    });
    
    // حذف الإشعار من قاعدة البيانات
    await FirebaseFirestore.instance
        .collection('notficitions')
        .doc(widget.docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    // تحويل ألوان hex إلى Color
    Color bgColor = _parseColor(widget.backgroundColor);
    Color txtColor = _parseColor(widget.textColor);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // زر الإغلاق
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              onTap: _dismissNotification,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // نص الإشعار
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.message,
              style: GoogleFonts.tajawal(
                color: txtColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      // تنظيف السلسلة من أي أحرف غير صالحة
      String cleanedHex = hexColor.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
      
      // إذا كانت السلسلة تبدأ بـ 'ff' فهي تحتوي على قناة ألفا
      if (cleanedHex.length == 6) {
        cleanedHex = 'FF$cleanedHex'; // إضافة قيمة ألفا كاملة
      }
      
      // تحويل إلى عدد صحيح وتحويل إلى Color
      return Color(int.parse(cleanedHex, radix: 16));
    } catch (e) {
      // في حالة الخطأ، إرجاع ألوان افتراضية
      return hexColor.contains('H') ? const Color.fromARGB(0, 3, 7, 61) : const Color.fromARGB(0, 193, 155, 0);
    }
  }
}

// -------------------------
// كروت عامة
// -------------------------
class _Card extends StatelessWidget {
  const _Card({this.title, required this.child, this.isLarge = false});
  final String? title;
  final Widget child;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 20 : 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, 3),
            color: Color(0x14000000),
          ),
        ],
      ),
      constraints: isLarge
          ? const BoxConstraints(minHeight: 130)
          : const BoxConstraints(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  title!,
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: const Color(0xFFB68700),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

// -------------------------
// بلوك بيانات المستخدم
// -------------------------
class _ProfileBlock extends StatelessWidget {
  const _ProfileBlock({
    required this.name,
    required this.governorate,
    required this.department,
    required this.school,
  });

  final String name;
  final String governorate;
  final String department;
  final String school;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _kv('الاسم', name),
              _kv('المحافظة', governorate),
              _kv('الإدارة', department),
              _kv('المدرسة', school),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 96,
            height: 96,
            child: Image.asset(
              'assets/pre_profile.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: RichText(
          textAlign: TextAlign.right,
          text: TextSpan(
            style: GoogleFonts.tajawal(color: Colors.black87, fontSize: 15),
            children: [
              TextSpan(
                text: '$k: ',
                style: GoogleFonts.tajawal(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text: v,
                style: GoogleFonts.tajawal(
                  color: const Color(0xFFB68700),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
}

// -------------------------
// بلوك الإحصائيات
// -------------------------
class _StatsBlock extends StatelessWidget {
  const _StatsBlock({
    required this.booksCount,
    required this.averageScore,
  });

  final int booksCount;
  final double averageScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            title: 'عدد الكتب المقروءة',
            value: booksCount.toString(),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          _StatItem(
            title: 'متوسط قوة التلخيص',
            value: '${averageScore.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB68700),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// -------------------------
// شارات الإنجازات
// -------------------------
class _BadgesRow extends StatelessWidget {
  const _BadgesRow({
    required this.badgeAssets,
    required this.unlocked,
  });

  final List<String> badgeAssets;
  final int unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badgeAssets.length,
          itemBuilder: (context, i) {
            final isUnlocked = i < unlocked;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: _BlurBadge(
                asset: badgeAssets[i],
                blur: isUnlocked ? 0 : 6,
                dimLocked: !isUnlocked,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BlurBadge extends StatelessWidget {
  const _BlurBadge({
    required this.asset,
    required this.blur,
    this.dimLocked = false,
  });

  final String asset;
  final double blur;
  final bool dimLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, // حجم ثابت للجميع
      height: 28, // حجم ثابت للجميع
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.transparent,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Stack(
            fit: StackFit.expand, // هذا يضمن ملء المساحة بالكامل
            children: [
              // الصورة الأساسية مع دقة التحجيم
              Image.asset(
                asset,
                fit: BoxFit.cover, // يملأ المساحة مع الحفاظ على النسبة
                width: 28,
                height: 28,
              ),
              // طبقة التعتيم للشارات المقفلة
              if (dimLocked)
                Container(
                  color: Colors.white.withOpacity(0.5), // زيادة التعتيم
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------
// شريط التقدّم
// -------------------------
class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.progress,
    required this.label,
    required this.startAsset,
    required this.endAsset,
  });

  final double progress;
  final String label;
  final String startAsset;
  final String endAsset;

  @override
  Widget build(BuildContext context) {
    return  Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _levelIcon(startAsset),
              const SizedBox(width: 8),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress.clamp(0, 1)),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 18,
                        child: Stack(
                          children: [
                            Container(
                              height: 18,
                              color: const Color(0xFFEFEFEF),
                              width: double.infinity,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: value,
                                child: Container(
                                  height: 18,
                                  color: const Color(0xFF2E2E2E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              _levelIcon(endAsset),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      
    );
  }

  Widget _levelIcon(String asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Image.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}