class CustomerInfo {
  final int id;
  final String name;
  final String avatarUrl;
  final String phoneNumber;
  final String token;

  CustomerInfo(
      this.id, this.avatarUrl, this.name, this.phoneNumber, this.token);

  Map<String, dynamic> toJson() {
    return {
      'Customer': {
        'id': id,
        'avatarUrl': avatarUrl,
        'name': name,
        'phoneNumber': phoneNumber,
      },
    };
  }
}
