import 'property_status.dart';

class Property {
  const Property({
    required this.id,
    required this.title,
    required this.address,
    required this.description,
    required this.price,
    required this.status,
    this.isUserAdded = false,
  });

  final String id;
  final String title;
  final String address;
  final String description;
  final double price;
  final PropertyStatus status;
  final bool isUserAdded;

  Property copyWith({
    String? id,
    String? title,
    String? address,
    String? description,
    double? price,
    PropertyStatus? status,
    bool? isUserAdded,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      description: description ?? this.description,
      price: price ?? this.price,
      status: status ?? this.status,
      isUserAdded: isUserAdded ?? this.isUserAdded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'description': description,
      'price': price,
      'status': status.name,
      'isUserAdded': isUserAdded,
    };
  }

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      title: json['title'] as String,
      address: json['address'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      status: propertyStatusFromString(json['status'] as String? ?? 'forSale'),
      isUserAdded: json['isUserAdded'] as bool? ?? false,
    );
  }
}
