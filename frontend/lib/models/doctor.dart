class Doctor {
  final String id;
  final String name;
  final String email;
  final String specialty;
  final String phoneNumber;
  final String address;
  final String? profileImage; // Add this

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.specialty,
    required this.phoneNumber,
    required this.address,
    this.profileImage, // Add this
  });
}
