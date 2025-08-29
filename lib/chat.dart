import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String apiKey = "AIzaSyD1uHChIO3hrOrf_Rt4P7qAIUdDe2PKLPE";
  static const String url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey";

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  String? _userName;
  bool _loading = false;

  final List<_Msg> _messages = <_Msg>[];

  // -------------------- NEW: رقم التواصل العام المخزّن في users/phone --------------------
  String? _globalPhone;
  Future<void> _loadGlobalPhone() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc('phone').get();
      final value = snap.data()?['phone'];
      if (value is String && value.trim().isNotEmpty) {
        setState(() => _globalPhone = value.trim());
      }
    } catch (_) {
      // تجاهل عادي؛ هنتصرف وقت الضغط على الزر
    }
  }

  Future<void> _showContactDialog() async {
    // لو ما اتحملش قبل كده جرّب تحمّله دلوقتي
    if (_globalPhone == null) {
      await _loadGlobalPhone();
    }
    if (!mounted) return;

    final phone = _globalPhone;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('التواصل عبر واتساب', style: GoogleFonts.tajawal()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (phone != null)
                  SelectableText(
                    'الرقم: $phone',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
                  )
                else
                  Text(
                    'لم يتم العثور على رقم للتواصل.\nتأكد من وجود مستند: users/phone وبداخله الحقل phone.',
                    style: GoogleFonts.tajawal(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إغلاق', style: GoogleFonts.tajawal()),
              ),
              if (phone != null) ...[
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: phone));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم نسخ الرقم', style: GoogleFonts.tajawal())),
                    );
                  },
                  child: Text('نسخ الرقم', style: GoogleFonts.tajawal()),
                ),
                FilledButton(
                  onPressed: () async {
                    await _openWhatsApp(phone);
                  },
                  child: Text('فتح واتساب', style: GoogleFonts.tajawal()),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _openWhatsApp(String phone) async {
    // لو الرقم فيه علامة + أو مسافات، ننضّفه شويّة
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned?text=${Uri.encodeComponent("مرحبًا!")}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر فتح واتساب', style: GoogleFonts.tajawal())),
      );
    }
  }
  // ---------------------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadGlobalPhone(); // NEW: تحميل الرقم عند بدء الشاشة (اختياري)
  }

  Future<void> _loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() => _userName = (snap.data()?['name'] as String?)?.trim());
    } catch (_) {}
  }

  bool _isAllowedIntent(String input) {
    final txt = _normalizeArabic(input);
    const allow = <String>[
      'قراءة', 'القراءة', 'اقرأ', 'قرء', 'كتاب', 'كتب', 'رواية', 'مؤلف',
      'ملخص', 'تلخيص', 'مكتبة', 'اقتراح كتاب', 'قائمة قراءة',
      'اشتراك', 'التسجيل', 'سجل', 'كيف اشترك', 'كيفية الاشتراك',
      'تحدي القراءة العربي', 'تحدى القراءة', 'تحدي القراءه', 'جوائز التحدي',
      'قواعد التحدي', 'شروط التحدي', 'نموذج تلخيص', 'بطاقة القراءة',
    ];
    const block = <String>[
      'برمجة', 'كود', 'رياضيات', 'فيزياء', 'طبخ', 'رياضة', 'سياحة', 'سفر',
      'سياسة', 'ألعاب', 'تاريخ امتحان', 'نتيجة', 'طقس'
    ];
    final hitAllow = allow.any((k) => txt.contains(_normalizeArabic(k)));
    final hitBlock = block.any((k) => txt.contains(_normalizeArabic(k)));
    return hitAllow && !hitBlock;
  }

  String _normalizeArabic(String s) {
    return s
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ة', 'ه')
        .toLowerCase();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Msg(text: text, mine: true));
      _controller.clear();
    });
    _scrollToEnd();

    if (!_isAllowedIntent(text)) {
      setState(() {
        _messages.add(_Msg(
          mine: false,
          text:
              'عذرًا، لا يمكنني الإجابة على هذا الطلب.\nهذا المساعد مخصّص لموضوعات القراءة والكتب والاشتراك في "تحدّي القراءة العربي".',
        ));
      });
      _scrollToEnd();
      return;
    }

    setState(() {
      _loading = true;
      _messages.add(_Msg(text: '', mine: false, thinking: true));
    });

    try {
      final reply = await _askGemini(text);
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.thinking);
        _messages.add(_Msg(mine: false, text: reply));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.thinking);
        _messages.add(_Msg(
            mine: false,
            text:
                'حدث خطأ أثناء الاتصال بالخدمة. حاول لاحقًا.\n(تفاصيل للمطور: $e)'));
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
      _scrollToEnd();
    }
  }

  Future<String> _askGemini(String userText) async {
    final systemPreamble =
        'أنت مساعد لمبادرة "تحدّي القراءة العربي" في مصر. أجب بالعربية الفصحى المبسّطة. '
        'اختصر وأعطِ خطوات واضحة وروابط/نصائح عامة عند الحاجة.';

    final history = _messages.takeLast(6).map((m) {
      return {
        'role': m.mine ? 'user' : 'model',
        'parts': [
          {'text': m.text}
        ]
      };
    }).toList();

    final body = {
      'contents': [
        ...history,
        {
          'role': 'user',
          'parts': [
            {'text': '$systemPreamble\n\nسؤال المستخدم: $userText'}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.5,
        'topK': 40,
        'topP': 0.9,
        'maxOutputTokens': 1024,
      },
    };

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw 'HTTP ${res.statusCode}: ${res.body}';
    }

    final data = jsonDecode(res.body);
    final candidates = data['candidates'] as List?;
    final text =
        candidates?.first?['content']?['parts']?.first?['text'] as String?;
    return text?.trim().isNotEmpty == true
        ? text!.trim()
        : 'لم أتلقَّ ردًا صالحًا من النموذج.';
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final welcomeName = _userName == null || _userName!.isEmpty ? 'بك' : _userName!;
    final isEmpty = _messages.isEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,

        // -------------------- NEW: AppBar مع زر تواصل --------------------
        appBar: AppBar(
          title: Text('المساعد القرائي', style: GoogleFonts.tajawal()),
          actions: [
            TextButton.icon(
              onPressed: _showContactDialog,
              icon: const Icon(Icons.support_agent),
              label: Text('تواصل', style: GoogleFonts.tajawal()),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(Colors.black87),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        // -----------------------------------------------------------------

        body: Column(
          children: [
            if (isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/tahadi.png', width: 140),
                      const SizedBox(height: 16),
                      Text('أهلًا، $welcomeName',
                          style: GoogleFonts.tajawal(
                            textStyle: Theme.of(context).textTheme.headlineSmall,
                          )),
                      const SizedBox(height: 8),
                      Text(
                        'كيف يمكنني مساعدتك اليوم في مواضيع القراءة والكتب؟',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.tajawal(
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    return Align(
                      alignment:
                          m.mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: m.mine
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.12)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: m.thinking
                            ? const _TypingDots()
                            : SelectableText(
                                m.text,
                                textAlign: TextAlign.start,
                                style: GoogleFonts.tajawal(),
                              ),
                      ),
                    );
                  },
                ),
              ),
            // إدخال الرسائل مع إطار أسود حول حقل النص فقط
            SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color.fromARGB(255, 130, 130, 130), width: 1.0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          style: GoogleFonts.tajawal(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            hintText: 'اكتب رسالتك هنا عن القراءة أو الكتب...',
                            hintStyle: GoogleFonts.tajawal(color: Colors.black54),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(const Color(0xFFF8CD57)),
                      ),
                      onPressed: _loading ? null : _send,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool mine;
  final bool thinking;
  _Msg({required this.text, required this.mine, this.thinking = false});
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        double v(double t) => (0.5 + 0.5 * (1 + math.sin(6.283 * (t % 1)))) / 2;
        final t = _c.value;
        final opacity = v(t + i / 3);
        return Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: const Color(0xFFF8CD57),
            ),
          ),
        );
      }),
    );
  }
}

extension<E> on List<E> {
  Iterable<E> takeLast(int n) => skip(length - (n < length ? n : length));
}