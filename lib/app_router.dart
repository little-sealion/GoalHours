import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/projects/projects_page.dart';
import 'features/projects/edit_project_page.dart';
import 'features/projects/project_detail_page.dart';
import 'features/projects/archived_projects_page.dart';
import 'features/settings/settings_page.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'projects',
      builder: (BuildContext context, GoRouterState state) => const ProjectsPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (BuildContext context, GoRouterState state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/archived',
      name: 'archivedProjects',
      builder: (BuildContext context, GoRouterState state) => const ArchivedProjectsPage(),
    ),
    GoRoute(
      path: '/edit',
      name: 'editProject',
      builder: (BuildContext context, GoRouterState state) => const EditProjectPage(),
    ),
    GoRoute(
      path: '/edit/:id',
      name: 'editProjectById',
      builder: (BuildContext context, GoRouterState state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('Invalid project id')));
        }
        return EditProjectPage(projectId: id);
      },
    ),
    GoRoute(
      path: '/project/:id',
      name: 'projectDetail',
      builder: (BuildContext context, GoRouterState state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) {
          return const Scaffold(body: Center(child: Text('Invalid project id')));
        }
        return ProjectDetailPage(projectId: id);
      },
    ),
  ],
);
