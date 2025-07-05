import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AuctionPage extends StatefulWidget {
  const AuctionPage({Key? key}) : super(key: key);

  @override
  _AuctionPageState createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = ['All', 'Active', 'Closed', 'Pending'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Live Auctions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {}); // Refresh the page
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(
              child: _buildTenderGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B).withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A).withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.5)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search tenders...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64B5F6)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _filterStatus == status;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filterStatus = status;
                      });
                    },
                    backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.5),
                    selectedColor: const Color(0xFF4A90E2),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF64B5F6),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('tenders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No tenders available',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        final tenders = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Filter by status
          bool statusMatch = _filterStatus == 'All' || 
                           (data['status'] ?? 'Active') == _filterStatus;
          
          // Filter by search query
          bool searchMatch = _searchQuery.isEmpty ||
                           (data['item'] ?? '').toLowerCase().contains(_searchQuery) ||
                           (data['category'] ?? '').toLowerCase().contains(_searchQuery) ||
                           (data['tenderId'] ?? '').toLowerCase().contains(_searchQuery);
          
          return statusMatch && searchMatch;
        }).toList();

        if (tenders.isEmpty) {
          return const Center(
            child: Text(
              'No tenders match your search criteria',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: tenders.length,
          itemBuilder: (context, index) {
            final tender = tenders[index];
            final data = tender.data() as Map<String, dynamic>;
            return _buildTenderCard(tender.id, data);
          },
        );
      },
    );
  }

  Widget _buildTenderCard(String tenderId, Map<String, dynamic> data) {
    final DateTime? deadline = data['tenderDeadline'] != null 
        ? DateTime.parse(data['tenderDeadline'])
        : null;
    
    final DateTime? openingTime = data['openingTime'] != null
        ? DateTime.parse(data['openingTime'])
        : null;

    final bool isActive = deadline != null && DateTime.now().isBefore(deadline);
    final bool hasStarted = openingTime != null && DateTime.now().isAfter(openingTime);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1B263B),
      child: InkWell(
        onTap: () => _showTenderDetails(tenderId, data),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? const Color(0xFF4CAF50) : const Color(0xFF4A90E2),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF4CAF50) : const Color(0xFF4A90E2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data['tenderId'] ?? 'Unknown ID',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'CLOSED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item and Category
                      Text(
                        data['item'] ?? 'Unknown Item',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['category'] ?? 'Unknown Category',
                        style: TextStyle(
                          color: const Color(0xFF64B5F6).withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Quantity
                      if (data['quantity'] != null)
                        _buildInfoRow(Icons.inventory, 'Qty: ${data['quantity']}'),
                      
                      // Current highest bid
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('bids')
                            .where('tenderId', isEqualTo: tenderId)
                            .orderBy('bidAmount', descending: true)
                            .limit(1)
                            .snapshots(),
                        builder: (context, bidSnapshot) {
                          if (bidSnapshot.hasData && bidSnapshot.data!.docs.isNotEmpty) {
                            final highestBid = bidSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            return _buildInfoRow(
                              Icons.monetization_on,
                              'Highest: \$${highestBid['bidAmount']}',
                              color: const Color(0xFF4CAF50),
                            );
                          }
                          return _buildInfoRow(
                            Icons.monetization_on,
                            'No bids yet',
                            color: Colors.orange,
                          );
                        },
                      ),
                      
                      const Spacer(),
                      
                      // Deadline countdown
                      if (deadline != null)
                        _buildCountdown(deadline),
                      
                      const SizedBox(height: 8),
                      
                      // Bid button
                      if (isActive && hasStarted)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showBidDialog(tenderId, data),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Place Bid'),
                          ),
                        )
                      else if (!hasStarted)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Not Started'),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Closed'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? const Color(0xFF64B5F6),
            size: 16,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(DateTime deadline) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final difference = deadline.difference(now);
        
        if (difference.isNegative) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'EXPIRED',
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        
        final days = difference.inDays;
        final hours = difference.inHours % 24;
        final minutes = difference.inMinutes % 60;
        final seconds = difference.inSeconds % 60;
        
        String countdown;
        if (days > 0) {
          countdown = '${days}d ${hours}h ${minutes}m';
        } else if (hours > 0) {
          countdown = '${hours}h ${minutes}m ${seconds}s';
        } else {
          countdown = '${minutes}m ${seconds}s';
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            countdown,
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  void _showBidDialog(String tenderId, Map<String, dynamic> tenderData) {
    final TextEditingController bidController = TextEditingController();
    final TextEditingController bidderNameController = TextEditingController();
    final TextEditingController bidderEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('bids')
              .where('tenderId', isEqualTo: tenderId)
              .orderBy('bidAmount', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            double? currentHighestBid;
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              currentHighestBid = snapshot.data!.docs.first.data() as Map<String, dynamic>?
                  ?['bidAmount']?.toDouble();
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1B263B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Place Bid - ${tenderData['item']}',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentHighestBid != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Current Highest Bid: \$${currentHighestBid!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No bids yet - Be the first!',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: bidderNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        labelStyle: const TextStyle(color: Color(0xFF64B5F6)),
                        filled: true,
                        fillColor: const Color(0xFF0D1B2A).withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: bidderEmailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Your Email',
                        labelStyle: const TextStyle(color: Color(0xFF64B5F6)),
                        filled: true,
                        fillColor: const Color(0xFF0D1B2A).withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: bidController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Your Bid Amount (\$)',
                        labelStyle: const TextStyle(color: Color(0xFF64B5F6)),
                        filled: true,
                        fillColor: const Color(0xFF0D1B2A).withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF4A90E2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 2),
                        ),
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF64B5F6)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _placeBid(
                      tenderId,
                      bidController.text,
                      bidderNameController.text,
                      bidderEmailController.text,
                      currentHighestBid,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Place Bid'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _placeBid(String tenderId, String bidAmount, String bidderName, String bidderEmail, double? currentHighestBid) async {
    if (bidAmount.isEmpty || bidderName.isEmpty || bidderEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double? bidValue = double.tryParse(bidAmount);
    if (bidValue == null || bidValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid bid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentHighestBid != null && bidValue <= currentHighestBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bid must be higher than current highest bid (\$${currentHighestBid.toStringAsFixed(2)})'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('bids').add({
        'tenderId': tenderId,
        'bidAmount': bidValue,
        'bidderName': bidderName,
        'bidderEmail': bidderEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing bid: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTenderDetails(String tenderId, Map<String, dynamic> tenderData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1B263B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A90E2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Tender Details',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic Info
                        _buildDetailSection('Basic Information', [
                          _buildDetailRow('Tender ID', tenderData['tenderId'] ?? 'N/A'),
                          _buildDetailRow('Item', tenderData['item'] ?? 'N/A'),
                          _buildDetailRow('Category', tenderData['category'] ?? 'N/A'),
                          _buildDetailRow('Quantity', tenderData['quantity'] ?? 'N/A'),
                          _buildDetailRow('Auction Type', tenderData['auctionType'] ?? 'N/A'),
                          _buildDetailRow('Status', tenderData['status'] ?? 'N/A'),
                        ]),
                        
                        const SizedBox(height: 16),
                        
                        // Timing Info
                        _buildDetailSection('Timing Information', [
                          _buildDetailRow('Opening Time', 
                            tenderData['openingTime'] != null 
                              ? DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.parse(tenderData['openingTime']))
                              : 'N/A'),
                          _buildDetailRow('Deadline', 
                            tenderData['tenderDeadline'] != null 
                              ? DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.parse(tenderData['tenderDeadline']))
                              : 'N/A'),
                        ]),
                        
                        const SizedBox(height: 16),
                        
                        // Delivery Info
                        _buildDetailSection('Delivery Information', [
                          _buildDetailRow('Timeline', tenderData['deliveryTimeline'] ?? 'N/A'),
                          _buildDetailRow('Location', tenderData['deliveryLocation'] ?? 'N/A'),
                          _buildDetailRow('Packaging', tenderData['packagingRequirements'] ?? 'N/A'),
                          _buildDetailRow('Special Handling', tenderData['specialHandling'] ?? 'N/A'),
                        ]),
                        
                        const SizedBox(height: 16),
                        
                        // Bidding History
                        _buildBiddingHistory(tenderId),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64B5F6),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiddingHistory(String tenderId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('bids')
          .where('tenderId', isEqualTo: tenderId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
            ),
          );
        }

        final bids = snapshot.data!.docs;
        
        if (bids.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
            ),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bidding History',
                  style: TextStyle(
                    color: Color(0xFF64B5F6),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'No bids yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bidding History',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...bids.asMap().entries.map((entry) {
                final index = entry.key;
                final bid = entry.value;
                final bidData = bid.data() as Map<String, dynamic>;
                final timestamp = bidData['timestamp'] as Timestamp?;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: index == 0 ? const Color(0xFF4CAF50).withOpacity(0.2) : const Color(0xFF1B263B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: index == 0 ? const Color(0xFF4CAF50) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bidData['bidderName'] ?? 'Anonymous',
                              style: TextStyle(
                                color: index == 0 ? const Color(0xFF4CAF50) : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (timestamp != null)
                              Text(
                                DateFormat('MMM dd, HH:mm').format(timestamp.toDate()),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (index == 0)
                            const Icon(
                              Icons.star,
                              color: Color(0xFF4CAF50),
                              size: 16,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            '\$${bidData['bidAmount']?.toStringAsFixed(2) ?? '0.00'}',
                            style: TextStyle(
                              color: index == 0 ? const Color(0xFF4CAF50) : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}