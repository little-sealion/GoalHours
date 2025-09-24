import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:goalhours/monetization/premium_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Status'),
            subtitle: Text(premium.isPremium ? 'Premium active' : 'Free tier'),
            leading: Icon(premium.isPremium ? Icons.verified : Icons.lock_open),
          ),
          const SizedBox(height: 8),
          if (!premium.isPremium) ...[
            FilledButton(
              onPressed: () async {
                try {
                  final ok = await context.read<PremiumController>().purchasePremium();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Purchase flow started' : 'Purchase cancelled')),
                  );
                } on Exception catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Purchase failed: $e')),
                  );
                }
              },
              child: const Text('Go Premium'),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: () async {
              try {
                await context.read<PremiumController>().restorePurchases();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restore complete')),
                );
              } on PurchasesErrorCode catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restore failed: $e')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restore failed: $e')),
                );
              }
            },
            child: const Text('Restore purchases'),
          ),
        ],
      ),
    );
  }
}
