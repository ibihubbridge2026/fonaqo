class OpportunityModel {
  final String id;
  final String title;
  final String category;
  final String location;
  final String price;
  final double rating;
  final String imageUrl;
  final bool isOpen;
  final bool isUrgent;

  OpportunityModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.isOpen = true,
    this.isUrgent = false,
  });

  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    return OpportunityModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Sans titre',
      category: json['category'] ?? 'Général',
      location: json['location'] ?? 'Inconnu',
      price: json['price'] ?? '0 FCFA',
      rating: (json['rating'] ?? 4.5).toDouble(),
      imageUrl: json['image_url'] ?? '',
      isOpen: json['is_open'] ?? true,
      isUrgent: json['is_urgent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'location': location,
      'price': price,
      'rating': rating,
      'image_url': imageUrl,
      'is_open': isOpen,
      'is_urgent': isUrgent,
    };
  }
}
