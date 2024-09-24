import 'package:intl/intl.dart'; // For date formatting
import '../data/poem.dart'; // Assuming the Poem class is in poem.dart
import 'package:flutter/services.dart' show rootBundle;


class PoemsService {
  // Internal list to store poems
  //List<Poem> _poems = [];

  List<Poem> _poems = [
            Poem(
              text: """
Fraszka
Wciąż udowadniał  dalszym
I bliższym że on po prostu 
Zna się na wszystkim
Z tego starania wyższości mania 
Prawdzie o sobie wejścia zabrania
Tak podejmował życia wybory że konsekwencje
Aż do tej pory
Bo nie dla siebie lecz by innym udowodnić
Co sam potrafi!
Do czego jest zdolny!
Uparcie trwając w próżnej satysfakcji
Doczekał się frustracji

Roma Lemańska

""",
              publishedAt: DateTime(2024, 9, 24),
              createdAt: DateTime(2023, 12, 1),
            ),
            Poem(
              text: """
Modlitwa
Znowu Kościół Krzyżowaniem
Znowu czas nasz
Biczowaniem
Tyle zranień
Nie płacz Panie
W odrzuceniach
Tyś Cierpiący
W apostazjach
Ran krwawiących
Odnawianie
Rozdzielaniem
Nie płacz Panie
Miłość Twoja życie daje
Zmartwychwstaniem
Niepojęte!
Bezczeszczone to co święte
Co niewinne
Co rodziną wzrasta silną
Poniszczone 
Roztrwonione
Wyśmiewane
I wykpione
Nie płacz Panie
Przyjmij moje zapłakanie
Boleść srogą
Kiedy czas Golgoty drogą
Rany Twoje chcę namaścić
W biedach ludzkich
Cię przytulić
Żeby żałość Twą otulić
Mą ofiarą i modlitwą
Życia bitwą
Nie płacz Panie
Droga Krzyża 
Zwyciężaniem
W Twych radościach
Moja radość
W Twoich bólach
Czas mój bólem
Opuszczony
Krzyżowany
Jesteś  Królem
Moim Królem

Roma Lemańska
Wrocław 24.09.2024
""",
              publishedAt: DateTime(2024, 9, 24),
              createdAt: DateTime(2024, 1, 20),
            ),
            Poem(
              text: """
Modlitwa
W szczęściu Pana
Być szczęściem
Moc nie będzie zabrana
Próżno gonić za ludźmi
Uszczęśliwiać chcę Pana
Niespełnionych  miłości
Wije się kręta rzeka
Kiedy Boga pomijam
Szukam tylko człowieka
Skarbem trwać w Twym Kościele
Skarbem trwać darem wiary 
Kiedy Chrystusa kocham
Zysk dla bliźnich
Bezmiarem
W woli Pana jest szczęście
Które innym daruję
Kiedy chwila po chwili
Twą Obecność miłuję
Kiedy karmisz mą duszę
Ucztowaniem Miłości
Tylko wtedy dla innych
Szczęście w sercach ich wzrośnie

Roma Lemańska
Ząbkowice 22.09.2024
""",
              publishedAt: DateTime(2024, 9, 23),
              createdAt: DateTime(2024, 2, 5),
            ),
          ];

  // Singleton setup
  static final PoemsService _instance = PoemsService._internal();
  factory PoemsService() => _instance;
  PoemsService._internal();

  // Method to publish a new poem
  void publish(String text) {
    DateTime now = DateTime.now();
    Poem newPoem = Poem(
      text: text,
      publishedAt: now,
      createdAt: now,
    );
    print("New poem added");
    _poems.add(newPoem);

  }

  List<Poem> display(DateTime publishedAt) {
    List<Poem> poems = [];

    for (Poem poem in _poems) {
      if (poem.publishedAt.year == publishedAt.year &&
          poem.publishedAt.month == publishedAt.month &&
          poem.publishedAt.day == publishedAt.day) {
        poems.add(poem);
      }
    }

    poems.sort((poemA, poemB) => poemA.createdAt.compareTo(poemB.createdAt));

    return poems;
  }


  Future<Poem> readPoemFromFile(String path, DateTime publishedAt, DateTime createdAt) async {
    try {
      // Load the poem text from the asset (file in assets folder)
      String poemText = await rootBundle.loadString(path);

      // Create a Poem object with the current date as publishedAt and createdAt
      return Poem(
        text: poemText,
        publishedAt: publishedAt,
        createdAt: createdAt,
      );
    } catch (e) {
      print("Error reading the poem file: $e");
            return Poem(
        text: "",
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }
  }
  

  // Optional: Display all poems for debugging purposes
  void displayAll() {
    if (_poems.isEmpty) {
      print("No poems have been published yet.");
    } else {
      for (Poem poem in _poems) {
        print("Poem published on: ${DateFormat('yyyy-MM-dd').format(poem.publishedAt)}");
        print(poem.text);
        print("-----------");
      }
    }
  }
}
