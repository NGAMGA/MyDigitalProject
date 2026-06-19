class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.country,
    required this.bio,
    required this.avatarDataUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      country: json['country'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarDataUrl: json['avatarDataUrl'] as String? ?? '',
    );
  }

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String dateOfBirth;
  final String country;
  final String bio;
  final String avatarDataUrl;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth,
        'country': country,
        'bio': bio,
        'avatarDataUrl': avatarDataUrl,
      };
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.plan,
    required this.status,
    required this.renewal,
    this.trialEnd = '-',
    this.cancelAtPeriodEnd = false,
    this.stripeManaged = false,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: json['plan'] as String? ?? 'Free',
      status: json['status'] as String? ?? '-',
      renewal: json['renewal'] as String? ?? '-',
      trialEnd: json['trialEnd'] as String? ?? '-',
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool? ?? false,
      stripeManaged: json['stripeManaged'] as bool? ?? false,
    );
  }

  final String plan;
  final String status;
  final String renewal;
  final String trialEnd;
  final bool cancelAtPeriodEnd;
  final bool stripeManaged;

  Map<String, dynamic> toJson() => {
        'plan': plan,
        'status': status,
        'renewal': renewal,
        'trialEnd': trialEnd,
        'cancelAtPeriodEnd': cancelAtPeriodEnd,
        'stripeManaged': stripeManaged,
      };
}

class KomiUser {
  const KomiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    required this.profile,
    required this.subscription,
    required this.invoicesCount,
  });

  factory KomiUser.fromJson(Map<String, dynamic> json) {
    return KomiUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      profile: UserProfile.fromJson(
        json['profile'] as Map<String, dynamic>? ?? const {},
      ),
      subscription: SubscriptionInfo.fromJson(
        json['subscription'] as Map<String, dynamic>? ?? const {},
      ),
      invoicesCount: json['invoicesCount'] as int? ?? 0,
    );
  }

  final String id;
  final String name;
  final String email;
  final String createdAt;
  final UserProfile profile;
  final SubscriptionInfo subscription;
  final int invoicesCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'createdAt': createdAt,
        'profile': profile.toJson(),
        'subscription': subscription.toJson(),
        'invoicesCount': invoicesCount,
      };
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'] as String? ?? '',
      user:
          KomiUser.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
    );
  }

  final String accessToken;
  final KomiUser user;

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'user': user.toJson(),
      };
}
