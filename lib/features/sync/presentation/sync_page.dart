import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/local/local_store.dart';
import '../../../core/sync/outbox_dao.dart';
import '../../../core/sync/sync_service.dart';
import '../../../shared/widgets/async_value_widget.dart';

/// Sincronização: vendas registradas offline (pendentes) e as que o servidor
/// recusou (falhas), com ações de tentar de novo / descartar. Tela acessível
/// pelo Drawer (push), com AppBar própria.
class SyncPage extends ConsumerWidget {
  const SyncPage({super.key});

  OutboxDao get _outbox => OutboxDao(LocalStore.instance);

  void _refresh(WidgetRef ref) {
    ref.invalidate(outboxEntriesProvider);
    ref.read(syncServiceProvider.notifier).refreshCount();
  }

  Future<void> _retry(BuildContext context, WidgetRef ref, OutboxEntry e) async {
    await _outbox.retry(e.id);
    await ref.read(syncServiceProvider.notifier).flush();
    _refresh(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reenviando…'), backgroundColor: AppColors.black));
  }

  Future<void> _discard(
      BuildContext context, WidgetRef ref, OutboxEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar venda'),
        content: const Text(
            'Descartar esta venda da fila? Ela NÃO será enviada ao servidor.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('DESCARTAR',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await _outbox.remove(e.id);
    _refresh(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Venda descartada'), backgroundColor: AppColors.green));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(outboxEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronização'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sincronizar agora',
            onPressed: () async {
              await ref.read(syncServiceProvider.notifier).flush();
              _refresh(ref);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async => _refresh(ref),
        child: AsyncValueWidget<List<OutboxEntry>>(
          value: entries,
          onRetry: () => _refresh(ref),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 120),
                EmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: 'Tudo sincronizado',
                    subtitle: 'Nenhuma venda na fila.'),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _EntryCard(
                e: list[i],
                onRetry: () => _retry(context, ref, list[i]),
                onDiscard: () => _discard(context, ref, list[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final OutboxEntry e;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;
  const _EntryCard(
      {required this.e, required this.onRetry, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    final failed = e.isFailed;
    final color = failed ? AppColors.red : const Color(0xFFB8860B);
    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(failed ? Icons.error_outline : Icons.sync, color: color, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                    'Venda · ${e.items.length} item(ns)'
                    '${e.paymentMethod != null ? ' · ${e.paymentMethod}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Text(failed ? 'FALHOU' : 'PENDENTE',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          if (failed && e.error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(e.error!,
                style: const TextStyle(color: AppColors.grey, fontSize: 12)),
          ],
          if (failed) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: onDiscard,
                    child: const Text('DESCARTAR',
                        style: TextStyle(color: AppColors.red))),
                TextButton(
                    onPressed: onRetry, child: const Text('TENTAR DE NOVO')),
              ],
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: Text('Aguardando conexão para sincronizar',
                  style: TextStyle(color: AppColors.grey, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
