class Choice {
  final String text;
  final String traitKey;

  Choice({
    required this.text,
    required this.traitKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'traitKey': traitKey,
    };
  }

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

  Map<String, dynamic> toJson() {
    return {
      'questionText': questionText,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionText: json['questionText'],
      choices: (json['choices'] as List<dynamic>)
          .map((e) => Choice.fromJson(e))
          .toList(),
    );
  }
}