import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/client_repository.dart';
import '../domain/client.dart';
import 'client_history_page.dart';

class ClientsPage extends ConsumerWidget {
  const ClientsPage({super.key});

  Future<void> _addClient(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome *')),
            const SizedBox(height: AppSpacing.sm),
            TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone')),
            const SizedBox(height: AppSpacing.sm),
            TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('SALVAR')),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(clientRepositoryProvider).create(
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            email: emailCtrl.text.trim(),
          );
      ref.invalidate(clientsProvider);
      ref.invalidate(clientRankingProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cliente cadastrado'),
          backgroundColor: AppColors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(toApiException(e).message),
          backgroundColor: AppColors.red));
    }
  }

  Future<void> _editClient(
      BuildContext context, WidgetRef ref, Client client) async {
    final nameCtrl = TextEditingController(text: client.name);
    final phoneCtrl = TextEditingController(text: client.phone ?? '');
    final emailCtrl = TextEditingController(text: client.email ?? '');
    final notesCtrl = TextEditingController(text: client.notes ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome *')),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone')),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail')),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Observações')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('SALVAR')),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    try {
      await ref.read(clientRepositoryProvider).update(
            client.id,
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            notes: notesCtrl.text.trim(),
          );
      ref.invalidate(clientsProvider);
      ref.invalidate(clientRankingProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cliente atualizado'),
          backgroundColor: AppColors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(toApiException(e).message),
          backgroundColor: AppColors.red));
    }
  }

  Future<void> _deleteClient(
      BuildContext context, WidgetRef ref, Client client) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: Text('Excluir "${client.name}"? Esta ação não pode ser '
            'desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('EXCLUIR',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(clientRepositoryProvider).delete(client.id);
      ref.invalidate(clientsProvider);
      ref.invalidate(clientRankingProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cliente excluído'),
          backgroundColor: AppColors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(toApiException(e).message),
          backgroundColor: AppColors.red));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentRoleProvider) == UserRole.admin;
    final clients = ref.watch(clientsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addClient(context, ref),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('NOVO'),
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async {
          ref.invalidate(clientsProvider);
          ref.invalidate(clientRankingProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(isAdmin ? 'CLIENTES (TODOS OS PONTOS)' : 'MEUS CLIENTES',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.lg),
            if (isAdmin) ...[
              const _RankingSection(),
              const SizedBox(height: AppSpacing.xl),
              const Text('TODOS OS CLIENTES',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.grey)),
              const SizedBox(height: AppSpacing.sm),
            ],
            AsyncValueWidget<List<Client>>(
              value: clients,
              onRetry: () => ref.invalidate(clientsProvider),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.people_outline,
                      title: 'Nenhum cliente ainda',
                      subtitle: 'Cadastre o primeiro no botão NOVO.');
                }
                return Container(
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.table),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      for (final c in list)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.mutedSurface,
                            child: Text(
                                c.name.isNotEmpty
                                    ? c.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(c.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text([
                            if (c.phone != null && c.phone!.isNotEmpty) c.phone!,
                            if (c.email != null && c.email!.isNotEmpty) c.email!,
                          ].join('  ·  ')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdmin)
                                Text('Ponto #${c.salePointId}',
                                    style: const TextStyle(
                                        color: AppColors.grey, fontSize: 12)),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    color: AppColors.grey),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editClient(context, ref, c);
                                  } else if (value == 'delete') {
                                    _deleteClient(context, ref, c);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.edit_outlined),
                                          title: Text('Editar'))),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.delete_outline,
                                              color: AppColors.red),
                                          title: Text('Excluir',
                                              style: TextStyle(
                                                  color: AppColors.red)))),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ClientHistoryPage(client: c)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _RankingSection extends ConsumerWidget {
  const _RankingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(clientRankingProvider);
    return AsyncValueWidget<List<ClientRanking>>(
      value: ranking,
      onRetry: () => ref.invalidate(clientRankingProvider),
      data: (list) {
        final top = list.where((c) => c.totalSpent > 0).take(5).toList();
        if (top.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MELHORES CLIENTES',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.grey)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: context.cardSurface,
                borderRadius: BorderRadius.circular(AppRadii.table),
                border: Border.all(color: context.borderColor),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  for (int i = 0; i < top.length; i++) ...[
                    if (i > 0) const Divider(height: AppSpacing.lg),
                    Row(
                      children: [
                        Text('${i + 1}  ',
                            style: const TextStyle(
                                color: AppColors.grey,
                                fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(top[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        Text('${top[i].ordersCount}x  ',
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 12)),
                        Text(currencyBRL(top[i].totalSpent),
                            style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
