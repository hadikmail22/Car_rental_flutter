class UserSession {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? dateOfBirth;
  final String? drivingLicenseNumber;
  final List<String> roles;

  const UserSession({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    this.drivingLicenseNumber,
    required this.roles,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: (json['id'] as num).toInt(),
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      drivingLicenseNumber:
      json['drivingLicenseNumber']?.toString(),
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((role) => role.toString())
          .toList(),
    );
  }

  bool get isAdmin {
    return roles.contains('ROLE_ADMIN');
  }

  bool get isCustomer {
    return roles.contains('ROLE_CUSTOMER');
  }
}