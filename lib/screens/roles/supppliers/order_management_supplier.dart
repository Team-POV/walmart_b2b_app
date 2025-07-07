import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';

class OrderManagementSupplier extends StatefulWidget {
  @override
  _OrderManagementSupplierState createState() => _OrderManagementSupplierState();
}

class _OrderManagementSupplierState extends State<OrderManagementSupplier> {
  List<Order> orders = [];
  List<Order> filteredOrders = [];
  List<TimeSlot> timeSlots = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedStatusFilter = 'All';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateRandomData();
    searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _generateRandomData() {
    setState(() {
      isLoading = true; // Set loading to true when data generation starts
    });
    Timer(Duration(seconds: 2), () {
      setState(() {
        orders = _generateRandomOrders();
        timeSlots = _generateTimeSlots();
        filteredOrders = orders;
        isLoading = false;
      });
    });
  }

  List<Order> _generateRandomOrders() {
    final random = Random();
    final products = ['Electronics', 'Groceries', 'Clothing', 'Home & Garden', 'Sports'];
    final warehouses = [
      'Walmart Bangalore Hub',
      'Walmart Mumbai Center',
      'Walmart Delhi North',
      'Walmart Chennai South',
      'Walmart Hyderabad East'
    ];
    final customers = ['Rajesh Kumar', 'Priya Sharma', 'Amit Singh', 'Deepika Reddy', 'Sandeep Mehta'];

    List<Order> generatedOrders = [];

    for (int i = 0; i < 20; i++) {
      generatedOrders.add(Order(
        id: 'ORD${1000 + i}',
        productCategory: products[random.nextInt(products.length)],
        quantity: random.nextInt(50) + 10,
        warehouse: warehouses[random.nextInt(warehouses.length)],
        priority: random.nextInt(3) == 0 ? 'High' : random.nextInt(2) == 0 ? 'Medium' : 'Low',
        status: random.nextInt(4) == 0 ? 'Pending' : random.nextInt(3) == 0 ? 'In Transit' : random.nextInt(2) == 0 ? 'Delivered' : 'Processing',
        estimatedDelivery: DateTime.now().add(Duration(days: random.nextInt(7) + 1)),
        tenderHoldingYears: random.nextInt(5) + 1,
        carbonFootprint: (random.nextDouble() * 50 + 10).toStringAsFixed(1),
        orderDetails: 'Details for order ORD${1000 + i}: Contains various items in ${products[random.nextInt(products.length)]} category. Customer: ${customers[random.nextInt(customers.length)]}.',
        isExpanded: false,
      ));
    }
    return generatedOrders;
  }

  List<TimeSlot> _generateTimeSlots() {
    final random = Random();
    final drivers = ['Driver A', 'Driver B', 'Driver C', 'Driver D', 'Driver E'];
    final vehicleTypes = ['Truck', 'Van', 'Motorcycle'];
    final warehouses = [
      'Walmart Bangalore Hub',
      'Walmart Mumbai Center',
      'Walmart Delhi North',
      'Walmart Chennai South',
      'Walmart Hyderabad East'
    ];
    List<TimeSlot> slots = [];

    for (int i = 0; i < 10; i++) {
      slots.add(TimeSlot(
        id: 'SLOT${100 + i}',
        timeRange: '${8 + i * 1}:00 - ${9 + i * 1}:00', // More granular time slots
        driverName: drivers[random.nextInt(drivers.length)],
        isAvailable: random.nextBool(),
        warehouse: warehouses[random.nextInt(warehouses.length)],
        estimatedUnloadTime: '${30 + random.nextInt(30)} mins',
        assignedOrdersCount: random.nextInt(5), // New: Number of orders assigned
        vehicleType: vehicleTypes[random.nextInt(vehicleTypes.length)], // New: Vehicle type
        capacity: '${random.nextInt(10) + 5} tons', // New: Capacity
      ));
    }
    return slots;
  }

  void _filterOrders() {
    setState(() {
      searchQuery = searchController.text.toLowerCase();
      filteredOrders = orders.where((order) {
        final matchesSearch = order.id.toLowerCase().contains(searchQuery) ||
            order.productCategory.toLowerCase().contains(searchQuery) ||
            order.warehouse.toLowerCase().contains(searchQuery);
        final matchesStatus = selectedStatusFilter == 'All' || order.status == selectedStatusFilter;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Supplier Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo.shade700, // Changed app bar color
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _generateRandomData();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade700),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _generateRandomData();
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search orders by ID, category, or warehouse...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300), // Added subtle border
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.indigo.shade700, width: 2), // Focused border color
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Status Filter
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300), // Added subtle border
                      ),
                      child: DropdownButtonHideUnderline( // Hides the default underline
                        child: DropdownButton<String>(
                          value: selectedStatusFilter,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.indigo.shade700), // Custom dropdown icon
                          items: ['All', 'Pending', 'Processing', 'In Transit', 'Delivered']
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: TextStyle(color: Colors.grey.shade800),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedStatusFilter = value!;
                              _filterOrders();
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Dashboard Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 16.0, // horizontal space between cards
                          runSpacing: 16.0, // vertical space between lines of cards
                          children: [
                            _buildDashboardCard(
                              'Total Orders',
                              '${orders.length}',
                              Icons.shopping_cart,
                              Colors.indigo.shade700,
                              constraints.maxWidth / 2 - 8, // Half width minus spacing
                            ),
                            _buildDashboardCard(
                              'Pending',
                              '${orders.where((o) => o.status == 'Pending').length}',
                              Icons.pending_actions, // Changed icon
                              Colors.orange.shade600,
                              constraints.maxWidth / 2 - 8,
                            ),
                            _buildDashboardCard(
                              'In Transit',
                              '${orders.where((o) => o.status == 'In Transit').length}',
                              Icons.local_shipping,
                              Colors.purple.shade600,
                              constraints.maxWidth / 2 - 8,
                            ),
                            _buildDashboardCard(
                              'Delivered',
                              '${orders.where((o) => o.status == 'Delivered').length}',
                              Icons.check_circle,
                              Colors.green.shade600,
                              constraints.maxWidth / 2 - 8,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 24),

                    // Time Slots Section
                    Text(
                      'Available Loading Bay Slots', // More specific title
                      style: TextStyle(
                        fontSize: 22, // Larger font size
                        fontWeight: FontWeight.w700, // Bolder font weight
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      height: 250, // Increased height for more content
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: timeSlots.length,
                        itemBuilder: (context, index) {
                          final slot = timeSlots[index];
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: 250, // Increased width
                            margin: EdgeInsets.only(right: 16), // Increased margin
                            child: Card(
                              elevation: 7, // Higher elevation
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16), // More rounded corners
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16), // Increased padding
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          slot.timeRange,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700, // Bolder time
                                            fontSize: 18, // Larger time font
                                            color: Colors.indigo.shade800, // Darker color
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: slot.isAvailable ? Colors.green.shade600 : Colors.red.shade600,
                                            borderRadius: BorderRadius.circular(16), // More rounded status
                                          ),
                                          child: Text(
                                            slot.isAvailable ? 'Available' : 'Occupied',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12), // Increased spacing
                                    _buildTimeSlotDetailRow(Icons.person, 'Driver:', slot.driverName),
                                    _buildTimeSlotDetailRow(Icons.warehouse, 'Warehouse:', slot.warehouse),
                                    _buildTimeSlotDetailRow(Icons.access_time, 'Unload Time:', slot.estimatedUnloadTime),
                                    _buildTimeSlotDetailRow(Icons.assignment, 'Orders:', '${slot.assignedOrdersCount}'), // New detail
                                    _buildTimeSlotDetailRow(Icons.local_shipping_outlined, 'Vehicle Type:', slot.vehicleType), // New detail
                                    _buildTimeSlotDetailRow(Icons.scale, 'Capacity:', slot.capacity), // New detail
                                    Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: slot.isAvailable
                                            ? () {
                                                _assignSlot(slot);
                                              }
                                            : null,
                                        child: Text(
                                          slot.isAvailable ? 'Assign Slot' : 'Fully Booked', // Changed button text
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: slot.isAvailable ? Colors.indigo.shade700 : Colors.grey.shade400,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10), // Rounded button
                                          ),
                                          padding: EdgeInsets.symmetric(vertical: 12), // Taller button
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 24),

                    // Orders List
                    Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return AnimatedSize(
                          duration: Duration(milliseconds: 300),
                          child: Card(
                            elevation: 4, // Slightly higher elevation
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16), // More rounded corners
                            ),
                            margin: EdgeInsets.only(bottom: 16), // Increased bottom margin
                            child: Padding(
                              padding: EdgeInsets.all(18), // Increased padding
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        order.id,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700, // Bolder ID
                                          fontSize: 18, // Larger ID font
                                          color: Colors.indigo.shade800,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            order.isExpanded = !order.isExpanded;
                                          });
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(order.status),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            order.status,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10), // Increased spacing
                                  _buildOrderInfoRow(Icons.category, order.productCategory, '${order.quantity} units'),
                                  _buildOrderInfoRow(Icons.location_on, order.warehouse, ''),
                                  _buildOrderInfoRow(Icons.schedule, 'Tender:', '${order.tenderHoldingYears} years'),
                                  _buildOrderInfoRow(Icons.eco, 'Carbon Footprint:', '${order.carbonFootprint} kg CO2'),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getPriorityColor(order.priority),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          order.priority,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Spacer(),
                                      Text(
                                        'Est. Delivery: ${DateFormat('dd/MM/yyyy').format(order.estimatedDelivery)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (order.isExpanded) ...[
                                    SizedBox(height: 16), // Increased spacing
                                    Divider(color: Colors.grey.shade300), // Lighter divider
                                    SizedBox(height: 16),
                                    Text(
                                      'Order Details:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      order.orderDetails,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon( // Changed to ElevatedButton.icon
                                          onPressed: () {
                                            _showOrderActionDialog(order);
                                          },
                                          icon: Icon(Icons.settings, size: 18, color: Colors.white), // Icon for action
                                          label: Text(
                                            'Take Action',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.indigo.shade600,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDashboardCard(String title, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 6, // Increased elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // More rounded corners
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
            children: [
              Align(
                alignment: Alignment.topRight, // Icon at top right
                child: Icon(icon, size: 36, color: color), // Larger icon
              ),
              SizedBox(height: 8), // Adjusted spacing
              Text(
                value,
                style: TextStyle(
                  fontSize: 28, // Larger value font
                  fontWeight: FontWeight.w800, // Extra bold
                  color: color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700, // Slightly darker grey
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0), // Consistent spacing
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Text(
            '$label ',
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
          ),
          if (value.isNotEmpty)
            Text(
              ' ($value)',
              style: TextStyle(color: Colors.grey.shade700),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade600;
      case 'Processing':
        return Colors.blue.shade600;
      case 'In Transit':
        return Colors.purple.shade600;
      case 'Delivered':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red.shade600;
      case 'Medium':
        return Colors.orange.shade600;
      case 'Low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _assignSlot(TimeSlot slot) {
    setState(() {
      slot.isAvailable = false;
      // In a real application, you would typically assign an order to this slot
      // For this example, we'll just mark it as occupied.
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Time slot ${slot.timeRange} assigned successfully!'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16), // Margin for floating snackbar
      ),
    );
  }

  void _showOrderActionDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text('Actions for Order ${order.id}'), // More descriptive title
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.indigo.shade700),
              title: Text('Edit Order Details'),
              onTap: () {
                Navigator.pop(context);
                // Implement edit functionality - e.g., navigate to an edit screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Edit functionality for Order ${order.id} not implemented yet.'),
                    backgroundColor: Colors.blue.shade400,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.all(16),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.red.shade600),
              title: Text('Cancel Order'),
              onTap: () {
                Navigator.pop(context);
                _cancelOrder(order);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(Order order) {
    setState(() {
      orders.removeWhere((o) => o.id == order.id); // Remove from original list
      filteredOrders.removeWhere((o) => o.id == order.id); // Remove from filtered list
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order.id} cancelled successfully!'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}

class Order {
  final String id;
  final String productCategory;
  final int quantity;
  final String warehouse;
  final String priority;
  final String status;
  final DateTime estimatedDelivery;
  final int tenderHoldingYears;
  final String carbonFootprint;
  final String orderDetails;
  bool isExpanded;

  Order({
    required this.id,
    required this.productCategory,
    required this.quantity,
    required this.warehouse,
    required this.priority,
    required this.status,
    required this.estimatedDelivery,
    required this.tenderHoldingYears,
    required this.carbonFootprint,
    required this.orderDetails,
    this.isExpanded = false,
  });
}

class TimeSlot {
  final String id;
  final String timeRange;
  final String driverName;
  bool isAvailable;
  final String warehouse;
  final String estimatedUnloadTime;
  final int assignedOrdersCount; // New field
  final String vehicleType; // New field
  final String capacity; // New field

  TimeSlot({
    required this.id,
    required this.timeRange,
    required this.driverName,
    required this.isAvailable,
    required this.warehouse,
    required this.estimatedUnloadTime,
    required this.assignedOrdersCount,
    required this.vehicleType,
    required this.capacity,
  });
}