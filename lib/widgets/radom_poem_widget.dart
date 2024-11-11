import 'package:flutter/material.dart';
import 'package:poem_app/pages/poem_screen.dart';
import 'package:poem_app/services/network_service.dart';

import '../data/configs.dart';
import '../data/poem.dart';

class RandomPoemWidget extends StatelessWidget {

 final Function(Poem) onPoemPicked; // Define the callback

  const RandomPoemWidget({Key? key, required this.onPoemPicked}) : super(key: key);

   pickRandom(context) async {

        Poem poem = await NetworkService().randomPoem(null);

         onPoemPicked(poem);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => pickRandom(context), // Pass as a callback
      tooltip:  Configs().browsePoemsScreenGet('randomPoemButton'),
      backgroundColor: const Color.fromARGB(255, 38, 146, 38), // Set background color
      child: const Icon(
        Icons.shuffle,
        size: 30.0, // Adjust the size as needed
        color: Colors.white, // Set icon color for better contrast
      ),
    );
  }
}