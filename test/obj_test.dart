import 'package:flutter_test/flutter_test.dart';

abstract class Pessoa {
  late int _id;
  String nome;

  Pessoa(this.nome);

  int get id => _id;

  set id(int id) {
    if (id > 0) {
      _id = id;
    } else {
      throw ArgumentError('Identificador deve ser positivo.');
    }
  }
}

class Professor extends Pessoa {
  Professor(super.nome);
}

mixin Ano {
  late int _ano;
  int get ano => _ano;
  set ano(int ano) {
    if (ano > 0) {
      _ano = ano;
    } else {
      throw ArgumentError('Ano deve ser positivo.');
    }
  }
}

class Aluno extends Pessoa with Ano {
  Aluno(super.nome, int ano) {
    this.ano = ano;
  }
}

class Disciplina {
  String nome;
  Disciplina(this.nome);
}

class Turma with Ano {
  Disciplina disciplina;
  Professor professor; 
  final List<Aluno> _alunos = [];

  Turma(this.disciplina, this.professor, int ano) {
    this.ano = ano;
  }

  void matricular(Aluno aluno) {
    if (aluno.ano == ano) {
      _alunos.add(aluno);
    } else {
      throw ArgumentError('Ano do aluno deve ser o mesmo da turma.');
    }
  }
}

class Historico extends Turma {
  Map<Aluno, List<double>> notas = {};

  Historico(super.disciplina, super.professor, super.ano);

  @override
  void matricular(Aluno aluno) {
    super.matricular(aluno);
    notas[aluno] = [];
  }

  double media(Aluno aluno) {
    if (!notas.containsKey(aluno) || notas[aluno]!.isEmpty) return 0.0;
    
    double soma = 0;
    for (double nota in notas[aluno]!) {
      soma += nota;
    }
    return soma / notas[aluno]!.length;
  }

  bool isAprovado(Aluno aluno) {
    return media(aluno) >= 6.0;
  }
}

void main() {
  test('Testar matrícula, professor e aprovação', () {
    Professor prof = Professor('Sandro');
    prof.id = 10;
    Disciplina disc = Disciplina('Flutter Avançado');

    Historico historico = Historico(disc, prof, 2026);

    Aluno aluno1 = Aluno('Maria', 2026);
    aluno1.id = 1;
    historico.matricular(aluno1);

    historico.notas[aluno1] = [7.0, 8.0];
    
    expect(historico.professor.nome, 'Sandro');
    expect(historico.media(aluno1), 7.5);
    expect(historico.isAprovado(aluno1), isTrue);

    Aluno aluno2 = Aluno('João', 2026);
    aluno2.id = 2;
    historico.matricular(aluno2);
    historico.notas[aluno2] = [4.0, 5.0];
    
    print('Média da Maria: ${historico.media(aluno1)}');
    print('Status da Maria: ${historico.isAprovado(aluno1) ? "Aprovada" : "Reprovada"}');

  

    expect(historico.isAprovado(aluno2), isFalse);
  });
}