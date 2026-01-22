const defaultAvatar = "assets/images/male.png";

class User {
  String name;
  String birthday;
  String avatar;
  bool gender;
  int money;

  User(
      {required this.name,
      required this.birthday,
      required this.avatar,
      required this.money,
      this.gender = true});

  Map<String, dynamic> toMap() => {
        "name": name,
        "birthday": birthday,
        "avatar": avatar,
        "gender": gender ? 1 : 0,
        "money": money
      };

  factory User.fromDb(Map<String, dynamic> data) {
    return User(
      name: data["name"] as String,
      birthday: data["birthday"] as String,
      avatar: data["avatar"] as String,
      money: data["money"] as int,
      gender: (data['gender'] as int) == 1,
    );
  }

  User copyWith(
      {String? name,
      String? birthday,
      String? avatar,
      bool? gender,
      int? money}) {
    return User(
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      avatar: avatar ?? defaultAvatar,
      money: money ?? this.money,
      gender: gender ?? this.gender,
    );
  }
}
