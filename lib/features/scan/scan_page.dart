import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shopping_product.dart';
import '../../providers/shopping_list_provider.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key, this.onBack});

  final VoidCallback? onBack;

  static const _recentLists = [
    'Liste du 13/04/26',
    'Liste du 03/04/26',
    'Liste du 23/03/26',
    'Liste du 13/03/26',
  ];

  @override
  Widget build(BuildContext context) {
    final shoppingList = context.watch<ShoppingListProvider>();
    final products = shoppingList.products;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ShoppingHeader(onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 104),
                children: [
                  const SizedBox(height: 6),
                  const _RecipePagerLabel(),
                  const SizedBox(height: 18),
                  _ImportActions(onComingSoon: _showComingSoon),
                  const SizedBox(height: 16),
                  for (final product in products) ...[
                    _ProductListRow(product: product),
                    const Divider(height: 1, color: Color(0xFFD9D9D9)),
                  ],
                  const SizedBox(height: 18),
                  const Text(
                    'listes recentes',
                    style: TextStyle(
                      color: Color(0xFF202020),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final list in _recentLists) ...[
                    _RecentListRow(title: list),
                    const Divider(height: 1, color: Color(0xFFD9D9D9)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action bientot disponible.')),
    );
  }
}

class _ShoppingHeader extends StatelessWidget {
  const _ShoppingHeader({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 10, 0),
      child: Column(
        children: [
          SizedBox(
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_back_rounded, size: 25),
                  ),
                ),
                const Text(
                  'Ma liste de course',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1.5, color: Color(0xFF3C3C3C)),
        ],
      ),
    );
  }
}

class _RecipePagerLabel extends StatelessWidget {
  const _RecipePagerLabel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Produits',
          style: TextStyle(
            color: Color(0xFF202020),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PagerDot(isActive: true),
            SizedBox(width: 6),
            _PagerDot(isActive: false),
          ],
        ),
      ],
    );
  }
}

class _PagerDot extends StatelessWidget {
  const _PagerDot({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF062F1A) : const Color(0xFF8A9A8E),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ImportActions extends StatelessWidget {
  const _ImportActions({required this.onComingSoon});

  final void Function(BuildContext context, String action) onComingSoon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _RoundImportButton(
              icon: Icons.add_rounded,
              onTap: () => onComingSoon(context, 'Ajout manuel'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => onComingSoon(context, 'Photo du ticket'),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD0F16C),
                  foregroundColor: const Color(0xFF062F1A),
                  minimumSize: const Size.fromHeight(34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                label: const Text('Prendre en photo un ticket'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onComingSoon(context, 'Recherche produit'),
                icon: const Icon(Icons.search_rounded, size: 16),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF062F1A),
                  side: const BorderSide(color: Color(0xFF062F1A), width: 1),
                  minimumSize: const Size.fromHeight(31),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                label: const Text('Rechercher un produit'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onComingSoon(context, 'Import photo'),
                icon: const Icon(Icons.image_outlined, size: 16),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF062F1A),
                  side: const BorderSide(color: Color(0xFF062F1A), width: 1),
                  minimumSize: const Size.fromHeight(31),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                label: const Text('Importer une photo'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundImportButton extends StatelessWidget {
  const _RoundImportButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFF062F1A),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 25),
      ),
    );
  }
}

class _ProductListRow extends StatelessWidget {
  const _ProductListRow({required this.product});

  final ShoppingProduct product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.network(
              product.imageUrl,
              width: 27,
              height: 27,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/komi-bowl.png',
                width: 27,
                height: 27,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 14,
                    height: 1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.brand} - x${product.quantity} - Nutri-score ${product.nutriScore}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 8,
                    height: 1,
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

class _RecentListRow extends StatelessWidget {
  const _RecentListRow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 53,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '10 jours - 14 plats',
                  style: TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 8,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFFD0F16C),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFF062F1A),
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}
