/// Um ponto de venda = também a entidade de usuário/login (o vendedor que
/// opera o ponto). O admin é um SalePoint com role "admin" no backend, mas a
/// resposta de `/auth/` não traz o papel — então a UI filtra o próprio usuário.
class SalePoint {
  final int id;
  final String name;
  final String? email;

  SalePoint({required this.id, required this.name, this.email});

  factory SalePoint.fromJson(Map<String, dynamic> json) => SalePoint(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '—',
        email: json['email'] as String?,
      );
}
