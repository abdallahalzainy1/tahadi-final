import 'home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'create_account.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // بعد التهيئة، نشغل التطبيق
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialPage() async {
    // نحصل على المستخدم الحالي من Firebase Auth
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // المعرف (UID)
      String uid = user.uid;

      // نبحث عن مستند بهذا الاسم في كولكشن users
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        // المستخدم موجود => نروح للصفحة الرئيسية
        return  HomeScreen();
      }
    }

    // إما المستخدم مش مسجل دخول، أو مفيش مستند ليه => نروح لإنشاء الحساب
    return const SignUpPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bena SRT App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Cairo',
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // أثناء تحميل البيانات من فايربيز
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            // في حالة وجود خطأ
            return Scaffold(
              body: Center(child: Text('حدث خطأ: ${snapshot.error}')),
            );
          } else {
            // توجيه المستخدم حسب الحالة
            return snapshot.data!;
          }
        },
      ),
    );
  }
}
