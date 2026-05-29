import 'package:flutter/material.dart';

import '../auth/data/auth_models.dart';
import '../auth/data/auth_session_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _sessionStore = const AuthSessionStore();
  KomiUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _sessionStore.readUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  String get _fullName {
    final name = _user?.name.trim();
    if (name == null || name.isEmpty) return 'Mathis';
    return name;
  }

  String get _firstName => _fullName.split(RegExp(r'\s+')).first;

  String get _lastName {
    final parts = _fullName.split(RegExp(r'\s+'));
    if (parts.length < 2) return 'Provost';
    return parts.skip(1).join(' ');
  }

  String get _email {
    final email = _user?.email.trim();
    if (email == null || email.isEmpty) {
      return 'mathis.provost@my-digital-school.org';
    }
    return email;
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
            _ProfileHeader(firstName: _firstName),
            const SizedBox(height: 38),
            const _SectionHeader(title: 'Mes informations'),
            const SizedBox(height: 16),
            _InfoRow(label: 'Prenom :', value: _firstName),
            _InfoRow(label: 'Nom :', value: _lastName),
            _InfoRow(label: 'Adresse mail :', value: _email),
            const _InfoRow(label: 'Age :', value: '22'),
            const _InfoRow(label: 'Sexe :', value: 'H'),
            const _InfoRow(label: 'Regime alimentaire :', value: 'Classique'),
            const _ImageProfileRow(),
            const SizedBox(height: 12),
            _ProfileImageButton(onTap: () {}),
            const SizedBox(height: 38),
            const _SectionHeader(title: 'Mon abonnement'),
            const SizedBox(height: 8),
            const _SubscriptionCards(),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(radius: 23, backgroundColor: Color(0xFF202020)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue $firstName !',
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
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          const Icon(Icons.edit_rounded, color: Color(0xFF202020), size: 13),
        ],
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
  const _SubscriptionCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 258,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _SubscriptionCard(
            title: 'Standard',
            subtitle: 'Pour decouvrir Komi en douceur',
            price: 'Gratuit',
            isSelected: true,
            items: [
              'Scan de tickets de caisse limite',
              'Analyse nutritionnelle basique',
              'Premiers conseils d\'amelioration alimentaire',
              'Acces a une selection de recettes simples',
            ],
            ideal:
                'Les curieux qui veulent tester Komi et commencer a mieux comprendre ce qu\'ils mangent.',
          ),
          SizedBox(width: 10),
          _SubscriptionCard(
            title: 'Premium',
            subtitle: 'Pour une vraie reduction',
            price: '6e par mois',
            isSelected: false,
            items: [
              'Tout le contenu Silver',
              'Analyses nutritionnelles avancees',
              'Recommandations ultra-personnalisees',
              'Suggestions de recettes',
              'Acces prioritaire aux nouveautes',
            ],
            ideal:
                'Celles et ceux qui veulent reprendre le controle de leur alimentation.',
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isSelected,
    required this.items,
    required this.ideal,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool isSelected;
  final List<String> items;
  final String ideal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFF062F1A),
          width: isSelected ? 1.1 : 0.8,
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF202020),
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF202020),
              fontSize: 8,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            price,
            style: const TextStyle(
              color: Color(0xFF062F1A),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFF9A9A9A)),
          const SizedBox(height: 14),
          const Text(
            'Ce qui est inclus :',
            style: TextStyle(
              color: Color(0xFF202020),
              fontSize: 9,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          for (final item in items.take(4))
            Text(
              '- $item',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF202020),
                fontSize: 6.8,
                height: 1.25,
              ),
            ),
          const SizedBox(height: 14),
          const Text(
            'Ideal pour :',
            style: TextStyle(
              color: Color(0xFF202020),
              fontSize: 9,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            ideal,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF202020),
              fontSize: 6.8,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
