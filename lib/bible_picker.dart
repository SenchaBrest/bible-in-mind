import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  List<Book> books = [];
  List<int> chapterNumbers = [];
  List<Verse> verses = [];
  List<int> verseNumbers = [];

  String? selectedBook;
  int? selectedChapter;
  int? selectedVerseStart;
  int? selectedVerseEnd;
  Book? currentBook;

  bool isLoadingBooks = true;
  bool isLoadingVerses = false;

  int currentPickerIndex = 0;

  // Ключи для SharedPreferences
  static const String _bookKey = 'selectedBook';
  static const String _chapterKey = 'selectedChapter';

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences().then((_) {
      fetchBooks(); // Загружаем книги после загрузки сохраненных значений
    });
  }

  // Загрузка сохраненных значений из SharedPreferences
  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedBook = prefs.getString(_bookKey);
      selectedChapter = prefs.getInt(_chapterKey);
    });
  }

  // Сохранение значений в SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookKey, selectedBook ?? '');
    await prefs.setInt(_chapterKey, selectedChapter ?? 0);
  }

  Future<void> fetchBooks() async {
    setState(() {
      isLoadingBooks = true;
    });
    try {
      final fetchedBooks = await apiService.fetchBooks("SYNOD");
      setState(() {
        books = fetchedBooks;
        if (books.isNotEmpty) {
          // Если книга была сохранена, выбираем ее, иначе первую книгу
          selectedBook = selectedBook ?? books.first.name;
          currentBook = books.firstWhere((b) => b.name == selectedBook);
          chapterNumbers = List.generate(currentBook!.chapters, (i) => i + 1);
          // Если глава была сохранена, выбираем ее, иначе первую главу
          selectedChapter = selectedChapter ?? chapterNumbers.first;
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
    if (currentBook == null || selectedChapter == null) return;

    setState(() {
      isLoadingVerses = true;
    });
    try {
      final fetchedVerses = await apiService.fetchChapterText(
        "SYNOD",
        currentBook!.bookId.toString(),
        selectedChapter.toString(),
      );
      setState(() {
        verses = fetchedVerses;
        verseNumbers = verses.map((v) => v.verse).toList();

        // Устанавливаем начальные значения для стихов
        selectedVerseStart = verseNumbers.first;
        selectedVerseEnd = verseNumbers.first;

        // Обновляем текст, если стихи уже выбраны
        if (selectedVerseStart != null && selectedVerseEnd != null) {
          widget.onTextChanged(
            getVersesWithText(verses, selectedVerseStart, selectedVerseEnd) ?? '',
          );
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

  void onBookSelected(String book) {
    setState(() {
      selectedBook = book;
      currentBook = books.firstWhere((b) => b.name == book);
      chapterNumbers = List.generate(currentBook!.chapters, (i) => i + 1);
      selectedChapter = chapterNumbers.first; // Сбрасываем главу
      _savePreferences(); // Сохраняем изменения
    });
  }

  void onChapterSelected(int chapter) {
    setState(() {
      selectedChapter = chapter;
      _savePreferences(); // Сохраняем изменения
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
        return selectedBook != null && selectedChapter != null;
      case 2:
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
              books,
              "Книга",
              isLoadingBooks,
              (index) => onBookSelected(books[index].name),
              (item) => item.name,
              ValueKey('bookPicker-${books.length}-${selectedBook}'),
              initialItem: books.indexWhere((b) => b.name == selectedBook),
            ),
            buildPicker(
              chapterNumbers,
              "Глава",
              false,
              (index) => onChapterSelected(chapterNumbers[index]),
              (item) => item.toString(),
              ValueKey('chapterPicker-${chapterNumbers.length}-${selectedChapter}'),
              initialItem: chapterNumbers.indexOf(selectedChapter ?? 1),
            ),
          ],
        );
      case 2:
        var availableVerses = verseNumbers.where((v) => selectedVerseStart != null && v >= selectedVerseStart!).toList();
        return Row(
          children: [
            buildPicker(
              verseNumbers,
              "От",
              isLoadingVerses,
              (index) => onVerseStartSelected(verseNumbers[index]),
              (item) => item.toString(),
              ValueKey('verseStartPicker-${verseNumbers.length}-${selectedVerseStart}'),
              initialItem: verseNumbers.indexOf(selectedVerseStart ?? 1),
            ),
            buildPicker(
              availableVerses,
              "До",
              false,
              (index) => onVerseEndSelected(availableVerses[index]),
              (item) => item.toString(),
              ValueKey('verseEndPicker-${availableVerses.length}-${selectedVerseEnd}'),
              initialItem: availableVerses.indexOf(selectedVerseEnd ?? 1),
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
    Key key, {
    int initialItem = 0,
  }) {
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
                  scrollController: FixedExtentScrollController(initialItem: initialItem),
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
    bool canGoForward = currentPickerIndex < 2 && isNextPickerEnabled();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (canGoBack)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.1,
            height: 100,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  currentPickerIndex -= 2; // Уменьшаем индекс пикера
                  widget.onTextChanged(''); // Сбрасываем текст
                });
              },
            ),
          ),
        buildCurrentPicker(),
        if (canGoForward)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.1,
            height: 100,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () async {
                if (currentPickerIndex == 0) {
                  await fetchVerses(); // Загружаем стихи только после нажатия кнопки
                }
                setState(() {
                  currentPickerIndex += 2;
                  if (currentPickerIndex == 2) {
                    widget.onTextChanged(
                      getVersesWithText(verses, selectedVerseStart, selectedVerseEnd) ?? '',
                    );
                  }
                });
              },
            ),
          ),
      ],
    );
  }
}