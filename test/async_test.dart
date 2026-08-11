import 'dart:developer';
import 'package:flutter_test/flutter_test.dart';

Future<int> process() async {
  await Future.delayed(Duration(seconds: 5));
  return 0;
}

Map<String, List<double>> alunos = {
  'Maria': [8.0, 9.0],
  'Bruna': [7.0, 7.0],
  'Carla': [10.0, 9.0],
};

Future<List<double>?> search(String key) async {
  return Future.delayed(Duration(seconds: 2), () {
    if (alunos.containsKey(key)) {
      return alunos[key]!;
    }
    throw ArgumentError('Aluno não encontrado.');
  });
}

Stream<int> count() async* {
  for (int i = 1; i <= 3; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

Stream<double> media(List<String> nomes) async* {
  for (String nome in nomes) {
    try {
      List<double>? notas = await search(nome);
      double soma = 0;
      for (double nota in notas!) {
        soma += nota;
      }
      yield soma / notas.length;
    } catch (error) {
      yield* Stream.error(error);
    }
  }
}

void main() {
  group('Testes de programação assíncrona', () {
    late Future<int> result;
    
    setUp(() => result = process());
    
    test('Aguardando...', () => expect(result, isNotNull));
    
    test('Testando o resultado', () async {
      int num = await result;
      expect(num, 0);
    });
    
    test('Testando busca sem erros em Future', () {
      search('Maria').then((notas) => expect(notas, [8.0, 9.0]));
    });
    
    test('Testando busca com erros em Future', () {
      search('Paula').then((notas) {}).catchError((error) {
        expect(error, isA<ArgumentError>());
      });
    });
    
    test('Testando contagem em Stream', () {
      List<int> resultados = [];
      count().listen(
        (resultado) {
          resultados.add(resultado);
        },
        onDone: () {
          expect(resultados, [1, 2, 3]);
        },
        onError: (error) => expect(error, isNotNull),
      );
    });

    test('Testando media em Stream', () {
      List<double> resultados = [];
      media(['Maria', 'Paula', 'Bruna']).listen(
        (resultado) {
          resultados.add(resultado);
          log('Média calculada com sucesso: $resultado');
        },
        onDone: () {
          expect(resultados, [8.5, 7.0]);
          log('Teste de Stream concluído com sucesso! Médias validadas.');
        },
        onError: (error) {
          expect(error, isA<ArgumentError>());
          log('Erro esperado capturado com sucesso: $error');
        },
      );
    });
  });
}