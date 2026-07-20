import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medilink/core/theme/app_colors.dart';
import 'package:medilink/features/auth/providers/auth_providers.dart';
import 'package:medilink/features/command_center/presentation/providers/command_center_providers.dart';
import 'package:medilink/features/command_center/presentation/screens/emergency_detail_screen.dart';
import 'package:medilink/features/command_center/presentation/widgets/incoming_emergency_card.dart';
import 'package:medilink/features/emergency/domain/entities/emergency_request.dart';

/// Deliberately a separate top-level screen from `AdminDashboardScreen`, per
/// architecture doc §9 — reachable via a nav entry, not a tab inside it.
class CommandCenterDashboardScreen extends ConsumerStatefulWidget {
  const CommandCenterDashboardScreen({super.key});

  @override
  ConsumerState<CommandCenterDashboardScreen> createState() =>
      _CommandCenterDashboardScreenState();
}

class _CommandCenterDashboardScreenState
    extends ConsumerState<CommandCenterDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hospitalIdAsync = ref.watch(currentHospitalIdProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Emergency Command Center'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: hospitalIdAsync.when(
        data: (hospitalId) {
          if (hospitalId == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hospital linked to your account yet. Create your '
                  'hospital, or contact support if you already have one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _CommandCenterBody(hospitalId: hospitalId, tabController: _tabController);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load: $error')),
      ),
    );
  }
}

class _CommandCenterBody extends ConsumerWidget {
  const _CommandCenterBody({required this.hospitalId, required this.tabController});

  final String hospitalId;
  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emergenciesAsync = ref.watch(hospitalEmergenciesProvider(hospitalId));

    return emergenciesAsync.when(
      data: (emergencies) {
        final incoming =
            emergencies.where((e) => incomingStatuses.contains(e.status.name)).toList();
        final active =
            emergencies.where((e) => activeStatuses.contains(e.status.name)).toList();
        final history =
            emergencies.where((e) => historyStatuses.contains(e.status.name)).toList();

        return TabBarView(
          controller: tabController,
          children: [
            _EmergencyList(
              requests: incoming,
              emptyMessage: 'No incoming emergencies right now.',
            ),
            _EmergencyList(
              requests: active,
              emptyMessage: 'No active emergencies.',
            ),
            _EmergencyList(
              requests: history,
              emptyMessage: 'No completed or closed emergencies yet.',
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load emergencies: $error')),
    );
  }
}

class _EmergencyList extends StatelessWidget {
  const _EmergencyList({required this.requests, required this.emptyMessage});

  final List<EmergencyRequest> requests;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: TextStyle(color: AppColors.getTextSecondary(context))),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return EmergencyRequestCard(
          request: request,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmergencyDetailScreen(requestId: request.id),
              ),
            );
          },
        );
      },
    );
  }
}
