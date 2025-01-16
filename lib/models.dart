class Language {
  final String language;
  final List<Translation> translations;

  Language({required this.language, required this.translations});

  factory Language.fromJson(Map<String, dynamic> json) {
    String originalLanguage = json['language'];
    String firstPart = originalLanguage.split(' ').first;
    String formattedLanguage = firstPart[0].toUpperCase() + firstPart.substring(1);

    return Language(
      language: formattedLanguage, 
      translations: (json['translations'] as List)
          .map((i) => Translation.fromJson(i))
          .toList(),
    );
  }

}

class Translation {
  final String shortName;
  final String fullName;

  Translation({required this.shortName, required this.fullName});

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      shortName: json['short_name'],
      fullName: json['full_name'],
    );
  }
}

class Book {
  final int bookId;
  final String name;
  final int chapters;

  Book({required this.bookId, required this.name, required this.chapters});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookId: json['bookid'],
      name: json['name'],
      chapters: json['chapters'],
    );
  }
}

class Verse {
  final int pk;
  final int verse;
  final String text;

  Verse({required this.pk, required this.verse, required this.text});

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      pk: json['pk'],
      verse: json['verse'],
      text: json['text'],
    );
  }
}