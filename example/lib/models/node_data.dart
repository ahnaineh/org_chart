class NodeData {
  final String id;
  String text;
  String? parentId;

  NodeData._({
    required this.id,
    required this.text,
    String? parentId,
  }) : parentId = parentId;

  factory NodeData({
    required String id,
    required String text,
    String? parentId,
  }) {
    if (parentId == id) {
      throw ArgumentError('A node cannot be its own parent');
    }
    return NodeData._(id: id, text: text, parentId: parentId);
  }

  NodeData copyWith({
    String? id,
    String? text,
    String? parentId,
  }) {
    return NodeData(
      id: id ?? this.id,
      text: text ?? this.text,
      parentId: parentId ?? this.parentId,
    );
  }

  NodeData withParent(String? newParentId) {
    if (newParentId == id) return this;
    return copyWith(parentId: newParentId);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'to': parentId,
      };

  factory NodeData.fromMap(Map<String, dynamic> map) => NodeData(
        id: map['id'] as String,
        text: map['text'] as String,
        parentId: map['to'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeData && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'NodeData(id: $id, text: $text, parentId: $parentId)';
}
