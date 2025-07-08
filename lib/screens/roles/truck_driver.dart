import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
void main() {
  runApp(TruckDeliveryApp());
}

class TruckDeliveryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoTruck Delivery',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    DeliveryScreen(),
    LeaderboardScreen(),
    UnloadingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green[700],
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping),
              label: 'Delivery',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'Unloading',
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryScreen extends StatefulWidget {
  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  bool _orderAccepted = false;
  bool _isDelivering = false;
  int _currentWaypoint = 0;
  Timer? _deliveryTimer;
  BitmapDescriptor? _truckIcon;

  // Realistic route points from supplier to Walmart warehouse
  final List<LatLng> _routePoints = [
    LatLng(12.9716, 77.5946), // Supplier location (Bangalore)
    LatLng(12.9750, 77.6050), // Waypoint 1
    LatLng(12.9800, 77.6150), // Waypoint 2
    LatLng(12.9850, 77.6250), // Waypoint 3
    LatLng(12.9900, 77.6350), // Waypoint 4
    LatLng(12.9950, 77.6450), // Waypoint 5
    LatLng(13.0000, 77.6550), // Walmart warehouse
  ];

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _currentPosition = LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    _setupInitialMarkers();
    _loadCustomMarker();
  }

  Future<void> _loadCustomMarker() async {
    final ByteData data = await rootBundle.load('assets/images/truck_icon.png');
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 80,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resizedImage = byteData!.buffer.asUint8List();
    setState(() {
      _truckIcon = BitmapDescriptor.fromBytes(resizedImage);
    });
  }

  void _setupInitialMarkers() {
    _markers.add(
      Marker(
        markerId: MarkerId('supplier'),
        position: _routePoints.first,
        infoWindow: InfoWindow(
          title: 'Supplier Location',
          snippet: 'Ready for pickup',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    _markers.add(
      Marker(
        markerId: MarkerId('walmart'),
        position: _routePoints.last,
        infoWindow: InfoWindow(
          title: 'Walmart Warehouse',
          snippet: 'Delivery destination',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
  }

  void _acceptOrder() {
    setState(() {
      _orderAccepted = true;
    });
    
    _createRoute();
    _startDelivery();
  }

  void _createRoute() {
    _polylines.add(
      Polyline(
        polylineId: PolylineId('delivery_route'),
        points: _routePoints,
        color: Colors.green,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _startDelivery() {
    setState(() {
      _isDelivering = true;
    });

    _deliveryTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_currentWaypoint < _routePoints.length - 1) {
        setState(() {
          _currentWaypoint++;
          _currentPosition = _routePoints[_currentWaypoint];
        });

        _updateTruckMarker();
        _animateCamera();
      } else {
        timer.cancel();
        setState(() {
          _isDelivering = false;
        });
        _showDeliveryComplete();
      }
    });
  }

  void _updateTruckMarker() {
    _markers.removeWhere((marker) => marker.markerId.value == 'truck');
    _markers.add(
      Marker(
        markerId: MarkerId('truck'),
        position: _currentPosition,
        infoWindow: InfoWindow(
          title: 'Ramesh\'s Truck',
          snippet: 'En route to Walmart',
        ),
        icon: _truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );
  }

  void _animateCamera() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 14,
          tilt: 30,
        ),
      ),
    );
  }

  void _recenterCamera() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 14,
          tilt: 30,
        ),
      ),
    );
  }

  void _showDeliveryComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delivery Complete!'),
        content: Text('Successfully delivered to Walmart warehouse'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _deliveryTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EcoTruck Delivery'),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (!_orderAccepted) _buildOrderCard(),
          if (_orderAccepted) _buildDeliveryStats(),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _routePoints.first,
                    zoom: 14,
                    tilt: 30,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _orderAccepted
          ? FloatingActionButton(
              onPressed: _recenterCamera,
              backgroundColor: Colors.green[700],
              child: Icon(Icons.my_location, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildOrderCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Icon(Icons.local_shipping, color: Colors.green[700]),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Delivery Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'From Supplier to Walmart Warehouse',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip('Distance', '25.4 km'),
              SizedBox(width: 12),
              _buildInfoChip('Est. Time', '45 min'),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip('Eco Score', '+85 pts'),
              SizedBox(width: 12),
              _buildInfoChip('Carbon Saved', '12.3 kg'),
            ],
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _acceptOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Accept Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStats() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driver: Ramesh Sharma',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isDelivering ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isDelivering ? 'In Transit' : 'Delivered',
                  style: TextStyle(
                    color: _isDelivering ? Colors.orange[700] : Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Vehicle: Tata Ace Electric',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'License: KA05-AB-1234',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Contact: +91 98765 43210',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Distance', '${(_currentWaypoint * 4.2).toStringAsFixed(1)} km')),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard('CO₂ Saved', '${(_currentWaypoint * 2.1).toStringAsFixed(1)} kg')),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard('Progress', '${((_currentWaypoint / (_routePoints.length - 1)) * 100).toInt()}%')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData = [
    {'name': 'Ramesh Sharma', 'score': 2450, 'carbon': 185.2, 'rank': 1},
    {'name': 'Suresh Sharma', 'score': 2380, 'carbon': 179.8, 'rank': 2},
    {'name': 'Vijay Singh', 'score': 2320, 'carbon': 175.1, 'rank': 3},
    {'name': 'Amit Patel', 'score': 2280, 'carbon': 172.3, 'rank': 4},
    {'name': 'Raj Gupta', 'score': 2240, 'carbon': 168.9, 'rank': 5},
    {'name': 'Krishna Reddy', 'score': 2190, 'carbon': 165.2, 'rank': 6},
    {'name': 'Ganesh Yadav', 'score': 2150, 'carbon': 162.8, 'rank': 7},
    {'name': 'Manoj Kumar', 'score': 2110, 'carbon': 159.7, 'rank': 8},
    {'name': 'Ravi Joshi', 'score': 2080, 'carbon': 157.1, 'rank': 9},
    {'name': 'Deepak Mehta', 'score': 2050, 'carbon': 154.8, 'rank': 10},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Green Travel Leaderboard'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final driver = leaderboardData[index];
                return _buildLeaderboardCard(driver, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[700]!, Colors.green[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Monthly Green Challenge',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Total Drivers', '847'),
              _buildHeaderStat('CO₂ Saved', '12.8T'),
              _buildHeaderStat('Your Rank', '#1'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(Map<String, dynamic> driver, int index) {
    Color rankColor = Colors.grey[600]!;
    IconData rankIcon = Icons.person;

    if (index == 0) {
      rankColor = Colors.amber[700]!;
      rankIcon = Icons.emoji_events;
    } else if (index == 1) {
      rankColor = Colors.grey[500]!;
      rankIcon = Icons.emoji_events;
    } else if (index == 2) {
      rankColor = Colors.orange[700]!;
      rankIcon = Icons.emoji_events;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: index == 0 ? Border.all(color: Colors.amber[300]!, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              rankIcon,
              color: rankColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.eco, color: Colors.green[600], size: 16),
                    SizedBox(width: 4),
                    Text(
                      '${driver['carbon']} kg CO₂ saved',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '#${driver['rank']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${driver['score']} pts',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// UnloadingScreen remains unchanged
class UnloadingScreen extends StatefulWidget {
  @override
  _UnloadingScreenState createState() => _UnloadingScreenState();
}

class _UnloadingScreenState extends State<UnloadingScreen> {
  DateTime? _scheduledTime;
  bool _isUnloading = false;
  int _progress = 0;
  Timer? _unloadingTimer;

  // Sample inventory data
  final List<Map<String, dynamic>> _inventoryItems = [
    {'name': 'Electronics', 'quantity': 50, 'status': 'Pending'},
    {'name': 'Clothing', 'quantity': 100, 'status': 'Pending'},
    {'name': 'Groceries', 'quantity': 200, 'status': 'Pending'},
    {'name': 'Furniture', 'quantity': 20, 'status': 'Pending'},
  ];

  @override
  void initState() {
    super.initState();
    _scheduledTime = DateTime.now().add(Duration(hours: 2, minutes: 30));
  }

  void _startUnloading() {
    setState(() {
      _isUnloading = true;
      _progress = 0;
    });

    _unloadingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_progress < 100) {
        setState(() {
          _progress += 2;
          // Update inventory status as progress increases
          if (_progress >= 25 && _inventoryItems[0]['status'] == 'Pending') {
            _inventoryItems[0]['status'] = 'Unloaded';
          }
          if (_progress >= 50 && _inventoryItems[1]['status'] == 'Pending') {
            _inventoryItems[1]['status'] = 'Unloaded';
          }
          if (_progress >= 75 && _inventoryItems[2]['status'] == 'Pending') {
            _inventoryItems[2]['status'] = 'Unloaded';
          }
          if (_progress >= 100 && _inventoryItems[3]['status'] == 'Pending') {
            _inventoryItems[3]['status'] = 'Unloaded';
          }
        });
      } else {
        timer.cancel();
        setState(() {
          _isUnloading = false;
        });
        _showUnloadingComplete();
      }
    });
  }

  void _showUnloadingComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unloading Complete!'),
        content: Text('All items have been successfully unloaded at the warehouse.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _unloadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unloading Schedule'),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWarehouseInfo(),
            SizedBox(height: 20),
            _buildScheduleCard(),
            SizedBox(height: 20),
            _buildUnloadingProgress(),
            SizedBox(height: 20),
            _buildInventoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.warehouse,
              color: Colors.blue[700],
              size: 30,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Walmart Distribution Center',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bay 12, Sector 7, Bangalore',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.green[600]),
                    SizedBox(width: 4),
                    Text(
                      'Open 24/7',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduled Unloading Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.green[700]),
                    SizedBox(width: 8),
                    Text(
                      '${_scheduledTime?.hour.toString().padLeft(2, '0')}:${_scheduledTime?.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          if (!_isUnloading)
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startUnloading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Start Unloading',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnloadingProgress() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Unloading Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '$_progress%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
            minHeight: 8,
          ),
          SizedBox(height: 8),
          Text(
            _isUnloading ? 'Unloading in progress...' : 'Ready to unload',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList() {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory List',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _inventoryItems.length,
                itemBuilder: (context, index) {
                  final item = _inventoryItems[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Quantity: ${item['quantity']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: item['status'] == 'Unloaded'
                                ? Colors.green[100]
                                : Colors.orange[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['status'],
                            style: TextStyle(
                              color: item['status'] == 'Unloaded'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}