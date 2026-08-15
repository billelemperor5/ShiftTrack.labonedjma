import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_design.dart';
import '../../models/payroll_slip.dart';
import '../../providers/payroll_provider.dart';
import '../../utils/storage_utils.dart';
import '../../utils/image_helper.dart';
import 'payroll_details_screen.dart';

class PayrollSlipsScreen extends StatelessWidget {
  const PayrollSlipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 850;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: isDesktop
            ? null
            : _AddPayrollFab(
                onTap: () => _showAddSlipSheet(context),
              ),
        body: Container(
          decoration: AppDesign.pageBackground(isDark),
          child: Consumer<PayrollProvider>(
            builder: (context, provider, _) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _PayrollHeader(
                    slips: provider.slips,
                    onAddSlip: () => _showAddSlipSheet(context),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                          child: _SectionTitle(count: provider.slips.length),
                        ),
                      ),
                    ),
                  ),
                  if (provider.slips.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: _EmptyPayrollState(
                            onAdd: () => _showAddSlipSheet(context),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                            child: isDesktop
                                ? GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: width > 1150 ? 3 : 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: width > 1150 ? 2.0 : 2.4,
                                    ),
                                    itemCount: provider.slips.length,
                                    itemBuilder: (context, index) => _PayrollSlipCard(
                                      slip: provider.slips[index],
                                      onView: () => _viewImage(
                                        context,
                                        provider.slips[index].imagePath,
                                        _monthLabel(provider.slips[index].date),
                                      ),
                                      onDetails: () => _viewDetails(
                                        context,
                                        provider.slips[index].date,
                                      ),
                                      onDelete: () => _confirmDelete(
                                        context,
                                        provider.slips[index],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: provider.slips.length,
                                    itemBuilder: (context, index) => _PayrollSlipCard(
                                      slip: provider.slips[index],
                                      onView: () => _viewImage(
                                        context,
                                        provider.slips[index].imagePath,
                                        _monthLabel(provider.slips[index].date),
                                      ),
                                      onDetails: () => _viewDetails(
                                        context,
                                        provider.slips[index].date,
                                      ),
                                      onDelete: () => _confirmDelete(
                                        context,
                                        provider.slips[index],
                                      ),
                                    ),
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

  void _confirmDelete(BuildContext context, PayrollSlip slip) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Supprimer',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('Voulez-vous vraiment supprimer cette fiche ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<PayrollProvider>().deleteSlip(slip);
              Navigator.pop(context);
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

  void _viewImage(BuildContext context, String path, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenViewer(imagePath: path, title: title),
      ),
    );
  }

  void _viewDetails(BuildContext context, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PayrollDetailsScreen(monthDate: date)),
    );
  }

  void _showAddSlipSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddSlipBottomSheet(),
    );
  }
}

class _PayrollHeader extends StatelessWidget {
  final List<PayrollSlip> slips;
  final VoidCallback onAddSlip;

  const _PayrollHeader({
    required this.slips,
    required this.onAddSlip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;
    final latest = slips.isEmpty
        ? 'Aucune fiche'
        : _monthLabel(slips.first.date);

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white70 : const Color(0xFF475569);

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 850;

    if (isDesktop) {
      final gradientColors = isDark 
          ? const [Color(0xFF0D1E1B), Color(0xFF091412)]
          : const [Color(0xFF0D9488), Color(0xFF0F766E)];
      final borderSideColor = isDark ? Colors.white10 : const Color(0xFF0F766E).withValues(alpha: 0.15);
      return SliverToBoxAdapter(
        child: Container(
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
                          Icons.receipt_long_rounded,
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
                            'Bulletins de salaire',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Gestion documentaire et fiches de paie',
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
                      _buildDesktopHeaderMetric('Fiches archivées', '${slips.length}', const Color(0xFF0F766E), isDark),
                      const SizedBox(width: 16),
                      _buildDesktopHeaderMetric('Dernière fiche', latest, const Color(0xFF10B981), isDark),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: onAddSlip,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Ajouter une fiche',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0F766E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                right: -56,
                top: -50,
                child: _SoftCircle(
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.065),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 48,
                child: Transform.rotate(
                  angle: -0.16,
                  child: const _PayslipIllustration(),
                ),
              ),
            ],
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (Navigator.canPop(context)) ...[
                          _GlassIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: Text(
                            'Fiches de paie',
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
                        _GlassIconButton(
                          icon: Icons.add_rounded,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const AddSlipBottomSheet(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Gestion documentaire',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Bulletins de salaire',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
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
                          _HeaderMetric(
                            icon: Icons.receipt_long_rounded,
                            label: 'Fiches',
                            value: '${slips.length}',
                            color: const Color(0xFF0F766E),
                            isDark: isDark,
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.13)
                                : const Color(0xFFE2E8F0),
                          ),
                          _HeaderMetric(
                            icon: Icons.calendar_month_rounded,
                            label: 'Dernière fiche',
                            value: latest,
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                        ],
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

class _PayslipIllustration extends StatelessWidget {
  const _PayslipIllustration();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        width: 118,
        height: 144,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 18,
              top: 18,
              child: Container(
                width: 44,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            ...List.generate(
              4,
              (index) => Positioned(
                left: 18,
                top: 44 + (index * 20),
                child: Container(
                  width: index == 2 ? 62 : 78,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6EE7B7).withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 19),
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

class _SectionTitle extends StatelessWidget {
  final int count;

  const _SectionTitle({required this.count});

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
          ),
          child: const Icon(
            Icons.folder_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Mes fiches',
          style: TextStyle(
            color: onSurface,
            fontSize: 19,
            fontWeight: FontWeight.w900,
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
      ],
    );
  }
}

class _PayrollSlipCard extends StatefulWidget {
  final PayrollSlip slip;
  final VoidCallback onView;
  final VoidCallback onDetails;
  final VoidCallback onDelete;

  const _PayrollSlipCard({
    required this.slip,
    required this.onView,
    required this.onDetails,
    required this.onDelete,
  });

  @override
  State<_PayrollSlipCard> createState() => _PayrollSlipCardState();
}

class _PayrollSlipCardState extends State<_PayrollSlipCard> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;
    final imageExists = widget.slip.imagePath.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface.withValues(alpha: isDark ? 0.88 : 0.96),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: onSurface.withValues(alpha: 0.055)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (imageExists) {
                      setState(() => _isRevealed = !_isRevealed);
                    }
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: imageExists
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                AppImageHelper.getImageWidget(
                                  widget.slip.imagePath,
                                  fit: BoxFit.cover,
                                  width: 58,
                                  height: 58,
                                  cacheWidth: 120,
                                  cacheHeight: 120,
                                  errorWidget: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: Color(0xFF0F766E),
                                    size: 25,
                                  ),
                                ),
                                if (!_isRevealed)
                                  Container(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    child: const Icon(
                                      Icons.visibility_off_rounded,
                                      color: Color(0xFF0F766E),
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF0F766E),
                            size: 25,
                          ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _monthLabel(widget.slip.date),
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (widget.slip.note ?? '').isEmpty
                            ? 'Bulletin de salaire enregistré'
                            : widget.slip.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.42),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _RoundDangerButton(onTap: widget.onDelete),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CardActionButton(
                    onTap: widget.onView,
                    text: 'Voir fiche',
                    icon: Icons.visibility_rounded,
                    soft: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardActionButton(
                    onTap: widget.onDetails,
                    text: 'Détails complets',
                    icon: Icons.analytics_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final IconData icon;
  final bool soft;

  const _CardActionButton({
    required this.onTap,
    required this.text,
    required this.icon,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF0F766E);

    return _Pressable(
      radius: 18,
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: soft ? color.withValues(alpha: 0.10) : color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: soft
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: soft ? color : Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: soft ? color : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundDangerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RoundDangerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      radius: 16,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFF43F5E),
          size: 20,
        ),
      ),
    );
  }
}

class _EmptyPayrollState extends StatelessWidget {
  final VoidCallback? onAdd;

  const _EmptyPayrollState({this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 36),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.045)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: onSurface.withValues(alpha: 0.065)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0F766E).withValues(alpha: 0.12),
                      const Color(0xFF2563EB).withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 44,
                  color: const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune fiche enregistrée',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ajoutez votre première fiche pour garder vos bulletins et salaires organisés.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.45),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onAdd != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Ajouter une fiche de paie',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddPayrollFab extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPayrollFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      radius: 22,
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 24),
            SizedBox(width: 9),
            Text(
              'Ajouter fiche',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenViewer extends StatelessWidget {
  final String imagePath;
  final String title;

  const FullScreenViewer({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _Pressable(
                      radius: 18,
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.7,
                    maxScale: 5,
                    child: AppImageHelper.getImageWidget(imagePath),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddSlipBottomSheet extends StatefulWidget {
  const AddSlipBottomSheet({super.key});

  @override
  State<AddSlipBottomSheet> createState() => _AddSlipBottomSheetState();
}

class _AddSlipBottomSheetState extends State<AddSlipBottomSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final savedPath = await StorageUtils.saveImage(pickedFile.path);
      setState(() => _imagePath = savedPath);
    }
  }

  void _save() {
    if (_imagePath == null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une image.')),
      );
      return;
    }

    final slip = PayrollSlip(
      date: _selectedDate,
      imagePath: _imagePath!,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    context.read<PayrollProvider>().addSlip(slip);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = isDark ? const Color(0xFF17232D) : Colors.white;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
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
                    color: const Color(0xFF0F766E).withValues(alpha: 0.08),
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
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
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
                                  'Ajouter une fiche',
                                  style: TextStyle(
                                    color: onSurface,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Bulletin de salaire mensuel',
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
                      ),
                      const SizedBox(height: 18),
                      _SheetTile(
                        icon: Icons.calendar_month_rounded,
                        title: 'Mois de la fiche',
                        value: _monthLabel(_selectedDate),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                            locale: const Locale('fr'),
                            helpText: 'Sélectionner le mois',
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _ImagePickerCard(
                        imagePath: _imagePath,
                        onTap: _pickImage,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteCtrl,
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Note (optionnelle)',
                          hintStyle: TextStyle(
                            color: onSurface.withValues(alpha: 0.42),
                            fontWeight: FontWeight.w700,
                          ),
                          prefixIcon: Icon(
                            Icons.notes_rounded,
                            color: onSurface.withValues(alpha: 0.46),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.055)
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF0F766E),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Pressable(
                        radius: 22,
                        onTap: _save,
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F766E,
                                ).withValues(alpha: 0.24),
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
                      ),
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
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

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
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF0F766E), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
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

class _ImagePickerCard extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const _ImagePickerCard({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hasImage = imagePath != null;

    return _Pressable(
      radius: 24,
      onTap: onTap,
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.055)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasImage
                ? const Color(0xFF0F766E).withValues(alpha: 0.28)
                : onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImageHelper.getImageWidget(imagePath!, fit: BoxFit.cover),
                    Container(color: Colors.black.withValues(alpha: 0.26)),
                    const Center(
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Color(0xFF0F766E),
                      size: 27,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sélectionner l’image de la fiche',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'JPG ou PNG depuis la galerie',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.38),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

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
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.22)
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

String _monthLabel(DateTime date) {
  final value = DateFormat('MMMM yyyy', 'fr').format(date);
  return value[0].toUpperCase() + value.substring(1);
}
