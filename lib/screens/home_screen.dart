import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:suivi_mvt_armoire_seche/screens/export_to_pdf_screen.dart';
import '../database/stock_database.dart';
import '../models/stock_model.dart';
import 'add_edit_screen.dart';
import 'dart:io';

import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Set<int> _selectedRows = {}; // Tracks selected rows
  List<StockMovement> _filteredMovements = []; // Store filtered movements
  TextEditingController _searchController =
      TextEditingController(); // Search input controller
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

    _searchController
        .addListener(_filterMovements); // Listen for search input changes
    _loadInitialData(); // Load initial data
  }

  // Load data from Hive initially and refresh the data
  void _loadInitialData() {
    setState(() {
      final box = Hive.box<StockMovement>('stockMovements');
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
              return movement.productName
                      .toLowerCase()
                      .contains(_searchQuery) ||
                  movement.storageLocation
                      .toLowerCase()
                      .contains(_searchQuery) ||
                  movement.operatorName.toLowerCase().contains(_searchQuery) ||
                  _formatDateTime(movement.dateTime)
                      .toLowerCase()
                      .contains(_searchQuery) ||
                  movement.movementType.toLowerCase().contains(_searchQuery) ||
                  movement.quantity.toString().contains(
                      _searchQuery); // Add quantity filtering if necessary
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
    if (startIndex >= _filteredMovements.length) {
      return []; // No items to display
    }
    return _filteredMovements.sublist(
      startIndex,
      endIndex > _filteredMovements.length
          ? _filteredMovements.length
          : endIndex,
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filtrer les Mouvements"),
          content: Column(
            children: [
              // Add your filter UI here (e.g., dropdowns, date pickers, etc.)
              // For example, you can filter by product name, movement type, etc.
              TextField(
                decoration: const InputDecoration(labelText: "Produit"),
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Opérateur"),
              ),
              ElevatedButton(
                onPressed: () {
                  // Apply filter logic and close the dialog
                  Navigator.pop(context);
                },
                child: const Text("Appliquer le filtre"),
              ),
            ],
          ),
        );
      },
    );
  }
 Future<void> exportToPdf(BuildContext context) async {
    // Generate the PDF content
    final pdf = pw.Document();

 pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Text(
            'Hello, world!', // Sample text with Unicode characters
            style: pw.TextStyle(fontSize: 24),
          ),
        );
      },
    ));

    // Get the directory path
    final directory = await _getSaveDirectory();

    if (directory != null) {
      final filePath = '${directory.path}/exported_data.pdf';

      try {
        final file = File(filePath);
        await file.writeAsBytes(await pdf.save());

        // Notify the user that the PDF was saved successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF saved successfully!")),
        );
      } catch (e) {
        // Handle any errors during saving
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save PDF.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF saving was canceled.")),
      );
    }
  }

  // Get the directory path where the file will be saved
  Future<Directory?> _getSaveDirectory() async {
    try {
      if (foundation.kIsWeb) {
        // For web, it is not possible to directly access file system. You will need to use a download link.
        return null;
      } else if (Platform.isAndroid) {
        // For Android, request permission and get external storage directory
        if (await Permission.storage.request().isGranted) {
          return await getExternalStorageDirectory();
        } else {
          // Handle permission denial
          throw Exception("Permission denied to access storage");
        }
      } else if (Platform.isIOS) {
        // For iOS, use app's documents directory
        return await getApplicationDocumentsDirectory();
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // For desktop, let the user choose where to save
        return Directory('/Users/username/Documents');  // Modify as needed for the platform
      } else {
        // For unsupported platforms
        throw Exception("Unsupported platform");
      }
    } catch (e) {
      print("Error getting directory: $e");
      return null;
    }
  }

Future<Uint8List> _generatePdfData() async {
  final pdf = pw.Document();

  pdf.addPage(pw.Page(
    build: (pw.Context context) {
      return pw.Center(
        child: pw.Text("Exported PDF Content"), // Add your filtered data here
      );
    },
  ));

  return await pdf.save();
}  // Write the PDF document to a file
  Future<Uint8List> _writePdfToFile(pw.Document pdf) async {
    final pdfBytes = await pdf.save();
    return pdfBytes;
  }

  // Optionally, show the generated PDF in the app (using Flutter's pdf_viewer plugin)
  void _showPdf(BuildContext context, Uint8List pdfFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PDFViewerPage(pdfFile: pdfFile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Mouvements de Stock - Armoire Sèche'),
        backgroundColor: const Color.fromARGB(255, 227, 219, 250),
        elevation: 0,
        actions: [
          // Add button to edit a movement
          IconButton(
            icon: const Icon(Icons.add, size: 28, color: Colors.blue),
            onPressed: () {
              _editMovement(context);
              // Add export functionality here
            },
          ),

          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show the filter dialog to filter data
            //  _showFilterDialog(context);
            },
          ),

          // Download button for exporting filtered data as a PDF
          IconButton(
            icon: const Icon(Icons.download_for_offline),
            onPressed: () {
              // Call the export to PDF function
             // exportToPdf(context);
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
                valueListenable:
                    Hive.box<StockMovement>('stockMovements').listenable(),
                builder: (context, Box<StockMovement> box, _) {
                  final movements =
                      _filteredMovements.isEmpty && _searchQuery.isNotEmpty
                          ? []
                          : _filteredMovements.isNotEmpty
                              ? _filteredMovements
                              : box.values.toList();

                  if (movements.isEmpty && _searchQuery.isNotEmpty) {
                    return const Center(
                      child: Text(
                        "Aucun mouvement trouvé",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    );
                  }

                  final pageItems = _getPageItems();

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      shadowColor: Colors.deepPurpleAccent.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(
                            8.0), // Adjust the padding as needed
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: DataTable(
                              columnSpacing: 24,
                              headingRowColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.deepPurple.shade100),
                              headingRowHeight: 55,
                              dataRowHeight: 70,
                              columns: _buildColumns(),
                              rows: pageItems
                                  .asMap()
                                  .entries
                                  .map((entry) =>
                                      _buildRow(entry.key, entry.value))
                                  .toList(),
                            ),
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
    );
  }

  // Edit movement action
  void _editMovement(BuildContext context, [StockMovement? movement]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScreen(
          movement: movement, // Pass the movement if editing
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
          content: const Text(
              'Voulez-vous vraiment supprimer ce mouvement de stock ?'),
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
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              onPressed: _currentPage > 0
                  ? () {
                      setState(() {
                        _currentPage--;
                      });
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
              ),
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
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4)),
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
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  DataRow _buildRow(int index, StockMovement movement) {
    return DataRow(
      cells: [
        DataCell(Text(movement.productName)),
        DataCell(Text(_formatDateTime(movement.dateTime))),
        DataCell(Text(movement.movementType,style: TextStyle(color: Colors.white,backgroundColor: movement.movementType=="sortie"?Colors.red:Colors.green,),)),
        DataCell(Text(movement.storageLocation)),
        DataCell(Text(movement.operatorName)),
        DataCell(Text(movement.quantity.toString())),
        DataCell(_buildActionButtons(index, movement)),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}";
  }

  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(label: Text('Produit')),
      const DataColumn(label: Text('Date')),
      const DataColumn(label: Text('Type Mouvement')),
      const DataColumn(label: Text('Lieu')),
      const DataColumn(label: Text('Opérateur')),
      const DataColumn(label: Text('Quantité')),
      const DataColumn(label: Text('Actions')),
    ];
  }
}
