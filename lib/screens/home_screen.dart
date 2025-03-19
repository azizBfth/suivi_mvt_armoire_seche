import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../database/stock_database.dart';
import '../models/stock_model.dart';
import 'add_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Set<int> _selectedRows = {}; // Tracks selected rows
  List<StockMovement> _filteredMovements = []; // Store filtered movements
  TextEditingController _searchController = TextEditingController(); // Search input controller
  String _searchQuery = ''; // Current search query
  int _currentPage = 0; // Current page number
  int _itemsPerPage = 6; // Items per page

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _searchController.addListener(_filterMovements); // Listen for search input changes
    _loadInitialData(); // Load initial data
  }

  // Load data from Hive initially and refresh the data
  void _loadInitialData() {
    setState(() {
      final box = Hive.box<StockMovement>('stockMovements');
 box.clear();
      _filteredMovements = box.values.toList(); // Reload the list
    });
  }

  // Filter movements based on search query
  void _filterMovements() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      final box = Hive.box<StockMovement>('stockMovements');
      _filteredMovements = _searchQuery.isEmpty
          ? box.values.toList()
          : box.values.where((movement) {
              return movement.productName.toLowerCase().contains(_searchQuery) ||
                  movement.storageLocation.toLowerCase().contains(_searchQuery) ||
                  movement.operatorName.toLowerCase().contains(_searchQuery) ||
                  _formatDateTime(movement.dateTime).toLowerCase().contains(_searchQuery) ||
                  movement.movementType.toLowerCase().contains(_searchQuery) ||
                  movement.quantity.toString().contains(_searchQuery); // Add quantity filtering if necessary
            }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Calculate the data for the current page
  List<StockMovement> _getPageItems() {
    int startIndex = _currentPage * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    return _filteredMovements.isEmpty
        ? []
        : _filteredMovements.sublist(
            startIndex, 
            endIndex > _filteredMovements.length ? _filteredMovements.length : endIndex,
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
        title: const Text('Suivi des Mouvements de Stock - Armoire Sèche'),
        backgroundColor: const Color.fromARGB(255, 227, 219, 250),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: (){}, // Show the filter dialog
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            onPressed: () {
              // Add export functionality here
            },
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              ValueListenableBuilder(
                valueListenable: Hive.box<StockMovement>('stockMovements').listenable(),
                builder: (context, Box<StockMovement> box, _) {
                  final movements = _filteredMovements.isEmpty && _searchQuery.isNotEmpty
                      ? []
                      : _filteredMovements.isNotEmpty
                          ? _filteredMovements
                          : box.values.toList();

                  if (movements.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(
                      child: Text(
                        "Aucun mouvement trouvé",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    );
                  }

                  final pageItems = _getPageItems();

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      shadowColor: Colors.deepPurpleAccent.withOpacity(0.3),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: DataTable(
                            columnSpacing: 24,
                            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.deepPurple.shade100),
                            headingRowHeight: 55,
                            dataRowHeight: 70,
                            columns: _buildColumns(),
                            rows: pageItems.asMap().entries.map((entry) => _buildRow(entry.key, entry.value)).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              _buildPaginationControls(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
        onPressed: () => _editMovement(context),
      ),
    );
  }

  // Edit movement action
 void _editMovement(BuildContext context, [StockMovement? movement]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
         
          movement: movement,  // Pass the movement if editing
          refreshCallback: _loadInitialData,
        ),
      ),
    );
  }
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) async {
  return showDialog<bool?>(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce mouvement de stock ?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // Return false if canceled
            },
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Return true if confirmed
            },
            child: const Text('Supprimer'),
          ),
        ],
      );
    },
  );
}
Widget _buildActionButtons(int index, StockMovement movement) {
  return Row(
    children: [
      IconButton(
        icon: const Icon(Icons.edit, color: Colors.blue),
        onPressed: () => _editMovement(context, movement),
      ),
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () async {
          bool? shouldDelete = await _showDeleteConfirmationDialog(context);
          if (shouldDelete!) {
            final box = Hive.box<StockMovement>('stockMovements');
            await box.delete(movement.id); // Suppression par clé unique
            _refreshPage(); // Rafraîchir l'affichage après suppression
          }
        },
      ),
    ],
  );
}


  // Refresh the page after actions
  void _refreshPage() {
    setState(() {
      _loadInitialData(); // Reload the data
    });
  }

  Widget _buildPaginationControls() {
    int totalPages = (_filteredMovements.length / _itemsPerPage).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Page ${_currentPage + 1} of $totalPages',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _currentPage > 0
                  ? () {
                      setState(() {
                        _currentPage--;
                      });
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _currentPage < totalPages - 1
                  ? () {
                      setState(() {
                        _currentPage++;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: 'Rechercher',
          labelStyle: TextStyle(color: Colors.deepPurpleAccent),
          prefixIcon: Icon(Icons.search, color: Colors.deepPurpleAccent),
          border: InputBorder.none,
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return const [
      DataColumn(label: Text('Date & Heure', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent))),
      DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent))),
      DataColumn(label: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent))),
      DataColumn(label: Text('Armoire', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent))),
      DataColumn(label: Text('Quantité', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent))),
      DataColumn(label: Text('Opérateur', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent))),
      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
    ];
  }

  DataRow _buildRow(int index, StockMovement movement) {
    final isSelected = _selectedRows.contains(index);
    return DataRow(
      selected: isSelected,
      onSelectChanged: (selected) {
        setState(() {
          if (selected == true) {
            _selectedRows.add(index);
          } else {
            _selectedRows.remove(index);
          }
        });
      },
      color: MaterialStateColor.resolveWith((states) => isSelected ? Colors.purple.shade100 : Colors.transparent),
      cells: [
        DataCell(Text(_formatDateTime(movement.dateTime))),
        DataCell(Text(movement.movementType,style: TextStyle(color: Colors.white,backgroundColor: movement.movementType=="sortie"?Colors.red:Colors.green,),)),
        DataCell(Text(movement.productName)),
        DataCell(Text(movement.storageLocation)),
        DataCell(Text(movement.quantity.toString())),
        DataCell(Text(movement.operatorName)),
        DataCell(_buildActionButtons(index,movement)),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}-${dateTime.month}-${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
