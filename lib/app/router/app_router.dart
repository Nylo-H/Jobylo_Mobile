import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/applications/presentation/pages/applicants_page.dart';
import '../../features/applications/presentation/pages/my_applications_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/jobs/presentation/pages/jobs_page.dart';
import '../../features/jobs/presentation/pages/job_detail_page.dart';
import '../../features/jobs/presentation/pages/my_jobs_page.dart';
import '../../features/kyc/presentation/pages/kyc_page.dart';
import '../../features/messages/presentation/pages/messages_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import 'shell_scaffold.dart';

// ChangeNotifier that wraps the Riverpod auth state so GoRouter can listen to it
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  bool get isLoggedIn =>
      _ref.read(authStateProvider).valueOrNull != null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: '/jobs',
    refreshListenable: notifier,
    redirect: (context, state) {
      // While loading, don't redirect
      if (ref.read(authStateProvider).isLoading) return null;

      final isLoggedIn = notifier.isLoggedIn;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/jobs';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/auth/otp',
        name: 'otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpPage(email: email);
        },
      ),

      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/jobs',
            name: 'jobs',
            builder: (context, state) => const JobsPage(),
          ),
          GoRoute(
            path: '/my-jobs',
            name: 'my-jobs',
            builder: (context, state) => const MyJobsPage(),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      GoRoute(
        path: '/kyc',
        name: 'kyc',
        builder: (context, state) => const KycPage(),
      ),
      GoRoute(
        path: '/my-applications',
        name: 'my-applications',
        builder: (context, state) =>
            const MyApplicationsPage(standalone: true),
      ),
      GoRoute(
        path: '/jobs/:jobId',
        name: 'job-detail',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          return JobDetailPage(jobId: jobId);
        },
      ),
      GoRoute(
        path: '/jobs/:jobId/applicants',
        name: 'job-applicants',
        builder: (context, state) {
          final jobId = state.pathParameters['jobId']!;
          final jobTitle =
              state.uri.queryParameters['title'] ?? 'Candidatures';
          return ApplicantsPage(jobId: jobId, jobTitle: jobTitle);
        },
      ),
    ],
  );
});
