import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'app_router.dart';
import 'data/project_repo.dart';
import 'data/session_repo.dart';
import 'features/projects/projects_ctrl.dart';
import 'features/timer/timer_ctrl.dart';

void main() {
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
