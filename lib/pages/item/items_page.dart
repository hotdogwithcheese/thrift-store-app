// lib/pages/items_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/supabase_service.dart';
import '../../models/item.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({super.key});
  @override
  ItemsPageState createState() => ItemsPageState();
}

class ItemsPageState extends State<ItemsPage> {
  late Future<List<Item>> _fetchFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final svc = Provider.of<SupabaseService>(context, listen: false);
    _fetchFuture = svc.fetchItems().then((_) => svc.items);
  }

  Future<void> _refresh() async {
    _loadItems();
    await _fetchFuture;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final svc          = Provider.of<SupabaseService>(context, listen: false);
    final currentEmail = Supabase.instance.client.auth.currentUser?.email;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF12c2e9), // cyan
              Color(0xFFc471ed), // purple
              Color(0xFFf64f59), // pink/red
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      'Reynaldo Store',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        await svc.signOut();
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/signin', (_) => false);
                      },
                    ),
                  ],
                ),
              ),

              // Content grid
              Expanded(
                child: RefreshIndicator(
                  color: Colors.white,
                  onRefresh: _refresh,
                  child: FutureBuilder<List<Item>>(
                    future: _fetchFuture,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            'Oops! ${snap.error}',
                            style: GoogleFonts.poppins(color: Colors.redAccent),
                          ),
                        );
                      }
                      final items = snap.data!;
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'No treasures yet 🧐',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item    = items[i];
                          final isOwner = item.uploaderEmail == currentEmail;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // Image
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (isOwner)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                              BorderRadius.circular(30),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                  Icons.delete, size: 20),
                                              color: Colors.white,
                                              onPressed: () async {
                                                await svc.deleteItem(item.id);
                                                await _refresh();
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Details
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Php ${item.price.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFf64f59),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'By ${item.uploadedBy}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(14),
                                            ),
                                            elevation: 4,
                                            backgroundColor:
                                            const Color(0xFF7209B7),
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/detail',
                                              arguments: item.id,
                                            );
                                          },
                                          child: Text(
                                            'View Details',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Add New button
              Padding(
                padding: const EdgeInsets.all(16),
                child: FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF12c2e9),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add New',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/add');
                    await _refresh();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
