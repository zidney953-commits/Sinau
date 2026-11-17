import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/app_controllers.dart';
import 'controllers/auth_controller.dart';
import 'core/theme.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/user/user_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthController(), permanent: true);
  runApp(const SinauApp());
}

class SinauApp extends StatelessWidget {
  const SinauApp({super.key});
  @override
  Widget build(BuildContext context) => GetMaterialApp(
        title: 'Sinau',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SplashScreen()),
          GetPage(name: '/login', page: () => const LoginScreen()),
          GetPage(name: '/register', page: () => const RegisterScreen()),
          GetPage(name: '/user', page: () => const UserShell(), binding: UserBinding()),
          GetPage(name: '/admin', page: () => const AdminShell(), binding: AdminBinding()),
        ],
      );
}
