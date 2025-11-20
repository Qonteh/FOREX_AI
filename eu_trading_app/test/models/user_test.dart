const userJson = '{"id":1,"name":"John Doe","email":"john.doe@example.com"}';

class User {
  final int id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

test('User fromJson creates a User object', () {
  final user = User.fromJson(jsonDecode(userJson));
  expect(user.id, 1);
  expect(user.name, 'John Doe');
  expect(user.email, 'john.doe@example.com');
});