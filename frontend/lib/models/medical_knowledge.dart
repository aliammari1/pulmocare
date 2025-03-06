class MedicalReference {
  final String content;
  final double score;
  final String source;

  MedicalReference({
    required this.content,
    required this.score,
    required this.source,
  });

  factory MedicalReference.fromJson(Map<String, dynamic> json) {
    return MedicalReference(
      content: json['content'] as String,
      score: json['score'] as double,
      source: json['source'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'content': content,
        'score': score,
        'source': source,
      };
}

class KnowledgeContext {
  final String condition;
  final List<MedicalReference> references;

  KnowledgeContext({
    required this.condition,
    required this.references,
  });

  factory KnowledgeContext.fromJson(Map<String, dynamic> json) {
    return KnowledgeContext(
      condition: json['condition'] as String,
      references: (json['references'] as List)
          .map((e) => MedicalReference.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'condition': condition,
        'references': references.map((e) => e.toJson()).toList(),
      };
}

class ChatResponse {
  final String response;
  final List<MedicalReference> references;

  ChatResponse({
    required this.response,
    required this.references,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] as String,
      references: (json['references'] as List)
          .map((e) => MedicalReference.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'response': response,
        'references': references.map((e) => e.toJson()).toList(),
      };
}
