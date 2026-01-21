enum ServiceCategory { grooming, vet, training, boarding }

class Service {
  final String id;
  final ServiceCategory category;
  final String name;
  final String description;
  final String durationText;
  final double price;

  const Service({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.durationText,
    required this.price,
  });
}
