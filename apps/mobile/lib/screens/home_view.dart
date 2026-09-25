import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_view_model.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_dialog.dart';
import 'AppointmentsScreen.dart';
import 'account_view.dart';
import 'patients_view.dart';
import 'reports/reports_list_screen.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _index = 0;

  static const _titles = ['Overview', 'Reports', 'Appointments', 'Account'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthViewModel>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardPage(onOpenTab: (index) => setState(() => _index = index)),
      const ReportsListScreen(embedded: true),
      const AppointmentsScreen(embedded: true),
      const AccountView(embedded: true),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final page = IndexedStack(index: _index, children: pages);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const _BrandMark(),
                const SizedBox(width: 10),
                Text(_titles[_index]),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Consumer<AuthViewModel>(
                    builder: (context, auth, _) =>
                        _RoleBadge(role: auth.userRole ?? 'user'),
                  ),
                ),
              ),
            ],
          ),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _index,
                      onDestinationSelected: (value) =>
                          setState(() => _index = value),
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -0.8,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard_rounded),
                          label: Text('Overview'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.description_outlined),
                          selectedIcon: Icon(Icons.description_rounded),
                          label: Text('Reports'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.calendar_month_outlined),
                          selectedIcon: Icon(Icons.calendar_month_rounded),
                          label: Text('Appointments'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline_rounded),
                          selectedIcon: Icon(Icons.person_rounded),
                          label: Text('Account'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: page),
                  ],
                )
              : page,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: 'Overview',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.description_outlined),
                      selectedIcon: Icon(Icons.description_rounded),
                      label: 'Reports',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month_rounded),
                      label: 'Appointments',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Account',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final firstName = (auth.displayName ?? auth.userEmail ?? 'there')
        .trim()
        .split(RegExp(r'\s+'))
        .first;
    final role = auth.userRole ?? 'user';
    final isProvider =
        role == 'doctor' || role == 'radiologist' || role == 'admin';

    return RefreshIndicator(
      onRefresh: auth.fetchProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $firstName',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _workspaceMessage(role),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color(0x22FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Icon(
                              Icons.health_and_safety_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Clinical workspace',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Open the information available to your authenticated role.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 680;
                      final cards = <Widget>[
                        _ActionCard(
                          icon: Icons.description_outlined,
                          title: 'Medical reports',
                          subtitle:
                              'Review reports returned by the reports service.',
                          onTap: () => onOpenTab(1),
                        ),
                        _ActionCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Appointments',
                          subtitle:
                              'Review upcoming and previous clinical appointments.',
                          onTap: () => onOpenTab(2),
                        ),
                        if (isProvider)
                          _ActionCard(
                            icon: Icons.groups_2_outlined,
                            title: 'Patients',
                            subtitle:
                                'Open patient accounts available to your clinical role.',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PatientsView(),
                              ),
                            ),
                          ),
                        if (isProvider)
                          _ActionCard(
                            icon: Icons.auto_awesome_outlined,
                            title: 'Clinical assistant',
                            subtitle:
                                'Get server-backed help with clinical documentation and report wording.',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChatDialog(),
                              ),
                            ),
                          ),
                        _ActionCard(
                          icon: Icons.manage_accounts_outlined,
                          title: 'Account',
                          subtitle:
                              'Review your identity, role and session information.',
                          onTap: () => onOpenTab(3),
                        ),
                      ];

                      if (!twoColumns) {
                        return Column(
                          children: [
                            for (var i = 0; i < cards.length; i++) ...[
                              cards[i],
                              if (i != cards.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }

                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final card in cards)
                            SizedBox(
                              width: (constraints.maxWidth - 14) / 2,
                              child: card,
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _SessionCard(auth: auth),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _workspaceMessage(String role) {
    switch (role) {
      case 'doctor':
        return 'Manage patient care, clinical reports and scheduled consultations.';
      case 'radiologist':
        return 'Review imaging-related reporting workflows and clinical activity.';
      case 'patient':
        return 'Access your reports, appointments and account information.';
      case 'admin':
        return 'Manage clinical workflows with administrator access.';
      default:
        return 'Your secure PulmoCare clinical workspace.';
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.auth});

  final AuthViewModel auth;

  @override
  Widget build(BuildContext context) {
    final email = auth.userEmail;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authenticated session',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email == null || email.isEmpty
                        ? 'Identity verified by PulmoCare.'
                        : 'Signed in as $email',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.lock_outline_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.air_rounded, color: AppTheme.primary, size: 19),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          role.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .7,
          ),
        ),
      ),
    );
  }
}
