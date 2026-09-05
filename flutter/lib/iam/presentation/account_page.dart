import 'package:flutter/material.dart';

import '../../app/localization/app_strings.dart';
import '../../shared/presentation/widgets/brand_mark.dart';
import '../../shared/presentation/widgets/module_widgets.dart';
import '../application/account_controller.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.controller,
    required this.onAccountDeleted,
  });

  final AccountController controller;
  final VoidCallback onAccountDeleted;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.isLoading && widget.controller.profile == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.controller.load(),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.strings.text('account')),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: context.strings.text('profile')),
              Tab(text: context.strings.text('security')),
              Tab(text: context.strings.text('access')),
              Tab(text: context.strings.text('platform')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProfileTab(controller: widget.controller),
            _SecurityTab(
              controller: widget.controller,
              onAccountDeleted: widget.onAccountDeleted,
            ),
            _AccessTab(controller: widget.controller),
            const _PlatformTab(),
          ],
        ),
      ),
    ),
  );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.controller});
  final AccountController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.profile;
    return ModuleBody(
      loading: controller.isLoading,
      failure: controller.failure,
      empty: profile == null,
      onRetry: controller.load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.14),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 38,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile!.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(profile.email),
                  const SizedBox(height: 10),
                  StatusPill(label: profile.accessProfileName, positive: true),
                  const SizedBox(height: 20),
                  FilledButton.tonalIcon(
                    onPressed: controller.isMutating
                        ? null
                        : () => _edit(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(context.strings.text('editProfile')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final profile = controller.profile!;
    final name = TextEditingController(text: profile.fullName);
    final email = TextEditingController(text: profile.email);
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.text('editProfile')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: context.strings.text('fullName'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.strings.text('email'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              name.text.trim().isNotEmpty && email.text.contains('@'),
            ),
            child: Text(context.strings.text('save')),
          ),
        ],
      ),
    );
    if (submitted == true && context.mounted) {
      final success = await controller.updateProfile(
        name.text.trim(),
        email.text.trim(),
      );
      if (context.mounted) showActionResult(context, success);
    }
    name.dispose();
    email.dispose();
  }
}

class _SecurityTab extends StatelessWidget {
  const _SecurityTab({
    required this.controller,
    required this.onAccountDeleted,
  });
  final AccountController controller;
  final VoidCallback onAccountDeleted;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Card(
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const Icon(Icons.password_rounded),
              title: Text(context.strings.text('changePassword')),
              subtitle: Text(context.strings.text('changePasswordDescription')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: controller.isMutating
                  ? null
                  : () => runAction(
                      context,
                      controller.requestRecovery(),
                      context.strings.text('recoverySent'),
                    ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(context.strings.text('deleteAccount')),
              subtitle: Text(context.strings.text('deleteAccountWarning')),
              onTap: controller.isMutating
                  ? null
                  : () async {
                      final confirmed = await showConfirmAction(
                        context,
                        title: context.strings.text('deleteAccount'),
                        message: context.strings.text('deleteAccountWarning'),
                        confirmLabel: context.strings.text('delete'),
                      );
                      if (!confirmed || !context.mounted) return;
                      final success = await controller.deleteAccount();
                      if (success) onAccountDeleted();
                      if (context.mounted) showActionResult(context, success);
                    },
            ),
          ],
        ),
      ),
    ],
  );
}

class _AccessTab extends StatelessWidget {
  const _AccessTab({required this.controller});
  final AccountController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.managedUsers.isEmpty || controller.accessProfiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.strings.text('accessRestricted'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: controller.managedUsers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = controller.managedUsers[index];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              child: Icon(Icons.person_outline_rounded),
            ),
            title: Text(user.fullName),
            subtitle: Text(user.email),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value:
                    controller.accessProfiles.any(
                      (item) => item.id == user.accessProfileId,
                    )
                    ? user.accessProfileId
                    : null,
                hint: Text(user.accessProfileName),
                items: controller.accessProfiles
                    .map(
                      (profile) => DropdownMenuItem(
                        value: profile.id,
                        child: Text(profile.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: controller.isMutating
                    ? null
                    : (value) async {
                        if (value == null) return;
                        await runAction(
                          context,
                          controller.assignProfile(user, value),
                        );
                      },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlatformTab extends StatelessWidget {
  const _PlatformTab();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Center(child: BrandMark()),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.strings.text('platformTitle'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(context.strings.text('platformDescription')),
              const SizedBox(height: 18),
              _capability(
                Icons.bolt_outlined,
                context.strings.text('energyMonitoring'),
              ),
              _capability(
                Icons.devices_other_outlined,
                context.strings.text('deviceAutomation'),
              ),
              _capability(
                Icons.notifications_outlined,
                context.strings.text('smartAlerts'),
              ),
              _capability(
                Icons.analytics_outlined,
                context.strings.text('reportsAndGoals'),
              ),
              _capability(
                Icons.support_agent_outlined,
                context.strings.text('integratedSupport'),
              ),
              const Divider(height: 30),
              const Text(
                'EnergyCore Mobile 1.0.0',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Text(
                'Teralume · Universidad Peruana de Ciencias Aplicadas',
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _capability(IconData icon, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
      ],
    ),
  );
}
