import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:to_do_9/providers/user_provider.dart';
import 'package:to_do_9/screens/dashboard_screen.dart';
import 'package:to_do_9/utils/constants.dart';
import 'package:to_do_9/widgets/loading_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ChangeNotifierProvider(
          create: (_) => UserProvider(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Gamified Todo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryColor,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              textTheme: Typography.englishLike2021.apply(
                fontSizeFactor: 0.85.sp,
                bodyColor: AppColors.primaryColor,
                displayColor: AppColors.primaryColor,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              textTheme: Typography.englishLike2021.apply(
                fontSizeFactor: 0.85.sp,
                bodyColor: AppColors.primaryColor,
                displayColor: AppColors.primaryColor,
              ),
            ),
            themeMode: ThemeMode.system,
            home: child,
          ),
        );
      },
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          // Show loading screen while user data is being loaded
          if (!userProvider.isInitialized) {
            return const LoadingScreen();
          }

          // Once loaded, show dashboard
          return const DashboardScreen();
        },
      ),
    );
  }
}
