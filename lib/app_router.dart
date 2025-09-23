import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/projects/projects_page.dart';
import 'features/projects/edit_project_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'projects',
      builder: (BuildContext context, GoRouterState state) => const ProjectsPage(),
    ),
    GoRoute(
      path: '/edit',
      name: 'editProject',
      builder: (BuildContext context, GoRouterState state) => const EditProjectPage(),
    ),
  ],
);
