import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/projects/projects_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'projects',
      builder: (BuildContext context, GoRouterState state) => const ProjectsPage(),
    ),
  ],
);
