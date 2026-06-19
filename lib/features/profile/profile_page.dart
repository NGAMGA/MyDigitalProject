import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/data/auth_models.dart';
import '../auth/data/auth_session_store.dart';
import '../auth/auth_choice_page.dart';
import '../../providers/user_session_provider.dart';
import '../../services/profile_service.dart';
import '../../services/subscription_payment_service.dart';
import '../../widgets/profile_avatar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _sessionStore = const AuthSessionStore();
  final _paymentService = SubscriptionPaymentService();
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();
  KomiUser? _user;
  bool _isStartingCheckout = false;
  bool _isManagingSubscription = false;
  bool _isSavingProfile = false;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    KomiUser? user;
    try {
      user = await _profileService.getMe();
      if (mounted) {
        await context.read<UserSessionProvider>().setUser(user);
      }
    } catch (_) {
      user = await _sessionStore.readUser();
    }
    if (!mounted) return;
    setState(() => _user = user);
  }

  String get _fullName {
    final profileName = [
      _user?.profile.firstName.trim() ?? '',
      _user?.profile.lastName.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(' ');
    if (profileName.isNotEmpty) return profileName;
    return _user?.name.trim() ?? '';
  }

  String get _firstName {
    final firstName = _user?.profile.firstName.trim();
    if (firstName != null && firstName.isNotEmpty) return firstName;
    if (_fullName.isEmpty) return '';
    return _fullName.split(RegExp(r'\s+')).first;
  }

  String get _lastName {
    final lastName = _user?.profile.lastName.trim();
    if (lastName != null && lastName.isNotEmpty) return lastName;
    final parts = _fullName.split(RegExp(r'\s+'));
    if (parts.length < 2) return '';
    return parts.skip(1).join(' ');
  }

  String get _email {
    final email = _user?.email.trim();
    if (email == null || email.isEmpty) return '';
    return email;
  }

  String _orMissing(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Non renseigne' : trimmed;
  }

  Future<void> _startPremiumCheckout() async {
    if (_isStartingCheckout) return;

    setState(() => _isStartingCheckout = true);
    try {
      final checkoutUrl = await _paymentService.createPremiumCheckoutSession();
      if (!mounted) return;

      final launched = await launchUrl(
        checkoutUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showMessage('Impossible d ouvrir la page Stripe.');
      }
    } on SubscriptionPaymentException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isStartingCheckout = false);
    }
  }

  Future<void> _cancelPremiumSubscription() async {
    if (_isManagingSubscription) return;
    final subscription = _user?.subscription;
    final isTrial = subscription?.status.toLowerCase() == 'essai gratuit';
    final endDate = _formatSubscriptionDate(
      isTrial ? subscription?.trialEnd : subscription?.renewal,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.event_busy_rounded, color: Color(0xFF9A3412)),
        title: const Text('Résilier Premium ?'),
        content: Text(
          isTrial
              ? 'Ton essai restera actif jusqu’au $endDate. Tu ne seras pas débité à cette date.'
              : 'Ton accès Premium restera actif jusqu’au $endDate, puis repassera automatiquement à Standard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Garder Premium'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF9A3412),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer la résiliation'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isManagingSubscription = true);
    try {
      await _paymentService.cancelPremiumSubscription();
      await _loadUser();
      if (mounted) {
        _showMessage(
          'Résiliation programmée. Aucun autre débit ne sera effectué.',
        );
      }
    } on SubscriptionPaymentException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isManagingSubscription = false);
    }
  }

  Future<void> _resumePremiumSubscription() async {
    if (_isManagingSubscription) return;
    setState(() => _isManagingSubscription = true);
    try {
      await _paymentService.resumePremiumSubscription();
      await _loadUser();
      if (mounted) _showMessage('Ton abonnement Premium continue normalement.');
    } on SubscriptionPaymentException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isManagingSubscription = false);
    }
  }

  String _formatSubscriptionDate(String? rawDate) {
    final parsed = DateTime.tryParse(rawDate ?? '');
    if (parsed == null) return 'la date de fin indiquée';
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Future<void> _editTextField({
    required String title,
    required String fieldKey,
    required String initialValue,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    if (_isSavingProfile) return;

    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _EditProfileFieldSheet(
        title: title,
        initialValue: initialValue,
        keyboardType: keyboardType,
      ),
    );

    if (value == null || value == initialValue.trim()) return;
    if (fieldKey == 'email' && value.isEmpty) {
      _showMessage('L adresse mail ne peut pas etre vide.');
      return;
    }

    await _updateProfile({fieldKey: value.isEmpty ? null : value});
  }

  Future<void> _editBirthDate() async {
    if (_isSavingProfile) return;

    final current = DateTime.tryParse(_user?.profile.dateOfBirth ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF062F1A),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    final value =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    await _updateProfile({'dateOfBirth': value});
  }

  Future<void> _editProfileImage() async {
    if (_isSavingProfile) return;

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 600,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    await _updateProfile({'avatarDataUrl': dataUrl});
  }

  Future<void> _updateProfile(Map<String, dynamic> fields) async {
    setState(() => _isSavingProfile = true);
    try {
      final user = await _profileService.updateMe(fields);
      if (!mounted) return;
      await context.read<UserSessionProvider>().setUser(user);
      if (!mounted) return;
      setState(() => _user = user);
      _showMessage('Profil mis a jour.');
    } on ProfileServiceException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se deconnecter ?'),
        content: const Text(
          'Tu devras te reconnecter pour acceder a ton compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Se deconnecter'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);
    await context.read<UserSessionProvider>().clear();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthChoicePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 104),
          children: [
            _ProfileHeader(
              firstName: _firstName,
              avatarDataUrl: _user?.profile.avatarDataUrl ?? '',
            ),
            const SizedBox(height: 38),
            const _SectionHeader(title: 'Mes informations'),
            const SizedBox(height: 16),
            if (_isSavingProfile) const LinearProgressIndicator(minHeight: 2),
            if (_isSavingProfile) const SizedBox(height: 12),
            _InfoRow(
              label: 'Prenom :',
              value: _orMissing(_firstName),
              onTap: () => _editTextField(
                title: 'Modifier le prenom',
                fieldKey: 'firstName',
                initialValue: _firstName,
              ),
            ),
            _InfoRow(
              label: 'Nom :',
              value: _orMissing(_lastName),
              onTap: () => _editTextField(
                title: 'Modifier le nom',
                fieldKey: 'lastName',
                initialValue: _lastName,
              ),
            ),
            _InfoRow(
              label: 'Adresse mail :',
              value: _orMissing(_email),
              onTap: () => _editTextField(
                title: 'Modifier l adresse mail',
                fieldKey: 'email',
                initialValue: _email,
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            _InfoRow(
              label: 'Date de naissance :',
              value: _orMissing(_user?.profile.dateOfBirth ?? ''),
              onTap: _editBirthDate,
            ),
            _InfoRow(
              label: 'Telephone :',
              value: _orMissing(_user?.profile.phoneNumber ?? ''),
              onTap: () => _editTextField(
                title: 'Modifier le telephone',
                fieldKey: 'phoneNumber',
                initialValue: _user?.profile.phoneNumber ?? '',
                keyboardType: TextInputType.phone,
              ),
            ),
            _InfoRow(
              label: 'Pays :',
              value: _orMissing(_user?.profile.country ?? ''),
              onTap: () => _editTextField(
                title: 'Modifier le pays',
                fieldKey: 'country',
                initialValue: _user?.profile.country ?? '',
              ),
            ),
            const _ImageProfileRow(),
            const SizedBox(height: 12),
            _ProfileImageButton(onTap: _editProfileImage),
            const SizedBox(height: 38),
            const _SectionHeader(title: 'Mon abonnement'),
            const SizedBox(height: 8),
            _SubscriptionCards(
              subscription: _user?.subscription,
              isStartingCheckout: _isStartingCheckout,
              isManagingSubscription: _isManagingSubscription,
              onPremiumPressed: _startPremiumCheckout,
              onCancelPressed: _cancelPremiumSubscription,
              onResumePressed: _resumePremiumSubscription,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isSigningOut ? null : _signOut,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(
                  _isSigningOut ? 'Deconnexion...' : 'Se deconnecter',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB3261E),
                  side: const BorderSide(color: Color(0xFFB3261E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.firstName,
    required this.avatarDataUrl,
  });

  final String firstName;
  final String avatarDataUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileAvatar(
          avatarDataUrl: avatarDataUrl,
          radius: 23,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                firstName.isEmpty ? 'Bienvenue !' : 'Bienvenue $firstName !',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sur cette page, gerez les informations de\nvotre compte et votre abonnement.',
                style: TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditProfileFieldSheet extends StatefulWidget {
  const _EditProfileFieldSheet({
    required this.title,
    required this.initialValue,
    required this.keyboardType,
  });

  final String title;
  final String initialValue;
  final TextInputType keyboardType;

  @override
  State<_EditProfileFieldSheet> createState() => _EditProfileFieldSheetState();
}

class _EditProfileFieldSheetState extends State<_EditProfileFieldSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFF202020),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            cursorColor: const Color(0xFF062F1A),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(
                _controller.text.trim(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF062F1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF202020),
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.keyboard_arrow_up_rounded, size: 17),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 2),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              const Icon(
                Icons.edit_rounded,
                color: Color(0xFF202020),
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageProfileRow extends StatelessWidget {
  const _ImageProfileRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        'Image de profil :',
        style: TextStyle(
          color: Color(0xFF202020),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _ProfileImageButton extends StatelessWidget {
  const _ProfileImageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
      label: const Text('Modifier image de profil'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFEFEFEF),
        foregroundColor: const Color(0xFF202020),
        minimumSize: const Size.fromHeight(39),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SubscriptionCards extends StatelessWidget {
  const _SubscriptionCards({
    required this.subscription,
    required this.isStartingCheckout,
    required this.isManagingSubscription,
    required this.onPremiumPressed,
    required this.onCancelPressed,
    required this.onResumePressed,
  });

  final SubscriptionInfo? subscription;
  final bool isStartingCheckout;
  final bool isManagingSubscription;
  final VoidCallback onPremiumPressed;
  final VoidCallback onCancelPressed;
  final VoidCallback onResumePressed;

  @override
  Widget build(BuildContext context) {
    final plan = subscription?.plan.trim() ?? '';
    final status = subscription?.status.trim() ?? '';
    final normalizedPlan = plan.toLowerCase();
    final isPremium = normalizedPlan == 'premium';
    final isTrial = status.toLowerCase() == 'essai gratuit';
    final cancellationScheduled = subscription?.cancelAtPeriodEnd ?? false;
    final endDate = _readableDate(
      isTrial ? subscription?.trialEnd : subscription?.renewal,
    );

    return Column(
      children: [
        if (isPremium) ...[
          _SubscriptionStatusBanner(
            icon: cancellationScheduled
                ? Icons.event_busy_rounded
                : isTrial
                    ? Icons.auto_awesome_rounded
                    : Icons.verified_rounded,
            title: cancellationScheduled
                ? 'Résiliation programmée'
                : isTrial
                    ? 'Essai Premium en cours'
                    : 'Premium actif',
            message: cancellationScheduled
                ? 'Ton accès reste actif jusqu’au $endDate. Tu ne seras pas débité ensuite.'
                : isTrial
                    ? 'Profite de toutes les fonctionnalités. Premier débit de 6 € le $endDate, sauf résiliation avant cette date.'
                    : 'Prochain renouvellement de 6 € prévu le $endDate.',
            warning: cancellationScheduled,
          ),
          const SizedBox(height: 12),
        ],
        _PlanCard(
          title: 'Standard',
          subtitle: 'Version actuelle incluse par defaut',
          price: 'Inclus',
          status:
              isPremium ? 'Disponible' : (status.isEmpty ? 'Actif' : status),
          isCurrent: !isPremium,
          features: const [
            'Compte Komi',
            'Une liste persistante',
            'Ajout manuel et photo',
            'Bilan de base',
            '3 suggestions personnalisees',
          ],
          actionLabel: !isPremium ? 'Actuel' : null,
        ),
        const SizedBox(height: 12),
        _PlanCard(
          title: 'Premium',
          subtitle: '7 jours gratuits, puis 6 € par mois',
          price: isTrial ? 'Essai gratuit' : '6 € par mois',
          status: isPremium ? (status.isEmpty ? 'Actif' : status) : 'Option',
          isCurrent: isPremium,
          features: const [
            'Plusieurs listes',
            'Historique complet',
            'Analyse de 5 ingredients',
            '6 suggestions personnalisees',
          ],
          actionLabel: isPremium ? 'Actuel' : 'Essayer gratuitement',
          isLoading: isStartingCheckout,
          onPressed: isPremium ? null : onPremiumPressed,
        ),
        if (isPremium && (subscription?.stripeManaged ?? false)) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: cancellationScheduled
                ? OutlinedButton.icon(
                    onPressed: isManagingSubscription ? null : onResumePressed,
                    icon: isManagingSubscription
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restart_alt_rounded),
                    label: const Text('Continuer mon abonnement'),
                  )
                : TextButton(
                    onPressed: isManagingSubscription ? null : onCancelPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF9A3412),
                    ),
                    child: const Text('Résilier mon abonnement'),
                  ),
          ),
        ],
      ],
    );
  }

  static String _readableDate(String? rawDate) {
    final parsed = DateTime.tryParse(rawDate ?? '');
    if (parsed == null) return 'la date indiquée';
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

class _SubscriptionStatusBanner extends StatelessWidget {
  const _SubscriptionStatusBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.warning,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFF9A3412) : const Color(0xFF176B3A);
    final background =
        warning ? const Color(0xFFFFF7ED) : const Color(0xFFF0F8EC);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 12,
                    height: 1.35,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.status,
    required this.isCurrent,
    required this.features,
    this.actionLabel,
    this.isLoading = false,
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String price;
  final String status;
  final bool isCurrent;
  final List<String> features;
  final String? actionLabel;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onPressed != null && !isLoading;
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFF5F9EE) : Colors.white,
        border: Border.all(
          color: const Color(0xFF062F1A),
          width: isCurrent ? 1.2 : 0.9,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0F16C),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Actuel',
                    style: TextStyle(
                      color: Color(0xFF062F1A),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF202020),
              fontSize: 10,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFF062F1A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: const TextStyle(
              color: Color(0xFF5A5A5A),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFCDCDCD)),
          const SizedBox(height: 12),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF062F1A),
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      feature,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF202020),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (actionLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: isInteractive ? onPressed : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: isCurrent
                        ? const Color(0xFFE4E4E4)
                        : const Color(0xFF062F1A),
                    foregroundColor:
                        isCurrent ? const Color(0xFF202020) : Colors.white,
                    disabledBackgroundColor: const Color(0xFFE4E4E4),
                    disabledForegroundColor: const Color(0xFF202020),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(actionLabel!),
                ),
              ),
            ),
        ],
      ),
    );

    if (!isInteractive) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}
