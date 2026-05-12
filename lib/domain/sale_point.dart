class SalePoint {
  final int id;
  final String name;
  final String? email;

  SalePoint({
    required this.id,
    required this.name,
    this.email,
  });

  // Transforma o JSON da API em um Objeto SalePoint
  factory SalePoint.fromJson(Map<String, dynamic> json) {
    return SalePoint(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }

  // Se precisar enviar dados de volta para a API (ex: atualizar perfil)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}