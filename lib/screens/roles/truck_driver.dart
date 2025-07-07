import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

// Shared data
final List<String> walmartLocations = [
  'Walmart Bangalore Central',
  'Walmart Hyderabad West',
  'Walmart Mumbai East',
  'Walmart Chennai North',
  'Walmart Delhi NCR',
  'Walmart Pune South',
  'Walmart Kolkata Central',
  'Walmart Ahmedabad',
  'Walmart Jaipur',
  'Walmart Kochi'
];

final List<LatLng> walmartCoords = [
  LatLng(12.9716, 77.5946), // Bangalore
  LatLng(17.3850, 78.4867), // Hyderabad
  LatLng(19.0760, 72.8777), // Mumbai
  LatLng(13.0827, 80.2707), // Chennai
  LatLng(28.7041, 77.1025), // Delhi
  LatLng(18.5204, 73.8567), // Pune
  LatLng(22.5726, 88.3639), // Kolkata
  LatLng(23.0225, 72.5714), // Ahmedabad
  LatLng(26.9124, 75.7873), // Jaipur
  LatLng(9.9312, 76.2673),  // Kochi
];

// Models
class DeliveryOrder {
  final String id;
  final String productName;
  final int quantity;
  final String destination;
  final LatLng destinationCoords;
  final String status;
  final double weight;
  final String priority;
  final DateTime estimatedDelivery;
  final double distance;
  final double carbonFootprint;
  final String timeSlot;
  final LatLng originCoords;

  DeliveryOrder({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.destination,
    required this.destinationCoords,
    required this.status,
    required this.weight,
    required this.priority,
    required this.estimatedDelivery,
    required this.distance,
    required this.carbonFootprint,
    required this.timeSlot,
    required this.originCoords,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productName': productName,
        'quantity': quantity,
        'destination': destination,
        'destinationCoords': {'lat': destinationCoords.latitude, 'lng': destinationCoords.longitude},
        'status': status,
        'weight': weight,
        'priority': priority,
        'estimatedDelivery': estimatedDelivery.toIso8601String(),
        'distance': distance,
        'carbonFootprint': carbonFootprint,
        'timeSlot': timeSlot,
        'originCoords': {'lat': originCoords.latitude, 'lng': originCoords.longitude},
      };

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) => DeliveryOrder(
        id: json['id'],
        productName: json['productName'],
        quantity: json['quantity'],
        destination: json['destination'],
        destinationCoords: LatLng(json['destinationCoords']['lat'], json['destinationCoords']['lng']),
        status: json['status'],
        weight: json['weight'],
        priority: json['priority'],
        estimatedDelivery: DateTime.parse(json['estimatedDelivery']),
        distance: json['distance'],
        carbonFootprint: json['carbonFootprint'],
        timeSlot: json['timeSlot'],
        originCoords: LatLng(json['originCoords']['lat'], json['originCoords']['lng']),
      );
}

class DriverProfile {
  final String id;
  final String name;
  final String vehicleNumber;
  final String vehicleType;
  final double carbonFootprint;
  final int deliveriesCompleted;
  final LatLng currentLocation;
  final String timeSlot;
  final bool isAvailable;
  final double rating;
  final String phoneNumber;

  DriverProfile({
    required this.id,
    required this.name,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.carbonFootprint,
    required this.deliveriesCompleted,
    required this.currentLocation,
    required this.timeSlot,
    required this.isAvailable,
    required this.rating,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'vehicleNumber': vehicleNumber,
        'vehicleType': vehicleType,
        'carbonFootprint': carbonFootprint,
        'deliveriesCompleted': deliveriesCompleted,
        'currentLocation': {'lat': currentLocation.latitude, 'lng': currentLocation.longitude},
        'timeSlot': timeSlot,
        'isAvailable': isAvailable,
        'rating': rating,
        'phoneNumber': phoneNumber,
      };

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
        id: json['id'],
        name: json['name'],
        vehicleNumber: json['vehicleNumber'],
        vehicleType: json['vehicleType'],
        carbonFootprint: json['carbonFootprint'],
        deliveriesCompleted: json['deliveriesCompleted'],
        currentLocation: LatLng(json['currentLocation']['lat'], json['currentLocation']['lng']),
        timeSlot: json['timeSlot'],
        isAvailable: json['isAvailable'],
        rating: json['rating'],
        phoneNumber: json['phoneNumber'],
      );
}

class LeaderboardEntry {
  final String driverName;
  final double carbonSaved;
  final int greenDeliveries;
  final String vehicleType;
  final double rating;

  LeaderboardEntry({
    required this.driverName,
    required this.carbonSaved,
    required this.greenDeliveries,
    required this.vehicleType,
    required this.rating,
  });

  Map<String, dynamic> toJson() => {
        'driverName': driverName,
        'carbonSaved': carbonSaved,
        'greenDeliveries': greenDeliveries,
        'vehicleType': vehicleType,
        'rating': rating,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        driverName: json['driverName'],
        carbonSaved: json['carbonSaved'],
        greenDeliveries: json['greenDeliveries'],
        vehicleType: json['vehicleType'],
        rating: json['rating'],
      );
}

class TimeSlot {
  final String time;
  final int trucksAllocated;
  final int maxCapacity;
  final List<String> driverNames;

  TimeSlot({
    required this.time,
    required this.trucksAllocated,
    required this.maxCapacity,
    required this.driverNames,
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'trucksAllocated': trucksAllocated,
        'maxCapacity': maxCapacity,
        'driverNames': driverNames,
      };

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        time: json['time'],
        trucksAllocated: json['trucksAllocated'],
        maxCapacity: json['maxCapacity'],
        driverNames: List<String>.from(json['driverNames']),
      );
}

// Data Generator
class TruckDriverDataGenerator {
  static final Random _random = Random();
  
  static final List<String> _products = [
    'Electronics Bundle', 'Clothing Collection', 'Fresh Produce', 
    'Book Set', 'Furniture Items', 'Toy Collection', 
    'Sports Gear', 'Kitchen Appliances', 'Beauty Products',
    'Health Supplements', 'Auto Parts', 'Garden Equipment'
  ];
  
  static final List<String> _vehicleTypes = [
    'Tata Ace', 'Mahindra Bolero Pickup', 'Ashok Leyland Dost',
    'Eicher Pro 1049', 'Tata 407', 'Mahindra Furio 7'
  ];
  
  static final List<String> _timeSlots = [
  '06:00 - 08:00',
  '08:00 - 10:00',
  '10:00 - 12:00',
  '12:00 - 14:00',
  '14:00 - 16:00',
  '16:00 - 18:00'
];
  
  static final List<String> _driverNames = [
    'Rajesh Kumar', 'Amit Singh', 'Suresh Patel', 'Vikram Sharma',
    'Ravi Gupta', 'Manoj Yadav', 'Santosh Joshi', 'Deepak Verma',
    'Arjun Reddy', 'Kiran Patel', 'Rohit Sharma', 'Naveen Kumar'
  ];

  static DriverProfile generateDriverProfile() {
    final locationIndex = _random.nextInt(walmartCoords.length);
    return DriverProfile(
      id: 'DRV${DateTime.now().millisecondsSinceEpoch}',
      name: _driverNames[_random.nextInt(_driverNames.length)],
      vehicleNumber: '${['KA', 'MH', 'TN', 'DL', 'UP', 'GJ'][_random.nextInt(6)]}${10 + _random.nextInt(40)}${['A', 'B', 'C'][_random.nextInt(3)]}${1000 + _random.nextInt(9000)}',
      vehicleType: _vehicleTypes[_random.nextInt(_vehicleTypes.length)],
      carbonFootprint: 50.0 + _random.nextDouble() * 200.0,
      deliveriesCompleted: _random.nextInt(500) + 50,
      currentLocation: walmartCoords[locationIndex],
      timeSlot: _timeSlots[_random.nextInt(_timeSlots.length)],
      isAvailable: _random.nextBool(),
      rating: 3.5 + _random.nextDouble() * 1.5,
      phoneNumber: '+91${7000000000 + _random.nextInt(2999999999)}',
    );
  }

  static DeliveryOrder generateRandomOrder() {
    final locationIndex = _random.nextInt(walmartCoords.length);
    final originIndex = _random.nextInt(walmartCoords.length);
    final distance = 5.0 + _random.nextDouble() * 45.0;
    final weight = 10.0 + _random.nextDouble() * 500.0;
    final carbonFootprint = (distance * 0.5) + (weight * 0.02);
    
    return DeliveryOrder(
      id: 'ORD${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(1000)}',
      productName: _products[_random.nextInt(_products.length)],
      quantity: _random.nextInt(50) + 1,
      destination: walmartLocations[locationIndex],
      destinationCoords: walmartCoords[locationIndex],
      status: ['Pending', 'In Transit', 'Delivered'][_random.nextInt(3)],
      weight: weight,
      priority: ['High', 'Medium', 'Low'][_random.nextInt(3)],
      estimatedDelivery: DateTime.now().add(Duration(hours: _random.nextInt(48) + 1)),
      distance: distance,
      carbonFootprint: carbonFootprint,
      timeSlot: _timeSlots[_random.nextInt(_timeSlots.length)],
      originCoords: walmartCoords[originIndex],
    );
  }

  static List<LeaderboardEntry> generateLeaderboard() {
    return List.generate(10, (index) {
      final carbonSaved = 50.0 + _random.nextDouble() * 500.0;
      return LeaderboardEntry(
        driverName: _driverNames[_random.nextInt(_driverNames.length)],
        carbonSaved: carbonSaved,
        greenDeliveries: _random.nextInt(200) + 50,
        vehicleType: _vehicleTypes[_random.nextInt(_vehicleTypes.length)],
        rating: 3.5 + _random.nextDouble() * 1.5,
      );
    })..sort((a, b) => b.carbonSaved.compareTo(a.carbonSaved));
  }

  static List<TimeSlot> generateTimeSlots() {
    return _timeSlots.map((time) {
      final trucksAllocated = _random.nextInt(8) + 2;
      final maxCapacity = trucksAllocated + _random.nextInt(5) + 1;
      final drivers = List.generate(trucksAllocated, 
        (index) => _driverNames[_random.nextInt(_driverNames.length)]);
      
      return TimeSlot(
        time: time,
        trucksAllocated: trucksAllocated,
        maxCapacity: maxCapacity,
        driverNames: drivers,
      );
    }).toList();
  }
}

// Main Truck Driver Screen
class TruckDriverScreen extends StatefulWidget {
  @override
  _TruckDriverScreenState createState() => _TruckDriverScreenState();
}

class _TruckDriverScreenState extends State<TruckDriverScreen>
    with SingleTickerProviderStateMixin {
  late GoogleMapController mapController;
  late DriverProfile currentDriver;
  late List<DeliveryOrder> orders;
  late List<LeaderboardEntry> leaderboard;
  late List<TimeSlot> timeSlots;
  int _selectedIndex = 0;
  bool _isRefreshing = false;
  late AnimationController _animationController;
  Map<String, List<LatLng>> _polylinePoints = {};
  late Future<void> _loadStateFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _loadStateFuture = _loadState().catchError((e) {
      print('Error loading state: $e');
    });
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final driverJson = prefs.getString('driverProfile');
      final ordersJson = prefs.getString('orders');
      final leaderboardJson = prefs.getString('leaderboard');
      final timeSlotsJson = prefs.getString('timeSlots');
      final selectedIndex = prefs.getInt('selectedIndex') ?? 0;

      currentDriver = driverJson != null
          ? DriverProfile.fromJson(jsonDecode(driverJson))
          : TruckDriverDataGenerator.generateDriverProfile();
      orders = ordersJson != null
          ? (jsonDecode(ordersJson) as List)
              .map((e) => DeliveryOrder.fromJson(e))
              .toList()
          : List.generate(5, (index) => TruckDriverDataGenerator.generateRandomOrder());
      leaderboard = leaderboardJson != null
          ? (jsonDecode(leaderboardJson) as List)
              .map((e) => LeaderboardEntry.fromJson(e))
              .toList()
          : TruckDriverDataGenerator.generateLeaderboard();
      timeSlots = timeSlotsJson != null
          ? (jsonDecode(timeSlotsJson) as List)
              .map((e) => TimeSlot.fromJson(e))
              .toList()
          : TruckDriverDataGenerator.generateTimeSlots();
      _selectedIndex = selectedIndex;

      await _fetchPolylines();
    } catch (e) {
      print('Error loading data: $e');
      // Fallback to default data if loading fails
      currentDriver = TruckDriverDataGenerator.generateDriverProfile();
      orders = List.generate(5, (index) => TruckDriverDataGenerator.generateRandomOrder());
      leaderboard = TruckDriverDataGenerator.generateLeaderboard();
      timeSlots = TruckDriverDataGenerator.generateTimeSlots();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driverProfile', jsonEncode(currentDriver.toJson()));
    await prefs.setString('orders', jsonEncode(orders.map((e) => e.toJson()).toList()));
    await prefs.setString('leaderboard', jsonEncode(leaderboard.map((e) => e.toJson()).toList()));
    await prefs.setString('timeSlots', jsonEncode(timeSlots.map((e) => e.toJson()).toList()));
    await prefs.setInt('selectedIndex', _selectedIndex);
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    try {
      currentDriver = TruckDriverDataGenerator.generateDriverProfile();
      orders = List.generate(5, (index) => TruckDriverDataGenerator.generateRandomOrder());
      leaderboard = TruckDriverDataGenerator.generateLeaderboard();
      timeSlots = TruckDriverDataGenerator.generateTimeSlots();
      await _fetchPolylines();
    } catch (e) {
      print('Error refreshing data: $e');
    }
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
    await _saveState();
  }

  Future<void> _fetchPolylines() async {
    final polylinePoints = PolylinePoints();
    _polylinePoints.clear();

    for (var order in orders) {
      try {
        final result = await polylinePoints.getRouteBetweenCoordinates(
          'YOUR_API_KEY_HERE', // Replace with a valid Google Maps API key
          PointLatLng(order.originCoords.latitude, order.originCoords.longitude),
          PointLatLng(order.destinationCoords.latitude, order.destinationCoords.longitude),
        );

        if (result.points.isNotEmpty) {
          _polylinePoints[order.id] = result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        } else {
          _polylinePoints[order.id] = [order.originCoords, order.destinationCoords];
        }
      } catch (e) {
        print('Error fetching polyline for order ${order.id}: $e');
        _polylinePoints[order.id] = [order.originCoords, order.destinationCoords];
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      mapController = controller;
      controller.setMapStyle('''
        [
          {
            "elementType": "geometry",
            "stylers": [{"color": "#f5f5f5"}]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [{"color": "#616161"}]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [{"color": "#f5f5f5"}]
          },
          {
            "featureType": "road",
            "elementType": "geometry",
            "stylers": [{"color": "#ffffff"}]
          },
          {
            "featureType": "road",
            "elementType": "geometry.stroke",
            "stylers": [{"color": "#d3d3d3"}]
          },
          {
            "featureType": "water",
            "elementType": "geometry.fill",
            "stylers": [{"color": "#4fc3f7"}]
          }
        ]
      ''');
    } catch (e) {
      print('Error creating map: $e');
    }
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    try {
      markers.add(Marker(
        markerId: MarkerId('driver_${currentDriver.id}'),
        position: currentDriver.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: '${currentDriver.name} - ${currentDriver.vehicleNumber}',
        ),
      ));

      for (var order in orders) {
        markers.add(Marker(
          markerId: MarkerId('order_${order.id}'),
          position: order.destinationCoords,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            order.priority == 'High' ? BitmapDescriptor.hueRed :
            order.priority == 'Medium' ? BitmapDescriptor.hueOrange :
            BitmapDescriptor.hueGreen
          ),
          infoWindow: InfoWindow(
            title: order.destination,
            snippet: 'From: ${walmartLocations[walmartCoords.indexOf(order.originCoords)]}\nTo: ${order.productName} - ${order.distance.toStringAsFixed(1)} km',
          ),
        ));
      }
    } catch (e) {
      print('Error building markers: $e');
    }

    return markers;
  }

  Set<Polyline> _buildRoutes() {
    Set<Polyline> polylines = {};
    
    try {
      for (var order in orders) {
        final points = _polylinePoints[order.id] ?? [order.originCoords, order.destinationCoords];
        polylines.add(Polyline(
          polylineId: PolylineId('route_${order.id}'),
          points: points,
          color: order.priority == 'High' ? Colors.red :
                 order.priority == 'Medium' ? Colors.orange : Colors.green,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          geodesic: true,
        ));
      }
    } catch (e) {
      print('Error building routes: $e');
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadStateFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: SpinKitFadingCube(color: Colors.blue[600], size: 50));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading data. Please try again.'));
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('🚛 Driver Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.blue[800],
              elevation: 0,
              actions: [
                _isRefreshing
                    ? Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SpinKitFadingCircle(color: Colors.white, size: 24),
                      )
                    : IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _refreshData,
                      ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    // Add settings functionality
                  },
                ),
              ],
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[800]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            body: _isRefreshing
                ? Center(child: SpinKitFadingCube(color: Colors.blue[600], size: 50))
                : _buildBody(),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                FocusScope.of(context).unfocus();
                setState(() => _selectedIndex = index);
                _saveState();
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue[800],
              unselectedItemColor: Colors.grey[600],
              backgroundColor: Colors.white,
              elevation: 10,
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
                BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
                BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildBody() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: [
        _buildDashboard(),
        _buildMapView(),
        _buildTimeSlots(),
        _buildLeaderboard(),
      ][_selectedIndex],
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDriverInfoCard(),
          SizedBox(height: 16),
          _buildOrdersList(),
          SizedBox(height: 16),
          _buildCarbonFootprintCard(),
          SizedBox(height: 16),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blue[300]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Hero(
                  tag: 'driver_avatar',
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.blue[600]),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentDriver.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currentDriver.vehicleNumber,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      Text(
                        currentDriver.vehicleType,
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Rating', '⭐ ${currentDriver.rating.toStringAsFixed(1)}', Icons.star),
                _buildInfoItem('Deliveries', '${currentDriver.deliveriesCompleted}', Icons.local_shipping),
                _buildInfoItem('Time Slot', currentDriver.timeSlot, Icons.schedule),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned Orders',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.sort),
                  onPressed: () {
                    setState(() {
                      orders.sort((a, b) => a.priority.compareTo(b.priority));
                    });
                    _saveState();
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            ...orders.asMap().entries.map((entry) => _buildOrderItem(entry.value, entry.key)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(DeliveryOrder order, int index) {
    Color priorityColor = order.priority == 'High' ? Colors.red :
                         order.priority == 'Medium' ? Colors.orange : Colors.green;
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: priorityColor,
          child: Text(
            order.priority[0],
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(order.productName, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 From: ${walmartLocations[walmartCoords.indexOf(order.originCoords)]}'),
            Text('📍 To: ${order.destination}'),
            Text('📦 Qty: ${order.quantity} | 🏋️ ${order.weight.toStringAsFixed(1)} kg'),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: order.status == 'Delivered' ? Colors.green :
                   order.status == 'In Transit' ? Colors.blue : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            order.status,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distance: ${order.distance.toStringAsFixed(1)} km'),
                Text('Carbon Footprint: ${order.carbonFootprint.toStringAsFixed(1)} kg CO₂'),
                Text('Time Slot: ${order.timeSlot}'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedIndex = 1);
                    _saveState();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('View on Map'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarbonFootprintCard() {
    double totalCarbon = orders.fold(0.0, (sum, order) => sum + order.carbonFootprint);
    double savedCarbon = totalCarbon * 0.3;
    
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.green[300]!, Colors.green[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '🌱 Green Travel Impact',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCarbonItem('Total CO₂', '${totalCarbon.toStringAsFixed(1)} kg', Colors.red[300]!),
                _buildCarbonItem('Saved CO₂', '${savedCarbon.toStringAsFixed(1)} kg', Colors.green[300]!),
                _buildCarbonItem('Efficiency', '${(savedCarbon/totalCarbon*100).toStringAsFixed(1)}%', Colors.blue[300]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Active Orders', '${orders.where((o) => o.status != 'Delivered').length}', Icons.pending_actions),
                _buildStatItem('Total Distance', '${orders.fold(0.0, (sum, o) => sum + o.distance).toStringAsFixed(1)} km', Icons.route),
                _buildStatItem('Availability', currentDriver.isAvailable ? 'Available' : 'Busy', Icons.event_available),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue[600], size: 20),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: currentDriver.currentLocation,
            zoom: 10,
          ),
          markers: _buildMarkers(),
          polylines: _buildRoutes(),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          mapType: MapType.normal,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          compassEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: true,
          zoomGesturesEnabled: true,
          liteModeEnabled: false,
          buildingsEnabled: true,
          indoorViewEnabled: true,
          trafficEnabled: true,
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Route Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: orders.isNotEmpty ? orders[0].id : null,
                    items: orders.map((order) => DropdownMenuItem(
                      value: order.id,
                      child: Text('From ${walmartLocations[walmartCoords.indexOf(order.originCoords)]} to ${order.destination}'),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final order = orders.firstWhere((o) => o.id == value);
                        mapController.animateCamera(CameraUpdate.newLatLngBounds(
                          LatLngBounds(
                            southwest: LatLng(
                              min(order.originCoords.latitude, order.destinationCoords.latitude),
                              min(order.originCoords.longitude, order.destinationCoords.longitude),
                            ),
                            northeast: LatLng(
                              max(order.originCoords.latitude, order.destinationCoords.latitude),
                              max(order.originCoords.longitude, order.destinationCoords.longitude),
                            ),
                          ),
                          100,
                        ));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 Warehouse Schedule',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final slot = timeSlots[index];
                final isCurrentSlot = slot.time == currentDriver.timeSlot;
                
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: isCurrentSlot ? 10 : 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: isCurrentSlot
                          ? LinearGradient(colors: [Colors.blue[300]!, Colors.blue[600]!])
                          : LinearGradient(colors: [Colors.grey[100]!, Colors.grey[300]!]),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        slot.time,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isCurrentSlot ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      subtitle: Text(
                        'Capacity: ${slot.trucksAllocated}/${slot.maxCapacity}',
                        style: TextStyle(
                          color: isCurrentSlot ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: slot.trucksAllocated / slot.maxCapacity,
                                backgroundColor: isCurrentSlot ? Colors.white30 : Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCurrentSlot ? Colors.white : Colors.blue[600]!,
                                ),
                                minHeight: 8,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Assigned Drivers:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentSlot ? Colors.white : Colors.grey[800],
                                ),
                              ),
                              ...slot.driverNames.map((name) => Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 20, color: isCurrentSlot ? Colors.white70 : Colors.grey[600]),
                                    SizedBox(width: 8),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: isCurrentSlot ? Colors.white70 : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 Green Driver Leaderboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final entry = leaderboard[index];
                final isCurrentDriver = entry.driverName == currentDriver.name;
                
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  elevation: isCurrentDriver ? 10 : 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: isCurrentDriver
                          ? LinearGradient(colors: [Colors.green[300]!, Colors.green[600]!])
                          : LinearGradient(colors: [Colors.grey[100]!, Colors.grey[300]!]),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index < 3 
                            ? [Colors.amber, Colors.grey, Colors.orange][index]
                            : Colors.blue[300],
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        entry.driverName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrentDriver ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🌱 ${entry.carbonSaved.toStringAsFixed(1)} kg CO₂ saved',
                            style: TextStyle(
                              color: isCurrentDriver ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          Text(
                            '📦 ${entry.greenDeliveries} green deliveries',
                            style: TextStyle(
                              color: isCurrentDriver ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          Text(
                            '🚛 ${entry.vehicleType}',
                            style: TextStyle(
                              color: isCurrentDriver ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentDriver ? Colors.white : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⭐ ${entry.rating.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: isCurrentDriver ? Colors.green[600] : Colors.grey[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}