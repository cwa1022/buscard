class CardModel {
  final int? id;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String orientation; // 'horizontal' or 'vertical'
  final String imagePath;

  CardModel({
    this.id,
    required this.name,
    required this.company,
    required this.phone,
    required this.email,
    required this.orientation,
    required this.imagePath,
  });

  factory CardModel.fromMap(Map<String, dynamic> map) => CardModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        company: map['company'] as String,
        phone: map['phone'] as String,
        email: map['email'] as String,
        orientation: map['orientation'] as String,
        imagePath: map['image_path'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'company': company,
        'phone': phone,
        'email': email,
        'orientation': orientation,
        'image_path': imagePath,
      };
}
