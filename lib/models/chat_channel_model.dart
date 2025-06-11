// lib/models/chat_channel_model.dart

/// Modelo de dados para representar um canal de chat de texto.
/// Adaptado para não usar Firestore.
class ChatChannelModel {
  final String id; // ID único do canal
  final String nome;
  final String clanId; // ID do clã ao qual este canal pertence
  final String? topico; // Tópico ou descrição curta do canal
  final List<String> membrosPermitidos; // Opcional: User IDs de quem pode ver/participar
  final DateTime? criadoEm; // Usar DateTime
  final String? ultimoRemetenteId; // UID do último usuário que enviou mensagem
  final String? ultimaMensagem; // Texto da última mensagem (para preview)
  final DateTime? ultimaMensagemEm; // Timestamp da última mensagem (usando DateTime)

  ChatChannelModel({
    required this.id,
    required this.nome,
    required this.clanId,
    this.topico,
    this.membrosPermitidos = const [],
    this.criadoEm,
    this.ultimoRemetenteId,
    this.ultimaMensagem,
    this.ultimaMensagemEm,
  });

  /// Converte um Map (JSON) em um objeto ChatChannelModel.
  factory ChatChannelModel.fromJson(Map<String, dynamic> json) {
    return ChatChannelModel(
      id: json["_id"] ?? json["id"] ?? "",
      nome: json["nome"] ?? "Canal Sem Nome",
      clanId: json["clanId"] ?? "",
      topico: json["topico"],
      membrosPermitidos: List<String>.from(json["membrosPermitidos"] ?? []),
      criadoEm: _parseDateTime(json["criadoEm"]),
      ultimoRemetenteId: json["ultimoRemetenteId"],
      ultimaMensagem: json["ultimaMensagem"],
      ultimaMensagemEm: _parseDateTime(json["ultimaMensagemEm"]),
    );
  }

  /// Converte o objeto ChatChannelModel em um Map (JSON).
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nome": nome,
      "clanId": clanId,
      "topico": topico,
      "membrosPermitidos": membrosPermitidos,
      "criadoEm": criadoEm?.toIso8601String(),
      "ultimoRemetenteId": ultimoRemetenteId,
      "ultimaMensagem": ultimaMensagem,
      "ultimaMensagemEm": ultimaMensagemEm?.toIso8601String(),
    };
  }

  // Helper function to parse DateTime from various potential JSON types
  static DateTime? _parseDateTime(dynamic jsonValue) {
    if (jsonValue == null) return null;
    if (jsonValue is String) {
      return DateTime.tryParse(jsonValue);
    }
    if (jsonValue is int) {
      // Assume milliseconds since epoch if it's an integer
      return DateTime.fromMillisecondsSinceEpoch(jsonValue);
    }
    // Add other potential type checks if necessary (e.g., double for seconds)
    return null;
  }
}

