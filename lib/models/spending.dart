import 'dart:convert';

class Spending {
  String? id;
  int money;
  int type;
  String? note;
  DateTime dateTime;
  String? image;
  String? typeName;
  String? location;
  List<String>? friends;

  Spending({
    this.id,
    required this.money,
    required this.type,
    required this.dateTime,
    this.note,
    this.image,
    this.typeName,
    this.location,
    this.friends,
  });

  Map<String, dynamic> toMap() => {
        "money": money,
        "type": type,
        "note": note,
        "date": dateTime.millisecondsSinceEpoch,
        "image": image,
        "typeName": typeName,
        "location": location,
        "friends": friends == null ? null : jsonEncode(friends),
      };

  factory Spending.fromDb(Map<String, dynamic> data) {
    return Spending(
      id: data["id"].toString(),
      money: data["money"] as int,
      type: data["type"] as int,
      dateTime: DateTime.fromMillisecondsSinceEpoch(data["date"] as int),
      note: data["note"] as String?,
      image: data["image"] as String?,
      typeName: data["typeName"] as String?,
      location: data["location"] as String?,
      friends: data["friends"] == null
          ? []
          : List<String>.from(jsonDecode(data["friends"] as String)),
    );
  }

  Spending copyWith({
    int? money,
    int? type,
    DateTime? dateTime,
    String? note,
    String? image,
    String? typeName,
    String? location,
    List<String>? friends,
  }) {
    return Spending(
      id: id,
      money: money ?? this.money,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      image: image ?? this.image,
      typeName: typeName ?? this.typeName,
      location: location ?? this.location,
      friends: friends ?? this.friends,
    );
  }
}
