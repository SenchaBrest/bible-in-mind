import 'dart:math';
import 'package:flutter/material.dart';

class EditableTextWidget extends StatefulWidget {
  final String inputString;
  final double hiddenWordPercentage;

  const EditableTextWidget({
    super.key,
    required this.inputString,
    required this.hiddenWordPercentage,
  });

  @override
  State<EditableTextWidget> createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  late TextEditingController _textController;
  late List<Color> _textColors;
  late List<String> _displayText;
  late List<bool> _hiddenWords;
  String _defaultText = '';
  int _cursorLogicalPosition = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _defaultText = widget.inputString;

    _textController = TextEditingController();
    _textColors = List.generate(_defaultText.length, (_) => Colors.white);
    _displayText = List.generate(_defaultText.length, (i) => _defaultText[i]);

    _hiddenWords = _getHiddenWordsList(_defaultText, widget.hiddenWordPercentage);
    _applyHiddenWords();

    _cursorLogicalPosition = 0;

    _textController.addListener(() {
      setState(() {
        _cursorLogicalPosition = _calculateLogicalCursorPosition(
          _textController.selection.base.offset
        );
      });
      
      _handleCursorVisibility();
    });
  }

  void _handleCursorVisibility() {
    // Убираем задержку на следующий кадр для более быстрой реакции
    if (!_scrollController.hasClients) return;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight == 0) return;

    // Увеличиваем размер буферной зоны для более раннего срабатывания прокрутки
    const double bufferZone = 100.0; // Увеличенная зона упреждения
    const double cursorPadding = 50.0; // Увеличенный отступ от курсора

    // Оцениваем текущую и предполагаемую следующую позицию курсора
    final currentPosition = _cursorLogicalPosition * 18.0;
    final nextPosition = currentPosition + 18.0; // Предполагаем следующую позицию

    final screenHeight = MediaQuery.of(context).size.height;
    final visibleHeight = screenHeight - keyboardHeight;
    
    // Проверяем, не приближается ли курсор к краю видимой области
    final bottomBoundary = _scrollController.offset + visibleHeight - keyboardHeight - bufferZone;
    
    if (nextPosition > bottomBoundary) {
      // Прокручиваем с опережением
      _scrollController.animateTo(
        nextPosition - visibleHeight + keyboardHeight + cursorPadding,
        duration: const Duration(milliseconds: 100), // Уменьшаем время анимации
        curve: Curves.easeOut,
      );
    }
  }

  double _calculateTargetScroll(
    double cursorPosition,
    double visibleHeight,
    double widgetHeight,
    double keyboardHeight
  ) {
    // Отступ от верха клавиатуры для лучшей видимости
    const double cursorPadding = 20.0;
    
    // Позиция курсора относительно начала виджета
    final cursorOffset = cursorPosition + 50.0; // 50 - примерный отступ сверху
    
    // Нижняя граница видимой области с учётом клавиатуры
    final bottomBoundary = _scrollController.offset + visibleHeight - keyboardHeight - cursorPadding;
    
    // Если курсор ниже видимой области
    if (cursorOffset > bottomBoundary) {
      return cursorOffset - visibleHeight + keyboardHeight + cursorPadding;
    }
    
    // Если курсор выше видимой области
    if (cursorOffset < _scrollController.offset + cursorPadding) {
      return max(0, cursorOffset - cursorPadding);
    }
    
    return _scrollController.offset;
  }

  // Метод для обеспечения видимости текущей позиции курсора
  void _ensureVisible(int position) {
    // Примерная оценка позиции в пикселях (18 - размер шрифта)
    final double estimatedPosition = position * 18;
    
    final double screenHeight = MediaQuery.of(context).size.height;
    final double viewportHeight = screenHeight - 100; // Учитываем отступы
    
    if (estimatedPosition > _scrollController.offset + viewportHeight) {
      // Прокрутка вниз
      _scrollController.animateTo(
        estimatedPosition - viewportHeight + 50,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else if (estimatedPosition < _scrollController.offset) {
      // Прокрутка вверх
      _scrollController.animateTo(
        estimatedPosition - 50,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant EditableTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inputString != oldWidget.inputString 
      || widget.hiddenWordPercentage != oldWidget.hiddenWordPercentage) {
      setState(() {
        _initializeState();
      });
    }
  }

  List<bool> _getHiddenWordsList(String text, double percentage) {
    final List<String> tokens = [];
    final List<bool> isWord = [];
    
    String currentWord = '';
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      if (RegExp(r'[a-zA-Zа-яА-Я]').hasMatch(char)) {
        currentWord += char;
      } else {
        if (currentWord.isNotEmpty) {
          tokens.add(currentWord);
          isWord.add(true);
          currentWord = '';
        }
        tokens.add(char);
        isWord.add(false);
      }
    }
    
    if (currentWord.isNotEmpty) {
      tokens.add(currentWord);
      isWord.add(true);
    }

    final wordCount = isWord.where((element) => element).length;
    final hiddenCount = (wordCount * percentage).round();
    
    final wordIndexes = List<int>.generate(
      tokens.length,
      (i) => i,
    ).where((i) => isWord[i]).toList();
    
    final random = Random();
    for (int i = wordIndexes.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = wordIndexes[i];
      wordIndexes[i] = wordIndexes[j];
      wordIndexes[j] = temp;
    }
    
    final hiddenTokens = List<bool>.filled(tokens.length, false);
    for (int i = 0; i < hiddenCount; i++) {
      if (i < wordIndexes.length) {
        hiddenTokens[wordIndexes[i]] = true;
      }
    }
    
    final hiddenList = <bool>[];
    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (isWord[i]) {
        hiddenList.addAll(List<bool>.filled(token.length, hiddenTokens[i]));
      } else {
        hiddenList.addAll(List<bool>.filled(token.length, false));
      }
    }
    
    return hiddenList;
  }

  void _applyHiddenWords() {
    for (int i = 0; i < _defaultText.length; i++) {
      if (!_hiddenWords[i]) {
        _displayText[i] = _defaultText[i];
        _textColors[i] = Colors.white;
      } else {
        _displayText[i] = '_';
        _textColors[i] = Colors.grey;
      }
    }
  }

  int _calculateLogicalCursorPosition(int actualPosition) {
    int count = 0;
    for (int i = 0; i < _defaultText.length; i++) {
      if (_hiddenWords[i]) {
        if (count == actualPosition) {
          return i;
        }
        count++;
      }
    }
    return _defaultText.length;
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged(String inputText) {
    setState(() {
      int inputPos = 0;
      for (int i = 0; i < _defaultText.length; i++) {
        if (_hiddenWords[i]) {
          if (inputPos < inputText.length && inputText[inputPos] == _defaultText[i]) {
            _displayText[i] = _defaultText[i];
            _textColors[i] = Colors.green;
          } else {
            if(inputPos < inputText.length) {
              _displayText[i] = inputText[inputPos];
              _textColors[i] = Colors.red;
            }
            else {
              _displayText[i] = '_';
              _textColors[i] = Colors.grey;
            }
          }
          inputPos++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Обрабатываем события скролла для более плавной работы
        if (notification is ScrollUpdateNotification) {
          _handleCursorVisibility();
        }
        return true;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(), // Более отзывчивая физика скролла
            child: Container(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              decoration: const BoxDecoration(color: Colors.black),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 8.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 50.0, // Увеличиваем нижний отступ
                ),
                child: Stack(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: List.generate(
                          _defaultText.length,
                          (i) => TextSpan(
                            text: _displayText[i],
                            style: TextStyle(
                              backgroundColor: i == _cursorLogicalPosition && i != 0
                                  ? Colors.white
                                  : Colors.transparent,
                              color: _textColors[i],
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 18,
                          height: 1.2,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        maxLines: null,
                        cursorColor: Colors.transparent,
                        onChanged: (value) {
                          final filteredValue = value.replaceAll(RegExp(r'[\s\n\r]'), '');
                          if (filteredValue != value) {
                            _textController.text = filteredValue;
                            _textController.selection = TextSelection.fromPosition(
                              TextPosition(offset: filteredValue.length),
                            );
                          }
                          _onTextChanged(filteredValue);
                          
                          // Немедленно проверяем необходимость прокрутки после изменения текста
                          _handleCursorVisibility();
                        },
                        showCursor: false,
                        keyboardType: TextInputType.visiblePassword,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}