/// Réponse de l'assistant Moki (API backend ou fallback local).
class AssistantResponse {
  final String reply;
  final bool suggestAgents;
  final AgentSearchHints agentSearch;

  const AssistantResponse({
    required this.reply,
    this.suggestAgents = false,
    this.agentSearch = const AgentSearchHints(),
  });

  factory AssistantResponse.fromJson(Map<String, dynamic> json) {
    final search = json['agent_search'];
    return AssistantResponse(
      reply: json['reply']?.toString() ?? '',
      suggestAgents: json['suggest_agents'] == true,
      agentSearch: search is Map<String, dynamic>
          ? AgentSearchHints.fromJson(search)
          : const AgentSearchHints(),
    );
  }
}

class AgentSearchHints {
  final List<String> missionTypes;
  final List<String> keywords;
  final String? locationHint;

  const AgentSearchHints({
    this.missionTypes = const [],
    this.keywords = const [],
    this.locationHint,
  });

  factory AgentSearchHints.fromJson(Map<String, dynamic> json) {
    return AgentSearchHints(
      missionTypes: (json['mission_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
      locationHint: json['location_hint']?.toString(),
    );
  }
}
