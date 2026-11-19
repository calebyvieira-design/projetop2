# Projeto P2 - TechVendas

## Ideia e problema de negócio

A **TechVendas** é uma loja fictícia de informática. O problema investigado é
identificar quais produtos e regiões geram mais receita e lucro, além de
acompanhar a evolução mensal das vendas. Com isso, a gestão consegue decidir
onde concentrar estoque, campanhas e esforços comerciais.

O arquivo [`dados/vendas.csv`](dados/vendas.csv) contém dados fictícios de
janeiro a junho de 2026. Cada linha registra data, produto, categoria, região,
quantidade, preço de venda e custo unitário.

## Indicadores produzidos

- receita bruta, lucro bruto estimado, margem e ticket médio;
- ranking de produtos por receita;
- comparação de receita, unidades e margem por região;
- evolução mensal de unidades, receita e lucro;
- duas conclusões e uma recomendação de negócio fundamentadas nos cálculos.

## Como executar

No terminal, a partir desta pasta:

```text
dart run main.dart
```

O programa lê `dados/vendas.csv`, exibe o relatório no terminal e cria
`relatorio.txt`. Também é possível informar outros arquivos para testar
alterações na entrada:

```text
dart run main.dart dados/vendas_teste.csv relatorio_teste.txt
```

Para testar, faça uma cópia do CSV, altere uma quantidade ou preço, execute o
comando acima e compare a receita, o ranking e as conclusões com o relatório
original.

## Principais partes do código

- `Venda.fromCsv`: converte cada linha do arquivo em tipos Dart (`DateTime`,
  `int` e `double`);
- `lerVendas`: abre o arquivo e armazena os registros em uma `List<Venda>`;
- `agrupar`: calcula resumos reutilizáveis por produto, região ou mês;
- `construirRelatorio`: calcula indicadores, ordena rankings e monta o texto;
- `main`: aceita caminhos opcionais, mostra erros de entrada e salva o
  relatório.
