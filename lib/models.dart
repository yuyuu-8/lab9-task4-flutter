/// Доменная модель трека. Хранится в Hive как Map (без кодогенерации адаптеров).
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.favorite = false,
  });

  final String id;
  final String title;
  final String artist;
  final bool favorite;

  Track copyWith({String? title, String? artist, bool? favorite}) => Track(
        id: id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        favorite: favorite ?? this.favorite,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'favorite': favorite,
      };

  factory Track.fromMap(Map<String, dynamic> map) => Track(
        id: map['id'] as String,
        title: (map['title'] as String?) ?? '',
        artist: (map['artist'] as String?) ?? '',
        favorite: (map['favorite'] as bool?) ?? false,
      );
}
