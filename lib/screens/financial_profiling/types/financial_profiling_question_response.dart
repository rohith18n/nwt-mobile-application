// To parse this JSON data, do
//
//     final financialProfilingQuestionResponse = financialProfilingQuestionResponseFromJson(jsonString);

import 'dart:convert';

FinancialProfilingQuestionResponse financialProfilingQuestionResponseFromJson(
  String str,
) => FinancialProfilingQuestionResponse.fromJson(json.decode(str));

String financialProfilingQuestionResponseToJson(
  FinancialProfilingQuestionResponse data,
) => json.encode(data.toJson());

class FinancialProfilingQuestionResponse {
  int statusCode;
  String message;
  List<FinancialProfilingQuestionData> data;

  FinancialProfilingQuestionResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory FinancialProfilingQuestionResponse.fromJson(
    Map<String, dynamic> json,
  ) => FinancialProfilingQuestionResponse(
    statusCode: json["statusCode"],
    message: json["message"],
    data: List<FinancialProfilingQuestionData>.from(
      json["data"].map((x) => FinancialProfilingQuestionData.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "statusCode": statusCode,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class FinancialProfilingQuestionData {
  int id;
  String questiontext;
  int questionorder;
  String category;
  QuestionType type;
  bool isactive;
  String subtitle;
  dynamic inputtype;
  List<QuestionOption> options;
  QuestionAnswer answer;

  FinancialProfilingQuestionData({
    required this.id,
    required this.questiontext,
    required this.questionorder,
    required this.category,
    required this.type,
    required this.isactive,
    required this.subtitle,
    required this.inputtype,
    required this.options,
    required this.answer,
  });

  factory FinancialProfilingQuestionData.fromJson(Map<String, dynamic> json) =>
      FinancialProfilingQuestionData(
        id: json["id"],
        questiontext: json["questiontext"],
        questionorder: json["questionorder"],
        category: json["category"],
        type: questionTypeValues.map[json["type"]]!,
        isactive: json["isactive"],
        subtitle: json["subtitle"],
        inputtype: json["inputtype"],
        options: List<QuestionOption>.from(
          json["options"].map((x) => QuestionOption.fromJson(x)),
        ),
        answer: QuestionAnswer.fromJson(json["answer"]),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "questiontext": questiontext,
    "questionorder": questionorder,
    "category": category,
    "type": questionTypeValues.reverse[type],
    "isactive": isactive,
    "subtitle": subtitle,
    "inputtype": inputtype,
    "options": List<dynamic>.from(options.map((x) => x.toJson())),
    "answer": answer.toJson(),
  };
}

class QuestionAnswer {
  String answertext;
  List<int> selectedoptionids;

  QuestionAnswer({required this.answertext, required this.selectedoptionids});

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) => QuestionAnswer(
    answertext: json["answertext"],
    selectedoptionids: List<int>.from(json["selectedoptionids"].map((x) => x)),
  );

  Map<String, dynamic> toJson() => {
    "answertext": answertext,
    "selectedoptionids": List<dynamic>.from(selectedoptionids.map((x) => x)),
  };
}

class QuestionOption {
  int id;
  int questionid;
  String optiontext;
  String optionvalue;
  int displayorder;
  dynamic minvalue;
  dynamic maxvalue;
  dynamic unit;

  QuestionOption({
    required this.id,
    required this.questionid,
    required this.optiontext,
    required this.optionvalue,
    required this.displayorder,
    required this.minvalue,
    required this.maxvalue,
    required this.unit,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
    id: json["id"],
    questionid: json["questionid"],
    optiontext: json["optiontext"],
    optionvalue: json["optionvalue"],
    displayorder: json["displayorder"],
    minvalue: json["minvalue"],
    maxvalue: json["maxvalue"],
    unit: json["unit"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "questionid": questionid,
    "optiontext": optiontext,
    "optionvalue": optionvalue,
    "displayorder": displayorder,
    "minvalue": minvalue,
    "maxvalue": maxvalue,
    "unit": unit,
  };
}

enum QuestionType { MULTI, RANGE, SINGLE }

final questionTypeValues = EnumValues({
  "multi": QuestionType.MULTI,
  "range": QuestionType.RANGE,
  "single": QuestionType.SINGLE,
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
