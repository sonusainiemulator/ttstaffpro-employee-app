import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';
import '../../utils/app_colors.dart';
import 'payslips_list_screen.dart';
import 'salary_structure_screen.dart';
import 'payroll_records_screen.dart';
import 'modifiers_screen.dart';

class PayrollDashboardScreen extends StatefulWidget {
  const PayrollDashboardScreen({super.key});

  @override
  State<PayrollDashboardScreen> createState() => _PayrollDashboardScreenState();
}

class _PayrollDashboardScreenState extends State<PayrollDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      payrollStore.fetchPayrollStatistics(),
      payrollStore.fetchPayslips(take: 5),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appStore.isDarkModeOn;

    return Scaffold(
      backgroundColor: isDark ? appBackgroundColorDark : appLayoutBackground,
      appBar: AppBar(
        title: Text(
          language.lblPayroll,
          style: TextStyle(
            color: isDark ? Colors.white : appTextColorPrimary, 
            fontWeight: FontWeight.bold
          ),
        ),
        backgroundColor: isDark ? cardBackgroundBlackDark : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : appTextColorPrimary),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) => SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(isDark),
                  const SizedBox(height: 24),
                  _buildActionCardsGrid(isDark),
                  const SizedBox(height: 24),
                  _buildRecentHighlights(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [opPrimaryColor, opPrimaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: opPrimaryColor.withOpacity(0.3), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${language.lblManageYour} ${language.lblPayroll}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'View payslips, check structural breakdowns, and track income',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Iconsax.money_recive, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCardsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _buildMenuCard(
          title: language.lblMyPayslips,
          subtitle: 'View past slips',
          icon: Iconsax.document_download,
          color: Colors.blueAccent,
          isDark: isDark,
          onTap: () => const PayslipsListScreen().launch(context),
        ),
        _buildMenuCard(
          title: language.lblSalaryStructure,
          subtitle: 'Current breakdown',
          icon: Iconsax.chart_square,
          color: Colors.teal,
          isDark: isDark,
          onTap: () => const SalaryStructureScreen().launch(context),
        ),
        _buildMenuCard(
          title: language.lblPayrollRecords,
          subtitle: 'Monthly records',
          icon: Iconsax.document_text,
          color: Colors.orangeAccent,
          isDark: isDark,
          onTap: () => const PayrollRecordsScreen().launch(context),
        ),
        _buildMenuCard(
          title: language.lblModifiers,
          subtitle: 'Earnings & Deductions',
          icon: Iconsax.edit_2,
          color: Colors.purpleAccent,
          isDark: isDark,
          onTap: () => const ModifiersScreen().launch(context),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? cardBackgroundBlackDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: isDark ? Colors.white : appTextColorPrimary
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle, 
              style: TextStyle(
                fontSize: 11, 
                color: isDark ? Colors.grey[400] : appTextColorSecondary
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHighlights(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payroll Highlights',
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : appTextColorPrimary
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? cardBackgroundBlackDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Iconsax.verify, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Set!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16, 
                        color: isDark ? Colors.white : appTextColorPrimary
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your salary structure and active payslips are up to date.',
                      style: TextStyle(
                        fontSize: 13, 
                        color: isDark ? Colors.grey[400] : appTextColorSecondary
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
