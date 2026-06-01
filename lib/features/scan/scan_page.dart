import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/shopping_product.dart';
import '../../models/shopping_list_analysis.dart';
import '../../providers/shopping_list_provider.dart';
import '../../services/shopping_list_ocr_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final TextEditingController _manualItemController = TextEditingController();
  final FocusNode _manualItemFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final ShoppingListOcrService _ocrService = ShoppingListOcrService();

  ShoppingListAnalysisResult? _lastAnalysis;
  bool _isAnalyzing = false;
  bool _isValidatingManualItem = false;

  static const List<String> _recentLists = [];

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
            _ShoppingHeader(onBack: widget.onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 104),
                children: [
                  const SizedBox(height: 6),
                  const _RecipePagerLabel(),
                  const SizedBox(height: 18),
                  _ImportActions(
                    controller: _manualItemController,
                    focusNode: _manualItemFocusNode,
                    onSubmitted: _handleManualItemSubmit,
                    onOpenManual: _openManualEntry,
                    onPickCamera: () => _pickAndAnalyze(ImageSource.camera),
                    onPickGallery: () => _pickAndAnalyze(ImageSource.gallery),
                  ),
                  if (_isAnalyzing) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(
                      color: Color(0xFF062F1A),
                      backgroundColor: Color(0xFFE8E8E8),
                    ),
                  ],
                  if (_lastAnalysis != null) ...[
                    const SizedBox(height: 14),
                    _AnalysisSummaryCard(result: _lastAnalysis!),
                  ],
                  const SizedBox(height: 16),
                  if (products.isEmpty)
                    const _EmptyListState()
                  else
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
                  if (_recentLists.isEmpty)
                    const _EmptyRecentListsState()
                  else
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

  @override
  void dispose() {
    _manualItemController.dispose();
    _manualItemFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleManualItemSubmit(BuildContext context) async {
    final query = _manualItemController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final shoppingListProvider = context.read<ShoppingListProvider>();

    if (query.isEmpty || _isValidatingManualItem) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ecris un item a ajouter a la liste.')),
      );
      return;
    }

    setState(() => _isValidatingManualItem = true);
    try {
      final result = await _ocrService.validateItems([query]);
      if (!mounted) return;
      setState(() {
        _lastAnalysis = result;
        _isValidatingManualItem = false;
      });

      if (result.items.isEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text('"$query" ignore : ce n est pas un aliment.')),
        );
        return;
      }

      final added =
          shoppingListProvider.addManualProduct(result.items.first.name);
      if (!added) return;

      _manualItemController.clear();
      _manualItemFocusNode.unfocus();
      messenger.showSnackBar(
        SnackBar(
            content: Text('"${result.items.first.name}" ajoute a la liste.')),
      );
    } on ShoppingListOcrException catch (error) {
      if (!mounted) return;
      setState(() => _isValidatingManualItem = false);
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  void _openManualEntry(BuildContext context) {
    _manualItemFocusNode.requestFocus();
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    if (_isAnalyzing) return;
    final shoppingListProvider = context.read<ShoppingListProvider>();

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2200,
      );
      if (file == null) return;

      setState(() => _isAnalyzing = true);
      final bytes = await file.readAsBytes();
      final result = await _ocrService.analyzeImage(
        bytes: bytes,
        filename: file.name,
        source: source == ImageSource.camera ? 'camera' : 'gallery',
      );

      final addedCount = shoppingListProvider.addRecognizedProducts(
        result.items.map((item) => item.name),
      );

      if (!mounted) return;
      setState(() {
        _lastAnalysis = result;
        _isAnalyzing = false;
      });

      final extractedCount = result.items.length;
      final rejectedCount = result.rejectedItems.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$extractedCount aliment${extractedCount > 1 ? 's' : ''} ajoute${addedCount > 1 ? 's' : ''}, $rejectedCount ignore${rejectedCount > 1 ? 's' : ''}.',
          ),
        ),
      );
    } on ShoppingListOcrException catch (error) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d ouvrir ou d analyser cette image.'),
        ),
      );
    }
  }
}

class _EmptyListState extends StatelessWidget {
  const _EmptyListState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Aucun item pour le moment. Prends une photo de ta liste, importe une image ou ajoute un item manuellement.',
        style: TextStyle(
          color: Color(0xFF4A4A4A),
          fontSize: 12,
          height: 1.25,
        ),
      ),
    );
  }
}

class _EmptyRecentListsState extends StatelessWidget {
  const _EmptyRecentListsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Aucune liste recente pour ce compte.',
        style: TextStyle(
          color: Color(0xFF6B6B6B),
          fontSize: 12,
        ),
      ),
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
          'Items de la liste',
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
  const _ImportActions({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onOpenManual,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(BuildContext context) onSubmitted;
  final void Function(BuildContext context) onOpenManual;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _RoundImportButton(
              icon: Icons.edit_note_rounded,
              onTap: () => onOpenManual(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onPickCamera,
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
                label: const Text('Prendre en photo la liste'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onSubmitted(context),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Ecrire un item de ma liste',
            hintStyle: const TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: IconButton(
              onPressed: () => onSubmitted(context),
              icon: const Icon(
                Icons.add_circle_rounded,
                color: Color(0xFF062F1A),
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF3F3F3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(
            color: Color(0xFF202020),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => onOpenManual(context),
                icon: const Icon(Icons.keyboard_alt_outlined, size: 16),
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
                label: const Text('Ajouter manuellement'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickGallery,
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
                label: const Text('Importer la liste'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'On recupere automatiquement l item saisi pour l ajouter a la liste.',
            style: TextStyle(
              color: Color(0xFF5C5C5C),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalysisSummaryCard extends StatelessWidget {
  const _AnalysisSummaryCard({required this.result});

  final ShoppingListAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final previewItems = result.items.take(4).toList();
    final hasAcceptedItems = result.items.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E5C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.source == 'camera'
                ? 'Derniere analyse photo'
                : 'Derniere analyse galerie',
            style: const TextStyle(
              color: Color(0xFF202020),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasAcceptedItems
                ? '${result.items.length} aliment${result.items.length > 1 ? 's' : ''} garde${result.items.length > 1 ? 's' : ''} - ${result.rejectedItems.length} ignore${result.rejectedItems.length > 1 ? 's' : ''}'
                : 'Aucun aliment reconnu automatiquement',
            style: const TextStyle(
              color: Color(0xFF4C4C4C),
              fontSize: 11,
            ),
          ),
          if (!hasAcceptedItems) ...[
            const SizedBox(height: 8),
            const Text(
              'La photo semble trop difficile a lire. Essaie une photo plus droite et plus proche, ou ajoute les items manuellement.',
              style: TextStyle(
                color: Color(0xFF8A4B3A),
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
          if (previewItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final item in previewItems)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (hasAcceptedItems && result.rejectedItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ignore : ${result.rejectedItems.map((item) => item.name).take(4).join(', ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8A4B3A),
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
          if (hasAcceptedItems && result.rawText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              result.rawText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF707070),
                fontSize: 10,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
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
                  '${product.brand} - x${product.quantity} - item valide',
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
