class Choice {
  final String text;
  final String traitKey;

  Choice({
    required this.text,
    required this.traitKey,
  });

  // ➤ toJson: 객체 → Map
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'traitKey': traitKey,
    };
  }

  // ➤ fromJson: Map → 객체
  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      text: json['text'],
      traitKey: json['traitKey'],
    );
  }
}

class Question {
  final String questionText;
  final List<Choice> choices;

  Question({
    required this.questionText,
    required this.choices,
  });

  // 객체 → Map
  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }

  //  Map → 객체
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionText: json['questionText'],
      choices: (json['choices'] as List<dynamic>)
          .map((e) => Choice.fromJson(e))
          .toList(),
    );
  }
}