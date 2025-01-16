import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';

class PickerWidget extends StatefulWidget {
  final ValueChanged<String> onTextChanged;

  const PickerWidget({super.key, required this.onTextChanged});

  @override
  State<PickerWidget> createState() => _PickerWidgetState();
}

class _PickerWidgetState extends State<PickerWidget> {
  final ApiService apiService = ApiService();

  List<Language> languages = [];
  List<Translation> currentTranslations = [];
  List<Book> books = [];
  List<int> chapterNumbers = [];
  List<Verse> verses = [];
  List<int> verseNumbers = [];

  String? selectedLanguage;
  String? selectedTranslation;
  String? selectedBook;
  int? selectedChapter;
  int? selectedVerseStart;
  int? selectedVerseEnd;
  Book? currentBook;

  bool isLoadingLanguages = true;
  bool isLoadingBooks = false;
  bool isLoadingVerses = false;

  int currentPickerIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchLanguages();
  }

  Future<void> fetchLanguages() async {
    setState(() {
      isLoadingLanguages = true;
    });
    try {
      final fetchedLanguages = await apiService.fetchLanguages();
      setState(() {
        languages = fetchedLanguages;
        if (languages.isNotEmpty) {
          selectedLanguage = languages.first.language;
          currentTranslations = languages.first.translations;
          selectedTranslation = currentTranslations.isNotEmpty ? currentTranslations.first.shortName : null;
        }
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoadingLanguages = false;
      });
    }
  }

  Future<void> fetchBooks() async {
    if (selectedTranslation == null) return;
    
    setState(() {
      isLoadingBooks = true;
    });
    try {
      final fetchedBooks = await apiService.fetchBooks(selectedTranslation!);
      setState(() {
        books = fetchedBooks;
        if (books.isNotEmpty) {
          selectedBook = books.first.name;
          currentBook = books.first;
          chapterNumbers = List.generate(currentBook!.chapters, (i) => i + 1);
          selectedChapter = chapterNumbers.isNotEmpty ? chapterNumbers.first : null;
        }
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoadingBooks = false;
      });
    }
  }

  Future<void> fetchVerses() async {
    if (selectedTranslation == null || currentBook == null || selectedChapter == null) return;
    
    setState(() {
      isLoadingVerses = true;
    });
    try {
      final fetchedVerses = await apiService.fetchChapterText(
        selectedTranslation!,
        currentBook!.bookId.toString(),
        selectedChapter.toString()
      );
      setState(() {
        verses = fetchedVerses;
        verseNumbers = verses.map((v) => v.verse).toList();
        if (verseNumbers.isNotEmpty) {
          selectedVerseStart = verseNumbers.first;
          selectedVerseEnd = verseNumbers.first;
        }
      });
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoadingVerses = false;
      });
    }
  }

  void onLanguageSelected(String language) {
    setState(() {
      selectedLanguage = language;
      var selectedLang = languages.firstWhere((l) => l.language == language);
      currentTranslations = selectedLang.translations;
      selectedTranslation = currentTranslations.isNotEmpty ? currentTranslations.first.shortName : null;
    });
  }

  void onTranslationSelected(String translation) {
    setState(() {
      selectedTranslation = translation;
    });
  }

  void onBookSelected(String book) {
    setState(() {
      selectedBook = book;
      currentBook = books.firstWhere((b) => b.name == book);
      chapterNumbers = List.generate(currentBook!.chapters, (i) => i + 1);
      selectedChapter = chapterNumbers.isNotEmpty ? chapterNumbers.first : null;
    });
  }

  void onChapterSelected(int chapter) {
    setState(() {
      selectedChapter = chapter;
    });
  }

  void onVerseStartSelected(int verse) {
    setState(() {
      selectedVerseStart = verse;
      if (selectedVerseEnd! < verse) {
        selectedVerseEnd = verse;
      }
    });
  }

  void onVerseEndSelected(int verse) {
    setState(() {
      selectedVerseEnd = verse;
      widget.onTextChanged(getVersesWithText(verses, selectedVerseStart, selectedVerseEnd) ?? '');
    });
  }

  String? getVersesWithText(List<Verse> verses, int? startIndex, int? endIndex) {
    if (startIndex == null || endIndex == null) return null;
    startIndex--;
    endIndex--;

    if (startIndex < 0 || endIndex >= verses.length || startIndex > endIndex) {
      return '';
    }

    String result = '';
    for (int i = startIndex; i <= endIndex; i++) {
      result += '${verses[i].verse}. ${verses[i].text}\n';
    }

    return result.trim();
  }

  bool isNextPickerEnabled() {
    switch (currentPickerIndex) {
      case 0:
        return selectedLanguage != null && selectedTranslation != null;
      case 2:
        return selectedBook != null && selectedChapter != null;
      case 4:
        return selectedVerseStart != null;
      default:
        return false;
    }
  }

  Widget buildCurrentPicker() {
    switch (currentPickerIndex) {
      case 0:
        return Row(
          children: [
            buildPicker(
              languages,
              "Язык",
              isLoadingLanguages,
              (index) => onLanguageSelected(languages[index].language),
              (item) => item.language,
              ValueKey('languagePicker-${languages.length}'),
            ),
            buildPicker(
              currentTranslations,
              "Перевод",
              false,
              (index) => onTranslationSelected(currentTranslations[index].shortName),
              (item) => item.shortName,
              ValueKey('translationPicker-${currentTranslations.length}'),
            ),
          ],
        );
      case 2:
        return Row(
          children: [
            buildPicker(
              books,
              "Книга",
              isLoadingBooks,
              (index) => onBookSelected(books[index].name),
              (item) => item.name,
              ValueKey('bookPicker-${books.length}'),
            ),
            buildPicker(
              chapterNumbers,
              "Глава",
              false,
              (index) => onChapterSelected(chapterNumbers[index]),
              (item) => item.toString(),
              ValueKey('chapterPicker-${chapterNumbers.length}'),
            ),
          ],
        );
      case 4:
        var availableVerses = verseNumbers.where((v) => selectedVerseStart != null && v >= selectedVerseStart!).toList();
        return Row(
          children: [
            buildPicker(
              verseNumbers,
              "От",
              isLoadingVerses,
              (index) => onVerseStartSelected(verseNumbers[index]),
              (item) => item.toString(),
              ValueKey('verseStartPicker-${verseNumbers.length}'),
            ),
            buildPicker(
              availableVerses,
              "До",
              false,
              (index) => onVerseEndSelected(availableVerses[index]),
              (item) => item.toString(),
              ValueKey('verseEndPicker-${availableVerses.length}'),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget buildPicker(
    List<dynamic> items,
    String title,
    bool isLoading,
    Function(int) onSelectedItemChanged,
    String Function(dynamic) itemLabelBuilder,
    Key key,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          width: MediaQuery.of(context).size.width * 0.4,
          child: Center(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(
          key: key,
          height: 100,
          width: MediaQuery.of(context).size.width * 0.4,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: 0),
                  itemExtent: 24.0,
                  onSelectedItemChanged: onSelectedItemChanged,
                  children: items.map((item) => Text(itemLabelBuilder(item))).toList(),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canGoBack = currentPickerIndex > 0;
    bool canGoForward = currentPickerIndex < 4 && isNextPickerEnabled();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.1,
          height: 100,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: canGoBack
                ? () {
                    setState(() {
                      currentPickerIndex -= 2;
                      widget.onTextChanged('');
                      if (currentPickerIndex == 2) {
                        selectedBook = books.first.name;
                        currentBook = books.first;
                        chapterNumbers = List.generate(currentBook!.chapters, (i) => i + 1);
                        selectedChapter = chapterNumbers.isNotEmpty ? chapterNumbers.first : null;
                      }
                    });
                  }
                : null,
          ),
        ),
        buildCurrentPicker(),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.1,
          height: 100,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: canGoForward
                ? () async {
                    if (currentPickerIndex == 0) {
                      await fetchBooks();
                    } else if (currentPickerIndex == 2) {
                      await fetchVerses();
                    }
                    setState(() {
                      currentPickerIndex += 2;
                      if (currentPickerIndex == 4) {
                        widget.onTextChanged(
                          getVersesWithText(verses, selectedVerseStart, selectedVerseEnd) ?? ''
                        );
                      }
                    });
                  }
                : null,
          ),
        ),
      ],
    );
  }
}