// lib/models/canal_model.dart

/// Modelo de dados para representar um canal de voz.
/// Adaptado para não usar Firestore.
class CanalModel {
  final String id; // ID único do canal
  final String nome; // Nome do canal (ex: Sala de Comando)
  final List<String> membros; // Lista de User IDs dos membros atualmente no canal
  final bool ativo; // Indica se o canal está ativo/disponível
  final DateTime? criadoEm; // Data/hora de criação do canal (usando DateTime)

  CanalModel({
    required this.id,
    required this.nome,
    this.membros = const [],
    this.ativo = true,
    this.criadoEm,
  });

  /// Converte um Map (JSON) em um objeto CanalModel.
  factory CanalModel.fromJson(Map<String, dynamic> json) {
    return CanalModel(
      id: json["_id"] ?? json["id"] ?? "",
      nome: json["nome"] ?? "Canal Sem Nome",
      // Garante que membros seja sempre uma lista de Strings
      membros: List<String>.from(json["membros"] ?? []),
      ativo: json["ativo"] ?? true,
      // Converte string ISO 8601 ou timestamp numérico para DateTime
      criadoEm: json["criadoEm"] != null
          ? (json["criadoEm"] is String
              ? DateTime.tryParse(json["criadoEm"])
              : (json["criadoEm"] is int
                  ? DateTime.fromMillisecondsSinceEpoch(json["criadoEm"])
                  : null))
          : null,
    );
  }

  /// Converte o objeto CanalModel em um Map (JSON).
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nome": nome,
      "membros": membros,
      "ativo": ativo,
      // Converte DateTime para string ISO 8601
      "criadoEm": criadoEm?.toIso8601String(),
    };
  }
}

