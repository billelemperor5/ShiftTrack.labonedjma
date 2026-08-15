import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_design.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import 'all_transactions_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 850;

    if (isDesktop) {
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
                final transactions = provider.transactions;
                return Column(
                  children: [
                    _WalletHeader(provider: provider, isDark: isDark),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Balance & Summary
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _DesktopBalanceCard(
                                        provider: provider,
                                        isDark: isDark,
                                        onNewOperation: () => _showAddTransactionSheet(context),
                                      ),
                                      const SizedBox(height: 20),
                                      _DesktopCategoryBreakdownCard(
                                        provider: provider,
                                        isDark: isDark,
                                        onSurface: onSurface,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Right Column: Transactions History
                                Expanded(
                                  flex: 7,
                                  child: _DesktopHistoryCard(
                                    transactions: transactions,
                                    isDark: isDark,
                                    onSurface: onSurface,
                                    onNewOperation: () => _showAddTransactionSheet(context),
                                    onSelectTransaction: (t) => _showTransactionDetailSheet(context, t),
                                    onViewAll: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AllTransactionsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
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
              final transactions = provider.transactions;
              final visibleTransactions = transactions.take(4).toList();

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _WalletHeader(provider: provider, isDark: isDark),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NewOperationButton(
                            onTap: () => _showAddTransactionSheet(context),
                          ),
                          const SizedBox(height: 22),
                          _HistoryHeader(
                            count: transactions.length,
                            onViewAll: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AllTransactionsScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  if (transactions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyWalletState(onSurface: onSurface),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _TransactionTile(
                            transaction: visibleTransactions[index],
                            isDark: isDark,
                            onTap: () => _showTransactionDetailSheet(
                              context,
                              visibleTransactions[index],
                            ),
                          ),
                          childCount: visibleTransactions.length,
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

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionBottomSheet(),
    );
  }

  void _showTransactionDetailSheet(
    BuildContext context,
    Transaction transaction,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheet(transaction: transaction),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  final TransactionProvider provider;
  final bool isDark;

  const _WalletHeader({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final balance = provider.currentBalance;
    final entries = provider.monthlyEntrees;
    final withdrawals = provider.monthlySorties;
    final net = entries - withdrawals;

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.70) : const Color(0xFF475569);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 850;

    if (isDesktop) {
      final gradientColors = isDark 
          ? const [Color(0xFF0D1E1B), Color(0xFF091412)]
          : const [Color(0xFF0D9488), Color(0xFF0F766E)];
      final borderSideColor = isDark ? Colors.white10 : const Color(0xFF0F766E).withValues(alpha: 0.15);
      return Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          border: Border(bottom: BorderSide(color: borderSideColor)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Portefeuille & Dépenses',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Suivi financier, solde et transactions',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildDesktopHeaderMetric('Solde actuel', '${_money(balance)} DA', const Color(0xFF0F766E), isDark),
                    const SizedBox(width: 14),
                    _buildDesktopHeaderMetric('Entrées ce mois', '+${_money(entries)} DA', const Color(0xFF10B981), isDark),
                    const SizedBox(width: 14),
                    _buildDesktopHeaderMetric('Sorties ce mois', '-${_money(withdrawals)} DA', const Color(0xFFF43F5E), isDark),
                    const SizedBox(width: 20),
                    _HeaderButton(
                      icon: Icons.receipt_long_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllTransactionsScreen(),
                          ),
                        );
                      },
                      isWhite: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppDesign.heroGradient(isDark),
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36),
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
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (isDark) ...[
              Positioned(
                right: -50,
                top: -46,
                child: _SoftCircle(
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.065),
                ),
              ),
              Positioned(
                right: 28,
                bottom: 52,
                child: Transform.rotate(
                  angle: -0.18,
                  child: const _DecorativeCard(),
                ),
              ),
              Positioned(
                left: -54,
                bottom: 8,
                child: _SoftCircle(
                  size: 132,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      _HeaderButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Text(
                        'Portefeuille',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    _HeaderButton(
                      icon: Icons.receipt_long_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllTransactionsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Solde actuel',
                  style: TextStyle(
                    color: subColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${_money(balance)} DA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _NetBadge(value: net),
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.analytics_rounded,
                                size: 16,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.82)
                                    : const Color(0xFF475569),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Total ce mois',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.78)
                                      : const Color(0xFF475569),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              _HeaderMetric(
                                icon: Icons.south_west_rounded,
                                label: 'Entrées',
                                value: '${_money(entries)} DA',
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                              ),
                              Container(
                                width: 1,
                                height: 48,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.13)
                                    : const Color(0xFFE2E8F0),
                              ),
                              _HeaderMetric(
                                icon: Icons.north_east_rounded,
                                label: 'Sorties',
                                value: '${_money(withdrawals)} DA',
                                color: const Color(0xFFF59E0B),
                                isDark: isDark,
                              ),
                            ],
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
      );
  }

  Widget _buildDesktopHeaderMetric(String label, String value, Color color, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.70),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _DecorativeCard extends StatelessWidget {
  const _DecorativeCard();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        width: 126,
        height: 78,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                width: 28,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                width: 72,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white.withValues(alpha: 0.34),
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetBadge extends StatelessWidget {
  final double value;

  const _NetBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final color = isPositive
        ? const Color(0xFF6EE7B7)
        : const Color(0xFFFCA5A5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            '${isPositive ? '+' : '-'} ${_money(value.abs())} DA ce mois',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _HeaderMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.60)
                        : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopBalanceCard extends StatelessWidget {
  final TransactionProvider provider;
  final bool isDark;
  final VoidCallback onNewOperation;

  const _DesktopBalanceCard({
    required this.provider,
    required this.isDark,
    required this.onNewOperation,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final balance = provider.currentBalance;
    final entries = provider.monthlyEntrees;
    final withdrawals = provider.monthlySorties;
    final net = entries - withdrawals;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.84 : 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solde Total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: onSurface.withValues(alpha: 0.55),
                ),
              ),
              _NetBadge(value: net),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_money(balance)} DA',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: onSurface,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Entrées',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: 0.60),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+${_money(entries)} DA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF43F5E).withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, color: Color(0xFFF43F5E), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Sorties',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: 0.60),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '-${_money(withdrawals)} DA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF43F5E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onNewOperation,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Nouvelle opération',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopCategoryBreakdownCard extends StatelessWidget {
  final TransactionProvider provider;
  final bool isDark;
  final Color onSurface;

  const _DesktopCategoryBreakdownCard({
    required this.provider,
    required this.isDark,
    required this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final transactions = provider.transactions;
    final totalSpent = provider.monthlySorties;

    // Group expenses by category
    final Map<String, double> categorySums = {};
    for (final t in transactions) {
      if (t.type == TransactionType.withdrawal) {
        categorySums[t.category] = (categorySums[t.category] ?? 0) + t.amount;
      }
    }

    final categories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.84 : 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category_rounded, color: Color(0xFF2563EB), size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Dépenses par catégorie',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Aucune dépense enregistrée',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.40),
                  ),
                ),
              ),
            )
          else
            ...categories.take(5).map((e) {
              final pct = totalSpent > 0 ? (e.value / totalSpent) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        Text(
                          '${_money(e.value)} DA (${(pct * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: onSurface.withValues(alpha: 0.70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DesktopHistoryCard extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isDark;
  final Color onSurface;
  final VoidCallback onNewOperation;
  final Function(Transaction) onSelectTransaction;
  final VoidCallback onViewAll;

  const _DesktopHistoryCard({
    required this.transactions,
    required this.isDark,
    required this.onSurface,
    required this.onNewOperation,
    required this.onSelectTransaction,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final visible = transactions.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: isDark ? 0.84 : 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Historique des opérations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${transactions.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: onSurface.withValues(alpha: 0.70),
                      ),
                    ),
                  ),
                ],
              ),
              if (transactions.length > 6)
                TextButton.icon(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text(
                    'Voir tout',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 32,
                        color: onSurface.withValues(alpha: 0.25),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune opération enregistrée',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ajoutez votre première entrée ou sortie pour suivre votre solde.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onSurface.withValues(alpha: 0.40),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: onNewOperation,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Ajouter une opération'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...visible.map(
              (t) => _TransactionTile(
                transaction: t,
                isDark: isDark,
                onTap: () => onSelectTransaction(t),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewOperationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NewOperationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      radius: 24,
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 25),
            SizedBox(width: 10),
            Text(
              'Nouvelle opération',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final int count;
  final VoidCallback onViewAll;

  const _HistoryHeader({required this.count, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.history_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Historique',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        const Spacer(),
        if (count > 4)
          _Pressable(
            radius: 999,
            onTap: onViewAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(
                'Tout voir',
                style: TextStyle(
                  color: const Color(0xFF0F766E),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.14),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : color.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.06 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
                      DateFormat('dd MMM yyyy', 'fr').format(transaction.date),
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.43),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((transaction.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        transaction.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.34),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isDeposit ? '+' : '-'} ${_money(transaction.amount)} DA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: onSurface.withValues(alpha: 0.22),
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWalletState extends StatelessWidget {
  final Color onSurface;

  const _EmptyWalletState({required this.onSurface});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.045)
                : Colors.white.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: onSurface.withValues(alpha: 0.055)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F766E).withValues(alpha: 0.10),
                      const Color(0xFF2563EB).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: onSurface.withValues(alpha: 0.18),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune opération enregistrée',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: onSurface.withValues(alpha: 0.48),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ajoutez votre première entrée ou sortie pour suivre votre solde.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: onSurface.withValues(alpha: 0.34),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTransactionBottomSheet extends StatefulWidget {
  const AddTransactionBottomSheet({super.key});

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  TransactionType _type = TransactionType.deposit;
  String _category = 'Salaire';
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  final List<String> _categories = [
    'Salaire',
    'Prime',
    'Transport',
    'Nourriture',
    'Facture',
    'Autre',
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;
    final activeColor = _type == TransactionType.deposit
        ? const Color(0xFF10B981)
        : const Color(0xFFF43F5E);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : activeColor.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.16),
                blurRadius: 36,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Stack(
              children: [
                Positioned(
                  right: -60,
                  top: -70,
                  child: _SoftCircle(
                    size: 180,
                    color: activeColor.withValues(alpha: 0.08),
                  ),
                ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
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
                      const SizedBox(height: 18),
                      _SheetTitle(type: _type),
                      const SizedBox(height: 20),
                      _TypeSegment(
                        type: _type,
                        onChanged: (value) => setState(() => _type = value),
                      ),
                      const SizedBox(height: 16),
                      _AmountField(
                        controller: _amountCtrl,
                        accent: activeColor,
                      ),
                      const SizedBox(height: 12),
                      _CategoryPicker(
                        value: _category,
                        categories: _categories,
                        onChanged: (value) => setState(() => _category = value),
                      ),
                      const SizedBox(height: 12),
                      _PremiumTextField(
                        controller: _noteCtrl,
                        hint: 'Note (optionnelle)',
                        icon: Icons.notes_rounded,
                      ),
                      const SizedBox(height: 12),
                      _DatePickerTile(
                        date: _date,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            locale: const Locale('fr'),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                      ),
                      const SizedBox(height: 20),
                      _SaveButton(type: _type, onTap: _save),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant valide.')),
      );
      return;
    }

    context.read<TransactionProvider>().addTransaction(
      Transaction(
        type: _type,
        amount: amount,
        category: _category,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        date: _date,
      ),
    );
    Navigator.pop(context);
  }
}

class _SheetTitle extends StatelessWidget {
  final TransactionType type;

  const _SheetTitle({required this.type});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDeposit = type == TransactionType.deposit;

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDeposit
                  ? const [Color(0xFF0F766E), Color(0xFF10B981)]
                  : const [Color(0xFFF97316), Color(0xFFF43F5E)],
            ),
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color:
                    (isDeposit
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF43F5E))
                        .withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isDeposit ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle opération',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isDeposit
                    ? 'Enregistrer une entrée financière'
                    : 'Enregistrer une sortie financière',
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.48),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeSegment extends StatelessWidget {
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  const _TypeSegment({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _TypeButton(
            selected: type == TransactionType.deposit,
            label: 'Dépôt',
            icon: Icons.arrow_downward_rounded,
            color: const Color(0xFF10B981),
            onTap: () => onChanged(TransactionType.deposit),
          ),
          _TypeButton(
            selected: type == TransactionType.withdrawal,
            label: 'Retrait',
            icon: Icons.arrow_upward_rounded,
            color: const Color(0xFFF43F5E),
            onTap: () => onChanged(TransactionType.withdrawal),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.selected,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Expanded(
      child: _Pressable(
        radius: 18,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.76)
                  : Colors.transparent,
              width: 1.3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? color : onSurface.withValues(alpha: 0.38),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : onSurface.withValues(alpha: 0.48),
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

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;

  const _AmountField({required this.controller, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.055)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.payments_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
              ],
              style: TextStyle(
                color: onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
              decoration: InputDecoration(
                hintText: 'Montant',
                hintStyle: TextStyle(
                  color: onSurface.withValues(alpha: 0.34),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
          Text(
            'DA',
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.50),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _PremiumTextField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return TextField(
      controller: controller,
      style: TextStyle(
        color: onSurface,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: onSurface.withValues(alpha: 0.42),
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(icon, color: onSurface.withValues(alpha: 0.48)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.055)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.4),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final String value;
  final List<String> categories;
  final ValueChanged<String> onChanged;

  const _CategoryPicker({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.055)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_rounded,
            color: onSurface.withValues(alpha: 0.46),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: onSurface.withValues(alpha: 0.45),
                ),
                dropdownColor: isDark ? const Color(0xFF17232D) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(
                            color: onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerTile({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return _Pressable(
      radius: 20,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.055)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: onSurface.withValues(alpha: 0.46),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('dd MMMM yyyy', 'fr').format(date),
                style: TextStyle(color: onSurface, fontWeight: FontWeight.w800),
              ),
            ),
            Icon(
              Icons.edit_rounded,
              size: 16,
              color: onSurface.withValues(alpha: 0.38),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final TransactionType type;
  final VoidCallback onTap;

  const _SaveButton({required this.type, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDeposit = type == TransactionType.deposit;
    final color = isDeposit ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    return _Pressable(
      radius: 22,
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDeposit
                ? const [Color(0xFF0F766E), Color(0xFF10B981)]
                : const [Color(0xFFF97316), Color(0xFFF43F5E)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Enregistrer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
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
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isDeposit
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: color,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDeposit ? 'Dépôt' : 'Retrait',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        DateFormat(
                          'EEEE, dd MMMM yyyy',
                          'fr',
                        ).format(transaction.date),
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.45),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    icon: Icons.category_rounded,
                    label: 'Catégorie',
                    value: transaction.category,
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.notes_rounded,
                    label: 'Note',
                    value: (transaction.note ?? '').isEmpty
                        ? 'Aucune note'
                        : transaction.note!,
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
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
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

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isWhite;

  const _HeaderButton({required this.icon, required this.onTap, this.isWhite = false});

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
          color: isWhite || isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isWhite || isDark
                ? Colors.white.withValues(alpha: 0.22)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(
          icon,
          color: isWhite || isDark ? Colors.white : const Color(0xFF0F172A),
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
