import 'dart:io';

class Venda {
  Venda({
    required this.data,
    required this.produto,
    required this.categoria,
    required this.regiao,
    required this.quantidade,
    required this.precoUnitario,
    required this.custoUnitario,
  });

  final DateTime data;
  final String produto;
  final String categoria;
  final String regiao;
  final int quantidade;
  final double precoUnitario;
  final double custoUnitario;

  double get receita => quantidade * precoUnitario;
  double get lucro => quantidade * (precoUnitario - custoUnitario);
  double get margem => lucro / receita;

  static Venda fromCsv(List<String> campos, int linha) {
    if (campos.length != 7) {
      throw FormatException(
        'Linha $linha: esperados 7 campos, encontrados ${campos.length}.',
      );
    }
    try {
      return Venda(
        data: DateTime.parse(campos[0]),
        produto: campos[1],
        categoria: campos[2],
        regiao: campos[3],
        quantidade: int.parse(campos[4]),
        precoUnitario: double.parse(campos[5]),
        custoUnitario: double.parse(campos[6]),
      );
    } on FormatException {
      throw FormatException('Linha $linha: data ou número inválido.');
    }
  }
}

class Resumo {
  int quantidade = 0;
  double receita = 0;
  double lucro = 0;

  void adicionar(Venda venda) {
    quantidade += venda.quantidade;
    receita += venda.receita;
    lucro += venda.lucro;
  }

  double get margem => receita == 0 ? 0 : lucro / receita;
}

String moeda(double valor) =>
    'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
String percentual(double valor) =>
    '${(valor * 100).toStringAsFixed(1).replaceAll('.', ',')}%';
String linha(String texto, [int largura = 78]) =>
    texto.padRight(largura).substring(0, largura);

List<Venda> lerVendas(String caminho) {
  final arquivo = File(caminho);
  if (!arquivo.existsSync()) {
    throw FileSystemException('Arquivo de entrada não encontrado', caminho);
  }
  final linhas = arquivo.readAsLinesSync();
  if (linhas.length <= 1) {
    throw const FormatException('O arquivo não possui registros de venda.');
  }
  return [
    for (var i = 1; i < linhas.length; i++)
      if (linhas[i].trim().isNotEmpty)
        Venda.fromCsv(linhas[i].split(','), i + 1),
  ];
}

Map<String, Resumo> agrupar(
  Iterable<Venda> vendas,
  String Function(Venda) chave,
) {
  final resultado = <String, Resumo>{};
  for (final venda in vendas) {
    final nome = chave(venda);
    resultado.putIfAbsent(nome, Resumo.new).adicionar(venda);
  }
  return resultado;
}

String construirRelatorio(List<Venda> vendas, String caminhoDados) {
  final total = Resumo();
  for (final venda in vendas) {
    total.adicionar(venda);
  }
  final porProduto = agrupar(vendas, (venda) => venda.produto);
  final porRegiao = agrupar(vendas, (venda) => venda.regiao);
  final porMes = agrupar(
    vendas,
    (venda) =>
        '${venda.data.year}-${venda.data.month.toString().padLeft(2, '0')}',
  );
  final produtos = porProduto.entries.toList()
    ..sort((a, b) => b.value.receita.compareTo(a.value.receita));
  final regioes = porRegiao.entries.toList()
    ..sort((a, b) => b.value.receita.compareTo(a.value.receita));
  final meses = porMes.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  final melhorMes = meses.reduce(
    (a, b) => a.value.receita > b.value.receita ? a : b,
  );
  final piorMes = meses.reduce(
    (a, b) => a.value.receita < b.value.receita ? a : b,
  );
  final melhorProduto = produtos.first;
  final produtoMaiorVolume = produtos.reduce(
    (a, b) => a.value.quantidade > b.value.quantidade ? a : b,
  );
  final crescimento = meses.length > 1
      ? (meses.last.value.receita / meses.first.value.receita) - 1
      : 0.0;

  final saida = StringBuffer()
    ..writeln('RELATÓRIO GERENCIAL - TECHVENDAS')
    ..writeln('Análise de vendas de janeiro a junho de 2026')
    ..writeln('Arquivo analisado: $caminhoDados')
    ..writeln('=' * 78)
    ..writeln('1. INDICADORES GERAIS')
    ..writeln('Registros de venda: ${vendas.length}')
    ..writeln('Unidades vendidas: ${total.quantidade}')
    ..writeln('Receita bruta: ${moeda(total.receita)}')
    ..writeln('Lucro bruto estimado: ${moeda(total.lucro)}')
    ..writeln('Margem bruta: ${percentual(total.margem)}')
    ..writeln(
      'Ticket médio por registro: ${moeda(total.receita / vendas.length)}',
    )
    ..writeln()
    ..writeln('2. RANKING DE PRODUTOS POR RECEITA')
    ..writeln(
      'Produto'.padRight(25) +
          'Unid.'.padLeft(8) +
          'Receita'.padLeft(18) +
          'Margem'.padLeft(12),
    );
  for (var i = 0; i < produtos.length; i++) {
    final item = produtos[i];
    saida.writeln(
      '${(i + 1).toString().padLeft(2)}. ${item.key.padRight(21)}'
      '${item.value.quantidade.toString().padLeft(8)}'
      '${moeda(item.value.receita).padLeft(18)}'
      '${percentual(item.value.margem).padLeft(12)}',
    );
  }
  saida
    ..writeln()
    ..writeln('3. DESEMPENHO POR REGIÃO')
    ..writeln(
      'Região'.padRight(20) +
          'Unid.'.padLeft(8) +
          'Receita'.padLeft(18) +
          'Margem'.padLeft(12),
    );
  for (final item in regioes) {
    saida.writeln(
      '${item.key.padRight(20)}${item.value.quantidade.toString().padLeft(8)}'
      '${moeda(item.value.receita).padLeft(18)}${percentual(item.value.margem).padLeft(12)}',
    );
  }
  saida
    ..writeln()
    ..writeln('4. EVOLUÇÃO MENSAL')
    ..writeln(
      'Mês'.padRight(12) +
          'Unid.'.padLeft(8) +
          'Receita'.padLeft(18) +
          'Lucro'.padLeft(18),
    );
  for (final item in meses) {
    saida.writeln(
      '${item.key.padRight(12)}${item.value.quantidade.toString().padLeft(8)}'
      '${moeda(item.value.receita).padLeft(18)}${moeda(item.value.lucro).padLeft(18)}',
    );
  }
  saida
    ..writeln()
    ..writeln('5. CONCLUSÕES')
    ..writeln(
      '• ${melhorProduto.key} lidera a receita com ${moeda(melhorProduto.value.receita)}, '
      'enquanto ${produtoMaiorVolume.key} apresenta o maior volume, com '
      '${produtoMaiorVolume.value.quantidade} unidades vendidas.',
    )
    ..writeln(
      '• A região ${regioes.first.key} é a principal fonte de receita (${moeda(regioes.first.value.receita)}), '
      'enquanto a margem geral alcançou ${percentual(total.margem)}.',
    )
    ..writeln(
      '• A receita variou ${percentual(crescimento)} entre o primeiro e o último mês; '
      '${melhorMes.key} foi o melhor mês e ${piorMes.key} o menor.',
    )
    ..writeln()
    ..writeln('6. RECOMENDAÇÃO DE NEGÓCIO')
    ..writeln(
      'Priorizar estoque e campanhas de ${melhorProduto.key} na região ${regioes.first.key}, '
      'usando acessórios de maior giro como oferta complementar. Acompanhar a margem para evitar '
      'que descontos reduzam a rentabilidade, repetindo a análise após a próxima alteração no CSV.',
    )
    ..writeln('=' * 78);
  return saida.toString();
}

void main(List<String> argumentos) {
  final caminhoDados = argumentos.isEmpty
      ? 'dados/vendas.csv'
      : argumentos.first;
  final caminhoRelatorio = argumentos.length > 1
      ? argumentos[1]
      : 'relatorio.txt';
  try {
    final vendas = lerVendas(caminhoDados);
    final relatorio = construirRelatorio(vendas, caminhoDados);
    File(caminhoRelatorio).writeAsStringSync(relatorio);
    print(relatorio);
    print('\nRelatório salvo em: $caminhoRelatorio');
  } on Object catch (erro) {
    stderr.writeln('Erro: $erro');
    exitCode = 1;
  }
}
