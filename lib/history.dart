import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _BooksSearchPageState();
}

class _BooksSearchPageState extends State<History> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _search = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _buildCenterFab(context),
        body: SafeArea(
          child: uid == null
              ? _centerMsg('من فضلك سجّل الدخول أولاً.')
              : Column(
                  children: [
                    // شريط البحث
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          textInputAction: TextInputAction.search,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.tajawal(),
                          decoration: InputDecoration(
                            hintText: 'ابحث باسم الكتاب...',
                            hintStyle: GoogleFonts.tajawal(),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            suffixIcon: const Padding(
                              padding: EdgeInsetsDirectional.only(end: 8.0),
                              child: Icon(Icons.search),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // قائمة الكتب
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('books')
                            .where('type', isEqualTo: 'history')
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snap.hasError) {
                            return _centerMsg('حصل خطأ: ${snap.error}');
                          }

                          final docs = snap.data?.docs ?? [];

                          // ترتيب + فلترة محلية
                          final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs)
                            ..sort((a, b) => (a.data()['title'] ?? '')
                                .toString()
                                .toLowerCase()
                                .compareTo((b.data()['title'] ?? '')
                                    .toString()
                                    .toLowerCase()));

                          final filtered = _search.isEmpty
                              ? sortedDocs
                              : sortedDocs.where((doc) {
                                  final data = doc.data();
                                  final t =
                                      (data['title'] ?? '').toString().toLowerCase();
                                  return t.contains(_search.toLowerCase());
                                }).toList();

                          if (filtered.isEmpty) {
                            return _centerMsg(_search.isEmpty
                                ? 'لا توجد كتب حالياً.'
                                : 'لا توجد نتائج مطابقة لبحثك.');
                          }

                          return ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(12, 8, 12, 96),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final doc = filtered[i];
                              final data = doc.data();
                              final title =
                                  (data['title'] ?? 'بدون عنوان').toString();
                              final author =
                                  (data['author'] ?? 'غير معروف').toString();
                              final score = data['evaluation_score'] ?? 0;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookDetailsPage(bookId: doc.id, bookData: data),
                                    ),
                                  );
                                },
                                child: _BookCard(
                                  title: title, 
                                  author: author,
                                  score: score,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCenterFab(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddBookPage(type: 'history'),
            ),
          );
        },
        backgroundColor: const Color(0xFF592F96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Icon(
          Icons.add,
          size: 28,
          color: Color(0xFFF8CD57),
        ),
      ),
    );
  }

  Widget _centerMsg(String msg) => Center(
        child: Text(msg, 
          style: GoogleFonts.tajawal(
            color: Colors.black54,
            fontSize: 16,
          )),
      );
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.title, 
    required this.author,
    required this.score,
  });

  final String title;
  final String author;
  final dynamic score;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // الصورة على اليمين بدون إطار
          Image.asset(
            'assets/book.png',
            width: 75,
            height: 75,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 42,
              height: 42,
              color: Colors.grey[300],
              child: const Icon(Icons.menu_book, size: 24, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          
          // النص على اليسار
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اسم الكتاب: $title',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'اسم المؤلف: $author',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'قوة التلخيص: ${score is num ? score.toStringAsFixed(1) : score.toString()}/10',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF8CD57),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookDetailsPage extends StatefulWidget {
  final Map<String, dynamic> bookData;
  final String bookId;

  const BookDetailsPage({
    super.key,
    required this.bookData,
    required this.bookId,
  });

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  final TextEditingController _summaryCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _summaryCtrl.text = widget.bookData['summary'] ?? '';
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    super.dispose();
  }

  // تحويل الأرقام للغة العربية (٠١٢٣٤٥٦٧٨٩)
  String _toArabicDigits(String input) {
    const map = {
      '0': '٠', '1': '١', '2': '٢', '3': '٣', '4': '٤',
      '5': '٥', '6': '٦', '7': '٧', '8': '٨', '9': '٩',
    };
    return input.replaceAllMapped(RegExp(r'[0-9]'), (m) => map[m.group(0)]!);
  }

  // دالة للاتصال بـ Gemini API لتقييم الملخص
  Future<Map<String, dynamic>?> _evaluateSummary() async {
    // ⚠️ لا تحفظ المفتاح في الكود المنتج
        const apiKey = "AIzaSyD1uHChIO3hrOrf_Rt4P7qAIUdDe2PKLPE";
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey";

    final headers = {
      "Content-Type": "application/json",
    };

    final prompt = """
    قم بتقييم هذا الملخص للقصة بناءً على المعايير التالية:

    1. تغطية الفكرة الأساسية - هل يعكس الملخص المغزى أو الفكرة الرئيسية للقصة؟
    2. الدقة - هل الأحداث والشخصيات صحيحة من غير تحريف؟
    3. الاختصار - هل الملخص قصير ومركز، من غير تفاصيل إضافية غير ضرورية؟
    4. الوضوح - هل اللغة سهلة الفهم والصياغة بسيطة؟
    5. التسلسل الزمني - هل الأحداث مرتبة بشكل منطقي (بداية – وسط – نهاية)؟
    6. اللغة والأسلوب - هل تم استخدام جمل مترابطة وأسلوب متماسك؟
    7. التركيز على الشخصيات الرئيسية - هل تم ذكر الشخصيات الأساسية وربطها بالأحداث المهمة؟
    8. تجنب التفاصيل غير المهمة - هل تم استبعاد أي تفاصيل ثانوية لا علاقة لها بالحبكة؟
    9. الإبداع في التعبير - هل اعتمد الملخص على صياغة الطالب الخاصة بدل النسخ الحرفي من القصة؟
    10. الموضوعية - هل يعكس الملخص ما حصل فعلًا في القصة، من غير إدخال رأي شخصي أو حكم ذاتي؟

    اسم الكتاب: ${widget.bookData['title']}
    اسم المؤلف: ${widget.bookData['author']}
    الملخص: ${_summaryCtrl.text}

    أرجو تقييم الملخص وإعطاء درجة من 0 إلى 10 مع تعليق قصير (لا يزيد عن 200 كلمة) يحتوي على ملاحظات لتحسين قوة التلخيص.
    أرجو إرجاع النتيجة بالتنسيق التالي:
    الدرجة: [رقم من 0 إلى 10]
    الملاحظات: [نص لا يزيد عن 200 كلمة]
    """;

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // محاولات متعددة لاستخراج النص بأمان
        String text = '';
        try {
          text = data["candidates"][0]["content"]["parts"][0]["text"] ?? '';
        } catch (_) {
          // fallback لتجميع جميع الأجزاء
          final parts = (data["candidates"]?[0]?["content"]?["parts"] as List?) ?? [];
          text = parts.map((p) => (p["text"] ?? '').toString()).join('\n');
        }

        final lines = text.split('\n');
        double? score;
        String feedback = '';

        for (final raw in lines) {
          final line = raw.trim();
          if (line.startsWith('الدرجة')) {
            final v = line.split(':').skip(1).join(':').trim();
            // التقط أول رقم حتى لو فيه نص ملازم
            final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(v);
            if (match != null) {
              score = double.tryParse(match.group(1)!);
            }
          } else if (line.startsWith('الملاحظات')) {
            feedback = line.split(':').skip(1).join(':').trim();
          }
        }

        return {
          'score': score ?? 0.0,
          'feedback': feedback.isNotEmpty ? feedback : 'لا توجد ملاحظات',
        };
      } else {
        throw Exception('فشل في الاتصال بالخادم: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء التقييم: $e');
    }
  }

  Future<void> _updateSummary() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);

    try {
      final evaluation = await _evaluateSummary();
      final score = (evaluation?['score'] ?? 0.0) as double;
      final feedback = (evaluation?['feedback'] ?? 'لم يتم التقييم') as String;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('books')
          .doc(widget.bookId)
          .update({
        'summary': _summaryCtrl.text.trim(),
        'evaluation_score': score.toDouble(),
        'evaluation_feedback': feedback,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        widget.bookData['summary'] = _summaryCtrl.text.trim();
        widget.bookData['evaluation_score'] = score;
        widget.bookData['evaluation_feedback'] = feedback;
        _editing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text('تم التحديث بنجاح', style: GoogleFonts.tajawal()),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text('خطأ في التحديث: $e', style: GoogleFonts.tajawal()),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteBook() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _deleting = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('books')
          .doc(widget.bookId)
          .delete();

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text('تم الحذف بنجاح', style: GoogleFonts.tajawal()),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text('خطأ في الحذف: $e', style: GoogleFonts.tajawal()),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.bookData['title'] ?? 'بدون عنوان';
    final author = widget.bookData['author'] ?? 'غير معروف';
    final summary = widget.bookData['summary'] ?? '';
    final score = (widget.bookData['evaluation_score'] ?? 0.0) as num;
    final feedback = widget.bookData['evaluation_feedback'] ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  foregroundColor: Colors.black87,
  title: Text('تفاصيل الكتاب', style: GoogleFonts.tajawal()),
  centerTitle: false,
  actions: [
    IconButton(
      icon: const Icon(Icons.delete, color: Color(0xFFF8CD57)), // أصفر
      tooltip: 'حذف الكتاب',
      onPressed: _deleting ? null : _deleteBook,
    ),
  ],
),

        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _InfoRow(label: 'اسم الكتاب:', value: title),
              const SizedBox(height: 12),
              _InfoRow(label: 'اسم المؤلف:', value: author),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'قوة التلخيص:',
                value: _toArabicDigits(
                  '${score.toStringAsFixed(1)}/10',
                ),
                valueColor: const Color(0xFFF8CD57),
              ),
              const SizedBox(height: 24),

              Text(
                'الملخص:',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEFEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  textDirection: TextDirection.rtl, // فرض RTL داخل الصف
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_editing) ...[
                      IconButton(
                        icon: const Icon(Icons.save, color: Color(0xFFF8CD57)),
                        onPressed: _saving ? null : _updateSummary,
                        tooltip: 'حفظ',
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFFF8CD57)),
                        onPressed: () => setState(() => _editing = true),
                        tooltip: 'تعديل',
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: _editing
                          ? TextFormField(
                              controller: _summaryCtrl,
                              maxLines: null,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.tajawal(),
                              decoration: InputDecoration(
                                hintText: 'اكتب الملخص هنا...',
                                hintStyle: GoogleFonts.tajawal(),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                          : Text(
                              summary.isEmpty ? 'لا يوجد ملخص' : summary,
                              style: GoogleFonts.tajawal(),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                    ),
                  ],
                ),
              ),

              if ((feedback as String).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'ملاحظات لزيادة قوة الملخص:',
                  style: GoogleFonts.tajawal(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    feedback,
                    style: GoogleFonts.tajawal(),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


/// ويدجت سطر معلومات مضمون RTL باستخدام Text.rich
class _InfoRow extends StatelessWidget {
  final String label; // مثال: "اسم الكتاب:"
  final String value; // مثال: "السيرة النبوية"
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              TextSpan(
                text: value,
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.w400,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}


class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key, this.type = 'history'});

  final String? type;

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();

  bool _saving = false;
  bool _evaluating = false;
  double? _evaluationScore;
  String? _evaluationFeedback;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  // دالة للاتصال بـ Gemini API لتقييم الملخص
  Future<Map<String, dynamic>?> _evaluateSummary() async {
    const apiKey = "AIzaSyD1uHChIO3hrOrf_Rt4P7qAIUdDe2PKLPE";
    const url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey";

    final headers = {
      "Content-Type": "application/json",
    };

    final prompt = """
    قم بتقييم هذا الملخص للقصة بناءً على المعايير التالية:
    
    1. تغطية الفكرة الأساسية - هل يعكس الملخص المغزى أو الفكرة الرئيسية للقصة؟
    2. الدقة - هل الأحداث والشخصيات صحيحة من غير تحريف؟
    3. الاختصار - هل الملخص قصير ومركز، من غير تفاصيل إضافية غير ضرورية؟
    4. الوضوح - هل اللغة سهلة الفاهيم والصياغة بسيطة؟
    5. التسلسل الزمني - هل الأحداث مرتبة بشكل منطقي (بداية – وسط – نهاية)؟
    6. اللغة والأسلوب - هل تم استخدام جمل مترابطة وأسلوب متماسك؟
    7. التركيز على الشخصيات الرئيسية - هل تم ذكر الشخصيات الأساسية وربطها بالأحداث المهمة؟
    8. تجنب التفاصيل غير المهمة - هل تم استبعاد أي تفاصيل ثانوية مالهاش علاقة بالحبكة؟
    9. الإبداع في التعبير - هل اعتمد الملخص على صياغة الطالب الخاصة بدل النسخ الحرفي من القصة؟
    10. الموضوعية - هل يعكس الملخص ما حصل فعلًا في القصة، من غير إدخال رأي شخصي أو حكم ذاتي؟
    
    اسم الكتاب: ${_titleCtrl.text}
    اسم المؤلف: ${_authorCtrl.text}
    الملخص: ${_summaryCtrl.text}
    
    أرجو تقييم الملخص وإعطاء درجة من 0 إلى 10 مع تعليق قصير (لا يزيد عن 200 كلمة) يحتوي على ملاحظات لتحسين قوة التلخيص.
    أرجو إرجاع النتيجة بالتنسيق التالي:
    الدرجة: [رقم من 0 إلى 10]
    الملاحظات: [نص لا يزيد عن 200 كلمة]
    """;

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(url), 
        headers: headers, 
        body: body
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data["candidates"][0]["content"]["parts"][0]["text"];
        
        // تحليل النتيجة
        final lines = text.split('\n');
        double? score;
        String feedback = '';
        
        for (final line in lines) {
          if (line.startsWith('الدرجة:')) {
            final scoreStr = line.replaceAll('الدرجة:', '').trim();
            score = double.tryParse(scoreStr);
          } else if (line.startsWith('الملاحظات:')) {
            feedback = line.replaceAll('الملاحظات:', '').trim();
          }
        }
        
        return {
          'score': score ?? 0,
          'feedback': feedback.isNotEmpty ? feedback : 'لا توجد ملاحظات'
        };
      } else {
        throw Exception('فشل في الاتصال بالخادم: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('حدث خطأ أثناء التقييم: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يجب تسجيل الدخول أولاً', 
          style: GoogleFonts.tajawal())),
      );
      return;
    }

    // تقييم الملخص أولاً قبل الحفظ
    setState(() => _evaluating = true);
    
    try {
      final evaluation = await _evaluateSummary();
      final score = evaluation?['score'] ?? 0;
      final feedback = evaluation?['feedback'] ?? 'لم يتم التقييم';
      
      setState(() {
        _evaluationScore = score is int ? score.toDouble() : score;
        _evaluationFeedback = feedback;
      });
      
      // إذا كانت النتيجة أقل من 3، لا نستمر في الحفظ
      if (_evaluationScore != null && _evaluationScore! < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يجب أن تتجاوز قوة التلخيص 3/10 ليمكن حفظ الكتاب', 
              style: GoogleFonts.tajawal()),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التقييم: $e', 
          style: GoogleFonts.tajawal())),
      );
      setState(() => _evaluating = false);
      return;
    } finally {
      setState(() => _evaluating = false);
    }

    // إذا نجح التقييم وكانت النتيجة كافية، نكمل الحفظ
    setState(() => _saving = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'author': _authorCtrl.text.trim(),
        'summary': _summaryCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'evaluation_score': _evaluationScore,
        'evaluation_feedback': _evaluationFeedback,
      };

      if (widget.type != null) {
        data['type'] = widget.type as Object;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('books')
          .add(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم الحفظ بنجاح', 
            style: GoogleFonts.tajawal())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: $e', 
            style: GoogleFonts.tajawal())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF8CD57);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
          title: Text('إضافة كتاب', 
            style: GoogleFonts.tajawal()),
          centerTitle: false,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              children: [
                _RoundedField(
                  controller: _titleCtrl,
                  hint: 'اسم الكتاب....',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل اسم الكتاب' : null,
                ),
                const SizedBox(height: 12),
                _RoundedField(
                  controller: _authorCtrl,
                  hint: 'اسم المؤلف....',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'أدخل اسم المؤلف' : null,
                ),
                const SizedBox(height: 12),

                // الملخص مع العنوان الأصفر
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFEFEF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الملخص:',
                        style: GoogleFonts.tajawal(
                          color: const Color(0xFFF8CD57),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        )),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: TextFormField(
                          controller: _summaryCtrl,
                          maxLines: null,
                          expands: true,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.tajawal(),
                          decoration: InputDecoration(
                            hintText: 'اكتب الملخص هنا...',
                            hintStyle: GoogleFonts.tajawal(),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // عرض نتيجة التقييم إذا كانت متوفرة
                if (_evaluationScore != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEFEF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نتيجة التقييم: ${_evaluationScore!.toStringAsFixed(1)}/10',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: const Color(0xFFF8CD57),
                          ),
                        ),
                        if (_evaluationFeedback != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'ملاحظات لزيادة قوة التلخيص:',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _evaluationFeedback!,
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                // زر حفظ بعرض الشاشة
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF8CD57),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: (_saving || _evaluating) ? null : _save,
                    child: (_saving || _evaluating)
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('حفظ', 
                            style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(221, 255, 255, 255),
                            )),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        textAlign: TextAlign.right,
        style: GoogleFonts.tajawal(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.tajawal(),
          border: InputBorder.none,
        ),
      ),
    );
  }
}