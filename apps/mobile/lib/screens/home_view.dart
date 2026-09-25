import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_view_model.dart';
import '../theme/app_theme.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Consumer<AuthViewModel>(
                builder: (context, auth, _) => _RoleBadge(
                  role: auth.userRole ?? 'user',
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
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
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _workspaceMessage(role),
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Workspace', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.description_outlined,
            title: 'Medical reports',
            subtitle: 'Review clinical reports stored by the reports service.',
            onTap: () => onOpenTab(1),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.calendar_month_outlined,
            title: 'Appointments',
            subtitle: 'View appointments from the scheduling service.',
            onTap: () => onOpenTab(2),
          ),
          if (isProvider) ...[
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.groups_2_outlined,
              title: 'Patients',
              subtitle: 'View patient accounts available to your care role.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PatientsView()),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.manage_accounts_outlined,
            title: 'Account',
            subtitle: 'Review your authenticated identity and session.',
            onTap: () => onOpenTab(3),
          ),
        ],
      ),
    );
  }

  static String _workspaceMessage(String role) {
    switch (role) {
      case 'doctor':
        return 'Manage patient care, reports and scheduled consultations.';
      case 'radiologist':
        return 'Review reporting workflows and scheduled clinical activity.';
      case 'patient':
        return 'Access your reports, appointments and account information.';
      case 'admin':
        return 'Manage clinical workflows with administrator access.';
      default:
        return 'Your secure PulmoCare clinical workspace.';
    }
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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
