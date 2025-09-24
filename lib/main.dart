import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'app_router.dart';
import 'data/project_repo.dart';
import 'data/session_repo.dart';
import 'features/projects/projects_ctrl.dart';
import 'features/timer/timer_ctrl.dart';
import 'monetization/premium_provider.dart';
import 'monetization/ads.dart';
import 'dart:io' show Platform;
import 'monetization/revenuecat_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Google Mobile Ads early
  await Ads.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProjectRepo>(create: (_) => const ProjectRepo()),
        Provider<SessionRepo>(create: (_) => const SessionRepo()),
        // Premium / RevenueCat
        ChangeNotifierProvider<PremiumController>(
          create: (_) {
            final ctrl = PremiumController();
            // Choose platform SDK key. These are placeholders until you set real keys.
            final apiKey = Platform.isIOS ? kRevenueCatApiKeyIOS : kRevenueCatApiKeyAndroid;
            // Safe no-op if keys are placeholders.
            // Intentionally not awaiting; initialize asynchronously.
            // ignore: discarded_futures
            ctrl.initialize(apiKey: apiKey);
            return ctrl;
          },
        ),
        ChangeNotifierProvider<ProjectsController>(
          create: (ctx) {
            final c = ProjectsController(ctx.read<ProjectRepo>());
            c.initialize();
            return c;
          },
        ),
        ChangeNotifierProvider<TimerController>(
          create: (ctx) => TimerController(ctx.read<SessionRepo>())..refresh(),
        ),
      ],
      child: MaterialApp.router(
        title: 'GoalHours',
        theme: buildAppTheme(),
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
