import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../inventory_bloc.dart';
import '../widgets/inventory_item_widget.dart';
import 'map_page.dart';

/// The Main Screen of the application.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// initState runs ONCE when this page is first created.
  @override
  void initState() {
    super.initState();
    // Use the Bloc (Logic) to ask for the data to be loaded.
    context.read<InventoryBloc>().add(LoadInventoryItems());
  }

  /// build describes what the UI looks like.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The Top Bar
      appBar: AppBar(
        title: const Text('Guardian Inventory'),
        actions: [
          // The Map Button
          IconButton(
            icon: const Icon(Icons.map), // Map icon
            onPressed: () {
              // Navigation: Go to the MapPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapPage()),
              );
            },
          ),
        ],
      ),
      // The Main content changes based on the data (State)
      body: BlocBuilder<InventoryBloc, InventoryState>(
        builder: (context, state) {
          // CASE 1: Loading
          if (state is InventoryLoading || state is InventoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          // CASE 2: Loaded successfully
          else if (state is InventoryLoaded) {
            if (state.items.isEmpty) {
              return const Center(child: Text("No items monitored"));
            }
            // Show a scrolling list of items
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.items.length, // How many items?
              itemBuilder: (context, index) {
                // Get the specific item for this row
                final item = state.items[index];

                // Draw the card widget for this item
                return InventoryItemWidget(
                  item: item,
                  // When the Star button is clicked...
                  onToggleEssential: () {
                    // Tell the Logic (Bloc) to toggle the essential status
                    context.read<InventoryBloc>().add(
                      ToggleEssentialStatus(item.id),
                    );
                  },
                  onTap: () {
                    // Navigate to details if needed (Future feature)
                  },
                );
              },
            );
          }
          // CASE 3: Error
          else if (state is InventoryError) {
            return Center(child: Text('Error: ${state.message}'));
          } else {
            return const SizedBox.shrink(); // Show nothing if weird state
          }
        },
      ),
    );
  }
}
