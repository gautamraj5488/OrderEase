class UserProfile {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String uid;
  final String profilePic; // Add this field
  final String email;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.uid,
    required this.profilePic,
    required this.email,// Initialize this in the constructor
  });

}