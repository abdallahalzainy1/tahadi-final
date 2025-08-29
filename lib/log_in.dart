import 'create_account.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String _name = '';
  String _password = '';
  bool _isLoading = false;
  String _errorMessage = '';
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = const Color(0xFF5A34A2);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: _name)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'لم يتم العثور على مستخدم بهذا الاسم',
        );
      }

      bool loginSuccess = false;
      String? userEmail;
      String? userPhone;

      for (var doc in querySnapshot.docs) {
        if (doc.data()['password'] == _password) {
          loginSuccess = true;
          userEmail = doc.data()['email'] as String?;
          userPhone = doc.data()['phone'] as String?;
          break;
        }
      }

      if (!loginSuccess) {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'كلمة المرور غير صحيحة',
        );
      }

      // محاولة تسجيل الدخول باستخدام البريد الإلكتروني أولاً
      if (userEmail != null && userEmail.isNotEmpty) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmail,
          password: _password,
        );
      } 
      // إذا لم يكن هناك بريد إلكتروني، حاول باستخدام رقم الهاتف
      else if (userPhone != null && userPhone.isNotEmpty) {
        String phoneEmail = '${userPhone}@tahadi.com';
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: phoneEmail,
          password: _password,
        );
      } 
      // إذا لم يكن هناك أي منهما
      else {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'بيانات الاعتماد غير صحيحة',
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SuccessPage(name: _name)),
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'لم يتم العثور على مستخدم بهذا الاسم';
        break;
      case 'wrong-password':
        errorMessage = 'كلمة المرور غير صحيحة';
        break;
      case 'invalid-credential':
        errorMessage = 'بيانات الاعتماد غير صحيحة';
        break;
      default:
        errorMessage = 'حدث خطأ: ${e.message}';
    }
    setState(() {
      _errorMessage = errorMessage;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Sign.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 45),
                        Text(
                          'تسجيل الدخول',
                          style: GoogleFonts.tajawal(
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpPage()),
                            );
                          },
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'ليس لديك حساب؟ ',
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: 'إنشاء حساب',
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Image.asset(
                        'assets/tahadi.png',
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildForm(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 5,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'جاري تسجيل الدخول...',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                style: GoogleFonts.tajawal(),
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  labelStyle: GoogleFonts.tajawal(),
                  prefixIcon: Icon(Icons.person, color: _primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                onChanged: (value) => _name = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال اسمك';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                style: GoogleFonts.tajawal(),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  labelStyle: GoogleFonts.tajawal(),
                  prefixIcon: Icon(Icons.lock, color: _primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
                obscureText: true,
                onChanged: (value) => _password = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: Text(
                    'تسجيل الدخول',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                child: Text(
                  _errorMessage,
                  style: GoogleFonts.tajawal(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SuccessPage extends StatelessWidget {
  final String name;

  const SuccessPage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Sign.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 100,
                ),
                const SizedBox(height: 32),
                Text(
                  'تم تسجيل الدخول بنجاح!',
                  style: GoogleFonts.tajawal(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'لقد سجلت دخولك بنجاح',
                  style: GoogleFonts.tajawal(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'مرحباً بعودتك $name',
                  style: GoogleFonts.tajawal(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A34A2),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Text(
                    'الذهاب للصفحة الرئيسية',
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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