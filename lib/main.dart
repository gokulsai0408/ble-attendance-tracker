import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme/app_theme.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/student_dashboard/controllers/student_dashboard_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentDashboardController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Attendance Tracker',
      theme: AppTheme.lightTheme,
      home: const RoleSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
