import 'package:flutter_test/flutter_test.dart';

bool isPerfect(int num) {
 if (num < 1) return false;
 int sum = 0;
 for (int i = 1; i <= num ~/ 2; i++) {
   if (num % i == 0) {
     sum += i;
   }
 }
 return sum == num;
}

int factorial(int n) {
 if (n < 0) throw ArgumentError('Número deve ser não negativo.');
 int result = 1;
 int i = n;
 while (i > 1) {
   result *= i;
   i--;
 }
 return result;
}

bool isPrime(int num) {
  if (num <= 1) return false; 
  for (int i = 2; i <= num ~/ 2; i++) {
    if (num % i == 0) {
      return false; 
    }
  }
  return true;
}

int sumOfDigits(int n) {
  if (n < 0) throw ArgumentError('Número não pode ser negativo.');
  
  int sum = 0;
  int temp = n;
  
  while (temp > 0) {
    sum += temp % 10; 
    temp ~/= 10;      
  }
  
  return sum;
}


void main() {
 group('Testes de Número perfeito', () {
   test('Número perfeito 6', () {
     expect(isPerfect(6), isTrue);
   });

   test('Número negativo não deve ser perfeito', () {
     expect(isPerfect(-6), isFalse);
   });
 });

 group('Testes de Fatorial', () {
   test('Fatorial de 5', () {
     expect(factorial(5), equals(120));
   });

test('Fatorial de número negativo deve lançar erro', () {
     expect(() => factorial(-3), throwsArgumentError);
   });
  }); 

group('Testes de Número Primo', () {
    test('Número primo 7 deve retornar verdadeiro', () {
      expect(isPrime(7), isTrue);
    });

    test('Número 4 não é primo, deve retornar falso', () {
      expect(isPrime(4), isFalse);
    });

    test('Número 1 não é primo', () {
      expect(isPrime(1), isFalse);
    });
  });

  group('Testes de Soma dos Dígitos', () {
    test('Soma dos dígitos de 123 deve ser 6', () {
      expect(sumOfDigits(123), equals(6));
    });

    test('Soma dos dígitos de 0 deve ser 0', () {
      expect(sumOfDigits(0), equals(0));
    });

    test('Número negativo deve lançar ArgumentError', () {
      expect(() => sumOfDigits(-123), throwsArgumentError);
    });
  });

}