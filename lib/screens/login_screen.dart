import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Firebase Auth import
import 'signin_screen.dart';
import 'home_screen.dart';
import 'pwreset_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  // 이메일, 비밀번호 컨트롤러 추가
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 1) 이메일 로그인 함수.
  Future<void> _signIn() async {

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 성공!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

    } on FirebaseAuthException catch (e) {
      String message = '로그인 실패';
      if (e.code == 'user-not-found') {
        message = '사용자를 찾을 수 없습니다.';
      } else if (e.code == 'wrong-password') {
        message = '비밀번호가 틀렸습니다.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러 발생: $e')),
      );
    }
  }

  // 2. 구글 로그인 함수
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // 사용자가 로그인 창 닫음
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final email = FirebaseAuth.instance.currentUser?.email;
      final name = FirebaseAuth.instance.currentUser?.displayName;

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        await userRef.set({
          'name': name ?? email ?? '사용자',
          'email': email,
          'createdAt': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구글 로그인 성공!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('로그인')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 이메일 입력
              TextField(
                controller: _emailController,  // 컨트롤러 연결
                decoration: const InputDecoration(
                  labelText: '이메일을 입력하세요',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20.0),

              // 비밀번호 입력
              TextField(
                controller: _passwordController,  // 컨트롤러 연결
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호를 입력하세요',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30.0),

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signIn,  // 로그인 함수 연결
                  child: const Text('로그인'),
                ),
              ),
              const SizedBox(height: 10.0),

              const SizedBox(height: 5.0),

              // 구글 로그인 버튼
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('구글 계정으로 로그인'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),



              // 회원가입 버튼
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                  );
                },
                child: const Text('회원가입'),
              ),

              //비밀번호 재설정
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PwResetScreen()),
                  );
                },
                child: const Text('비밀번호 찾기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
