/// Predefined interest for discovery and profile display.
/// Stored in Firestore as config/interests or interests collection.
class Interest {
  final String id;
  final String label;
  final int order;

  const Interest({required this.id, required this.label, this.order = 0});

  Map<String, dynamic> toMap() => {'id': id, 'label': label, 'order': order};

  static Interest fromMap(Map<String, dynamic> map) => Interest(
        id: map['id'] as String? ?? '',
        label: map['label'] as String? ?? '',
        order: (map['order'] as num?)?.toInt() ?? 0,
      );
}
