class ServerDef {
  final String id;
  final int port;
  final String scheme;
  final String? tlsCert;
  final String? tlsKey;
  final CorsDef? cors;

  const ServerDef({
    required this.id,
    this.port = 8081,
    this.scheme = 'http',
    this.tlsCert,
    this.tlsKey,
    this.cors,
  });

  ServerDef copyWith({
    String? id,
    int? port,
    String? scheme,
    String? tlsCert,
    String? tlsKey,
    CorsDef? cors,
  }) {
    return ServerDef(
      id: id ?? this.id,
      port: port ?? this.port,
      scheme: scheme ?? this.scheme,
      tlsCert: tlsCert ?? this.tlsCert,
      tlsKey: tlsKey ?? this.tlsKey,
      cors: cors ?? this.cors,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'port': port,
        'scheme': scheme,
        if (tlsCert != null) 'tls_cert': tlsCert,
        if (tlsKey != null) 'tls_key': tlsKey,
        if (cors != null) 'cors': cors!.toJson(),
      };

  factory ServerDef.fromJson(Map<String, dynamic> json) => ServerDef(
        id: json['id'] as String,
        port: json['port'] as int? ?? 8081,
        scheme: json['scheme'] as String? ?? 'http',
        tlsCert: json['tls_cert'] as String?,
        tlsKey: json['tls_key'] as String?,
        cors: json['cors'] != null
            ? CorsDef.fromJson(json['cors'] as Map<String, dynamic>)
            : null,
      );
}

class CorsDef {
  final List<String> origins;
  final List<String> methods;
  final List<String> headers;

  const CorsDef({
    this.origins = const ['*'],
    this.methods = const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    this.headers = const ['Content-Type', 'Authorization'],
  });

  Map<String, dynamic> toJson() => {
        'origins': origins,
        'methods': methods,
        'headers': headers,
      };

  factory CorsDef.fromJson(Map<String, dynamic> json) => CorsDef(
        origins: (json['origins'] as List?)?.cast<String>() ?? ['*'],
        methods: (json['methods'] as List?)?.cast<String>() ??
            ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
        headers:
            (json['headers'] as List?)?.cast<String>() ?? ['Content-Type', 'Authorization'],
      );
}
