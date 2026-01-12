import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class AirtimeScreen extends StatelessWidget {
  const AirtimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Airtime'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionCard(
            icon: Icons.phone_android,
            title: 'Buy Airtime',
            subtitle: 'Send airtime to any phone number',
            onTap: () => context.push('/airtime/select-country'),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.data_usage,
            title: 'Buy Data',
            subtitle: 'Purchase internet data bundles',
            onTap: () => context.push('/data/select-country'),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: Icons.receipt_long,
            title: 'Pay Bills',
            subtitle: 'Pay utility bills and services',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

