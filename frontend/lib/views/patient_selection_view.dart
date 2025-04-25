import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class PatientSelectionView extends StatefulWidget {
  final Function(Map<String, dynamic>) onPatientSelected;

  const PatientSelectionView({
    Key? key,
    required this.onPatientSelected,
  }) : super(key: key);

  @override
  _PatientSelectionViewState createState() => _PatientSelectionViewState();
}

class _PatientSelectionViewState extends State<PatientSelectionView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _recentPatients = [];
  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  void _loadPatients() {
    setState(() {
      _isLoading = true;
    });

    // Simulating API call
    Future.delayed(const Duration(seconds: 2), () {
      _recentPatients = _getDummyRecentPatients();
      _allPatients = _getDummyAllPatients();
      _filteredPatients = List.from(_allPatients);

      setState(() {
        _isLoading = false;
      });
    });
  }

  void _filterPatients(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPatients = List.from(_allPatients);
      });
      return;
    }

    setState(() {
      _filteredPatients = _allPatients
          .where((patient) =>
              patient['name'].toLowerCase().contains(query.toLowerCase()) ||
              patient['identifier'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  List<Map<String, dynamic>> _getDummyRecentPatients() {
    return [
      {
        'id': '1',
        'name': 'John Doe',
        'age': 45,
        'gender': 'Male',
        'identifier': 'P-1001',
        'lastVisit': '2023-05-15',
        'image': 'https://randomuser.me/api/portraits/men/1.jpg',
      },
      {
        'id': '2',
        'name': 'Jane Smith',
        'age': 32,
        'gender': 'Female',
        'identifier': 'P-1002',
        'lastVisit': '2023-05-12',
        'image': 'https://randomuser.me/api/portraits/women/1.jpg',
      },
      {
        'id': '3',
        'name': 'Michael Brown',
        'age': 58,
        'gender': 'Male',
        'identifier': 'P-1003',
        'lastVisit': '2023-05-10',
        'image': 'https://randomuser.me/api/portraits/men/2.jpg',
      },
    ];
  }

  List<Map<String, dynamic>> _getDummyAllPatients() {
    // Start with recent patients
    List<Map<String, dynamic>> allPatients = List.from(_recentPatients);

    // Add more patients
    allPatients.addAll([
      {
        'id': '4',
        'name': 'Emily Johnson',
        'age': 28,
        'gender': 'Female',
        'identifier': 'P-1004',
        'lastVisit': '2023-04-20',
        'image': 'https://randomuser.me/api/portraits/women/2.jpg',
      },
      {
        'id': '5',
        'name': 'Robert Wilson',
        'age': 62,
        'gender': 'Male',
        'identifier': 'P-1005',
        'lastVisit': '2023-04-15',
        'image': 'https://randomuser.me/api/portraits/men/3.jpg',
      },
      {
        'id': '6',
        'name': 'Sarah Davis',
        'age': 41,
        'gender': 'Female',
        'identifier': 'P-1006',
        'lastVisit': '2023-03-28',
        'image': 'https://randomuser.me/api/portraits/women/3.jpg',
      },
      {
        'id': '7',
        'name': 'James Miller',
        'age': 35,
        'gender': 'Male',
        'identifier': 'P-1007',
        'lastVisit': '2023-03-20',
        'image': 'https://randomuser.me/api/portraits/men/4.jpg',
      },
      {
        'id': '8',
        'name': 'Patricia Moore',
        'age': 52,
        'gender': 'Female',
        'identifier': 'P-1008',
        'lastVisit': '2023-02-18',
        'image': 'https://randomuser.me/api/portraits/women/4.jpg',
      },
    ]);

    return allPatients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('select_patient')),
        backgroundColor: AppTheme.turquoise,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterPatients,
              decoration: InputDecoration(
                hintText: context.tr('search_patient'),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // New Patient Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to new patient form
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.turquoise,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
              icon: const Icon(Icons.add),
              label: Text(context.tr('new_patient')),
            ),
          ),

          // Patients List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.turquoise),
                  )
                : _filteredPatients.isEmpty
                    ? Center(
                        child: Text(context.tr('no_patients_found')),
                      )
                    : CustomScrollView(
                        slivers: [
                          // Recent Patients
                          if (_searchController.text.isEmpty &&
                              _recentPatients.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  context.tr('recent_patients'),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 130,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  itemCount: _recentPatients.length,
                                  itemBuilder: (context, index) {
                                    final patient = _recentPatients[index];
                                    return _buildRecentPatientCard(patient);
                                  },
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Text(
                                  context.tr('all_patients'),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],

                          // All Patients
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final patient = _filteredPatients[index];
                                return _buildPatientListItem(patient);
                              },
                              childCount: _filteredPatients.length,
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPatientCard(Map<String, dynamic> patient) {
    return GestureDetector(
      onTap: () => widget.onPatientSelected(patient),
      child: Container(
        width: 110,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(patient['image']),
              onBackgroundImageError: (_, __) {},
              backgroundColor: Colors.grey.shade200,
              child: Text(
                patient['name'].substring(0, 1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              patient['name'],
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientListItem(Map<String, dynamic> patient) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(patient['image']),
        onBackgroundImageError: (_, __) {},
        backgroundColor: Colors.grey.shade200,
        child: Text(
          patient['name'].substring(0, 1),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(patient['name']),
      subtitle: Text(
          '${context.tr("age")}: ${patient["age"]} • ID: ${patient["identifier"]}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => widget.onPatientSelected(patient),
    );
  }
}
