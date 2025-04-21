import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    // TODO: 로그아웃 로직 추가
                  },
                  child: const Text(
                    'Version',
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ),
                const Spacer(),
                Text('v1.0.0'),
                const SizedBox(width: 20,),
              ],
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () async {
                // Firebase 로그아웃
                await FirebaseAuth.instance.signOut();

                // SharedPreferences에서 저장된 자동 로그인 정보 삭제
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('email');
                await prefs.remove('password');
                await prefs.remove('loginTime');

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Are you sure you want to delete your account?'),
                    content: const Text('This action is irreversible and will permanently delete your account.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false), // 취소
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true), // 확인
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true) {
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    await user?.delete();

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear(); // 자동 로그인 정보도 같이 삭제

                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    }
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'requires-recent-login') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in again before deleting your account.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('에러 발생: ${e.message}')),
                      );
                    }
                  }
                }
              },
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
