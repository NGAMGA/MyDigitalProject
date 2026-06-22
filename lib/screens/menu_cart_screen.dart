import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/shopping_list_provider.dart';
import '../services/menu_cart_service.dart';
import 'meal_detail_screen.dart';

class MenuCartScreen extends StatefulWidget {
  const MenuCartScreen({super.key});

  @override
  State<MenuCartScreen> createState() => _MenuCartScreenState();
}

class _MenuCartScreenState extends State<MenuCartScreen> {
  final _service = MenuCartService();
  List<MenuCartItem> _items = const [];
  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.getCart();
      if (!mounted) return;
      setState(() => _items = items);
    } on MenuCartException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _remove(MenuCartItem item) async {
    try {
      await _service.removeMeal(item.mealId);
      if (!mounted) return;
      setState(() {
        _items = _items
            .where((candidate) => candidate.mealId != item.mealId)
            .toList();
      });
      _showMessage('${item.mealName} retire du panier.');
    } on MenuCartException catch (error) {
      if (mounted) _showMessage(error.message);
    }
  }

  Future<void> _generate() async {
    if (_isGenerating || _items.isEmpty) return;
    setState(() => _isGenerating = true);
    try {
      final generated = await _service.generateShoppingList();
      if (!mounted) return;
      final provider = context.read<ShoppingListProvider>();
      final added = provider.addRecognizedProducts(
        generated.ingredients.map((ingredient) => ingredient.name),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2E7D52),
          ),
          title: const Text('Liste de courses generee'),
          content: Text(
            '$added ingredient${added > 1 ? 's' : ''} ajoute'
            '${added > 1 ? 's' : ''} depuis '
            '${generated.recipeCount} recette'
            '${generated.recipeCount > 1 ? 's' : ''}.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Terminer'),
            ),
          ],
        ),
      );
    } on MenuCartException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Panier de recettes'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(),
      bottomNavigationBar: _items.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: _isGenerating ? null : _generate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.playlist_add_check_rounded),
                label: Text(
                  _isGenerating
                      ? 'Generation...'
                      : 'Generer ma liste de courses',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFF062F1A),
                  foregroundColor: const Color(0xFFDDF577),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 58,
                color: Color(0xFF6E756F),
              ),
              SizedBox(height: 14),
              Text(
                'Ton panier est vide',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Ajoute des recettes pour generer automatiquement '
                'ta liste de courses.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            elevation: 0,
            color: const Color(0xFFF4F8F4),
            child: ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MealDetailScreen(
                    mealId: item.mealId,
                    mealName: item.mealName,
                  ),
                ),
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: item.mealThumb.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE5EFE5),
                          child: Icon(Icons.restaurant_rounded),
                        )
                      : CachedNetworkImage(
                          imageUrl: item.mealThumb,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              title: Text(
                item.mealName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: IconButton(
                tooltip: 'Retirer du panier',
                onPressed: () => _remove(item),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFB3261E),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
