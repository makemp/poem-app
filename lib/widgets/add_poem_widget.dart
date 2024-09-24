import 'package:flutter/material.dart';
import '../pages/add_poem_page.dart'; // Import the new page

class AddPoemWidget extends StatelessWidget {


  const AddPoemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        // Navigate to the new page and wait for the poem result
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddPoemPage(), // Open the AddPoemPage
          ),
        );

        // If the result is not null (i.e., user added a poem), call the callback to add the poem

      },
      child: const Icon(Icons.add), // "+" Icon
    );
  }
}
