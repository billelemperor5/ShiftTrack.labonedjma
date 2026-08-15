import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_design.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';

class AllTransactionsScreen extends StatelessWidget {
  const AllTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          decoration: AppDesign.pageBackground(isDark),
          child: Consumer<TransactionProvider>(
            builder: (context, provider, _) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _TransactionsHeader(provider: provider),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ChartCard(provider: provider),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0F766E),
                                      Color(0xFF2563EB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Historique complet',
                                style: TextStyle(
                                  color: onSurface,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  if (provider.transactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyTransactions(onSurface: onSurface),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _TransactionRow(
                            transaction: provider.transactions[index],
                            onTap: () => _showTransactionDetail(
                              context,
                              provider.transactions[index],
                            ),
                          ),
                          childCount: provider.transactions.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheet(transaction: transaction),
    );
  }
}

class _TransactionsHeader extends StatelessWidget {
  final TransactionProvider provider;

  const _TransactionsHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white70 : const Color(0xFF475569);

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppDesign.heroGradient(isDark),
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(34),
          ),
          border: isDark
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isDark)
              Positioned(
                right: -52,
                top: -54,
                child: _SoftCircle(
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.065),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toutes les opérations',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Suivi financier détaillé',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _IconButton(
                      icon: Icons.delete_sweep_rounded,
                      onTap: () => _showResetDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.13)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.17)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          _HeaderStat(
                            label: 'Solde',
                            value: '${_money(provider.currentBalance)} DA',
                            icon: Icons.account_balance_wallet_rounded,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            isDark: isDark,
                          ),
                          _Divider(isDark: isDark),
                          _HeaderStat(
                            label: 'Entrées',
                            value: '${_money(provider.monthlyEntrees)} DA',
                            icon: Icons.south_west_rounded,
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                          _Divider(isDark: isDark),
                          _HeaderStat(
                            label: 'Sorties',
                            value: '${_money(provider.monthlySorties)} DA',
                            icon: Icons.north_east_rounded,
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Réinitialiser',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Voulez-vous vraiment supprimer toutes les opérations du portefeuille ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<TransactionProvider>().clearAllTransactions();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(
                color: Color(0xFFF43F5E),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.62) : const Color(0xFF64748B);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: subColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFE2E8F0),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final TransactionProvider provider;

  const _ChartCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final entries = provider.monthlyEntrees;
    final withdrawals = provider.monthlySorties;
    final total = entries + withdrawals;
    final withdrawalRatio = total == 0 ? 0.0 : withdrawals / total;
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.88 : 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: onSurface.withValues(alpha: 0.055)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 45,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: entries == 0 && withdrawals == 0 ? 1 : entries,
                        color: entries == 0 && withdrawals == 0
                            ? onSurface.withValues(alpha: 0.08)
                            : const Color(0xFF10B981),
                        radius: 12,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: withdrawals,
                        color: const Color(0xFFF43F5E),
                        radius: 12,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(withdrawalRatio * 100).round()}%',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Sorties',
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.42),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Structure du mois',
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Entrées et sorties financières',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.42),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _LegendLine(
                  color: const Color(0xFF10B981),
                  label: 'Entrées',
                  value: '${_money(entries)} DA',
                ),
                const SizedBox(height: 10),
                _LegendLine(
                  color: const Color(0xFFF43F5E),
                  label: 'Sorties',
                  value: '${_money(withdrawals)} DA',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendLine({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.56),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionRow({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDeposit = transaction.type == TransactionType.deposit;
    final color = isDeposit ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Pressable(
        radius: 24,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: isDark ? 0.88 : 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.05 : 0.07),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isDeposit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'EEEE, dd MMM yyyy',
                        'fr',
                      ).format(transaction.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.42),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isDeposit ? '+' : '-'} ${_money(transaction.amount)} DA',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;

  const _TransactionDetailSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDeposit = transaction.type == TransactionType.deposit;
    final color = isDeposit ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17232D) : Colors.white,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: color.withValues(alpha: 0.13)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
              blurRadius: 34,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isDeposit ? 'Détail du dépôt' : 'Détail du retrait',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  Text(
                    '${isDeposit ? '+' : '-'} ${_money(transaction.amount)} DA',
                    style: TextStyle(
                      color: color,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    label: 'Catégorie',
                    value: transaction.category,
                    icon: Icons.category_rounded,
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'Date',
                    value: DateFormat(
                      'dd MMMM yyyy',
                      'fr',
                    ).format(transaction.date),
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    label: 'Note',
                    value: (transaction.note ?? '').isEmpty
                        ? 'Aucune note'
                        : transaction.note!,
                    icon: Icons.notes_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Pressable(
              radius: 20,
              onTap: () async {
                await context.read<TransactionProvider>().deleteTransaction(
                  transaction,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFF43F5E),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Supprimer cette opération',
                      style: TextStyle(
                        color: Color(0xFFF43F5E),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, color: onSurface.withValues(alpha: 0.42), size: 18),
        const SizedBox(width: 9),
        Text(
          '$label :',
          style: TextStyle(
            color: onSurface.withValues(alpha: 0.45),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  final Color onSurface;

  const _EmptyTransactions({required this.onSurface});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Aucune opération enregistrée',
        style: TextStyle(
          color: onSurface.withValues(alpha: 0.38),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Pressable(
      radius: 18,
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.14)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          size: 22,
        ),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double radius;

  const _Pressable({
    required this.child,
    required this.onTap,
    required this.radius,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.radius),
          onTap: widget.onTap,
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            setState(() => _pressed = true);
          },
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          splashColor: Colors.white.withValues(alpha: 0.11),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _money(double value) => NumberFormat('#,###', 'fr').format(value);
