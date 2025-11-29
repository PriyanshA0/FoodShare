
import 'package:flutter/material.dart';

class NgoHomeScreen extends StatelessWidget {
  static const String routeName = "/ngo_home";

  const NgoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.volunteer_activism, size: 36, color: Colors.green),
                title: const Text('Welcome, NGO Partner'),
                subtitle: const Text('View available donations and claim pickups'),
                trailing: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to view posts screen
                  },
                  child: const Text('View Posts'),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Center(
                child: Text(
                  'NGO dashboard content goes here.\nUse this screen to accept donations and manage pickups.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
