import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/sale_point_repository.dart';
import '../domain/sale_point.dart';

/// Gestão de Pontos de Venda / vendedores (admin): listar, cadastrar e excluir.
/// O próprio admin (usuário logado) é filtrado da lista.
class SalePointsPage extends ConsumerWidget {
  const SalePointsPage({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo ponto de venda'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Nome / usuário *')),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha *')),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail')),
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
    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final pass = passCtrl.text;
    if (name.isEmpty || pass.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nome e senha são obrigatórios'),
          backgroundColor: AppColors.red));
      return;
    }
    try {
      await ref
          .read(salePointRepositoryProvider)
          .create(name: name, password: pass, email: emailCtrl.text.trim());
      ref.invalidate(salePointsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ponto de venda cadastrado'),
          backgroundColor: AppColors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(toApiException(e).message),
          backgroundColor: AppColors.red));
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, SalePoint sp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir ponto de venda'),
        content: Text('Excluir "${sp.name}"? Esta ação não pode ser desfeita.'),
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
      await ref.read(salePointRepositoryProvider).delete(sp.id);
      ref.invalidate(salePointsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ponto de venda excluído'),
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
    final points = ref.watch(salePointsProvider);
    final selfId = ref.watch(currentSalePointIdProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('NOVO'),
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async => ref.invalidate(salePointsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text('PONTOS DE VENDA',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.lg),
            AsyncValueWidget<List<SalePoint>>(
              value: points,
              onRetry: () => ref.invalidate(salePointsProvider),
              data: (all) {
                // Esconde o próprio admin logado da lista de vendedores.
                final list = all.where((p) => p.id != selfId).toList();
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Nenhum ponto de venda',
                      subtitle: 'Cadastre o primeiro vendedor no botão NOVO.');
                }
                return Container(
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.table),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      for (final p in list)
                        ListTile(
                          // Toque abre as "Vendas por Banca" daquele ponto.
                          onTap: () => context.push(
                              '/admin/points/${p.id}/sales'
                              '?name=${Uri.encodeQueryComponent(p.name)}'),
                          leading: CircleAvatar(
                            backgroundColor: context.mutedSurface,
                            child: Text(
                                p.name.isNotEmpty
                                    ? p.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              (p.email != null && p.email!.isNotEmpty)
                                  ? p.email!
                                  : 'Toque para ver as vendas'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Vendas da banca',
                                icon: const Icon(Icons.receipt_long_outlined,
                                    color: AppColors.green),
                                onPressed: () => context.push(
                                    '/admin/points/${p.id}/sales'
                                    '?name=${Uri.encodeQueryComponent(p.name)}'),
                              ),
                              IconButton(
                                tooltip: 'Excluir',
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.red),
                                onPressed: () => _delete(context, ref, p),
                              ),
                            ],
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
