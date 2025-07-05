import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

// --- TenderCard Widget ---
class TenderCard extends StatefulWidget {
  final Map<String, dynamic> tenderData;
  final String tenderId;
  final String selectedTenderStatus;
  final Function(BuildContext, Map<String, dynamic>) showTenderDetails;
  final Function(BuildContext, String, String?) showBidDialog;

  const TenderCard({
    Key? key,
    required this.tenderData,
    required this.tenderId,
    required this.selectedTenderStatus,
    required this.showTenderDetails,
    required this.showBidDialog,
  }) : super(key: key);

  @override
  _TenderCardState createState() => _TenderCardState();
}

class _TenderCardState extends State<TenderCard> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _cardTimer;
  String _remainingTime = 'Loading...';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant TenderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenderData['tenderDeadline'] != widget.tenderData['tenderDeadline']) {
      _cardTimer?.cancel();
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _updateRemainingTime();
    _cardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateRemainingTime();
        });
      }
    });
  }

  void _updateRemainingTime() {
    _remainingTime = _getRemainingTime(widget.tenderData['tenderDeadline']);
  }

  String _getRemainingTime(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final DateTime deadline = DateTime.parse(isoString);
      final Duration remaining = deadline.difference(DateTime.now());

      if (remaining.isNegative) {
        return 'Tender Closed';
      }

      String twoDigits(int n) => n.toString().padLeft(2, '0');
      String days = remaining.inDays > 0 ? '${remaining.inDays}d ' : '';
      String hours = twoDigits(remaining.inHours.remainder(24));
      String minutes = twoDigits(remaining.inMinutes.remainder(60));
      String seconds = twoDigits(remaining.inSeconds.remainder(60));

      return '$days$hours:$minutes:$seconds remaining';
    } catch (e) {
      return 'Invalid Time';
    }
  }

  Future<Map<String, dynamic>?> _getCurrentWinningBid(String tenderId, String? auctionType) async {
    try {
      final bidsSnapshot = await _firestore
          .collection('tenders')
          .doc(tenderId)
          .collection('bids')
          .orderBy('bidAmount', descending: auctionType != 'Lowest Bidder Wins')
          .limit(1)
          .get();

      if (bidsSnapshot.docs.isNotEmpty) {
        return bidsSnapshot.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting winning bid: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _cardTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenderData = widget.tenderData;
    final tenderId = widget.tenderId;
    final auctionType = tenderData['auctionType'];
    final companyName = tenderData['companyName'] ?? 'Walmart';
    final licenseDuration = tenderData['licenseDuration'] ?? 'N/A';
    final baseBudget = tenderData['baseBudget'] ?? 'N/A';
    final pricingType = tenderData['pricingType'] ?? 'N/A';

    final bool isTenderClosed = _remainingTime == 'Tender Closed' || widget.selectedTenderStatus == 'Completed';

    return GestureDetector(
      onTap: () => widget.showTenderDetails(context, tenderData),
      child: Card(
        color: const Color(0xFF1B263B),
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: auctionType == 'Lowest Bidder Wins' ? Colors.redAccent.withOpacity(0.8) : const Color(0xFF4A90E2).withOpacity(0.6),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        '$companyName for ${tenderData['category']} Tender (${licenseDuration})',
                        style: const TextStyle(
                          color: Color(0xFF64B5F6),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Tender ID: ${tenderData['tenderId']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(auctionType ?? 'Auction', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    backgroundColor: const Color(0xFF0D1B2A).withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Item: ${tenderData['item']} (${tenderData['quantity']})',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Delivery: ${tenderData['deliveryLocation']}',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              Text(
                'Base Budget: ${baseBudget}',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              Text(
                'Pricing Type: ${pricingType}',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              const Divider(color: Colors.white30, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (auctionType == 'Lowest Bidder Wins')
                        const Text(
                          'Lowest Bid Wins!',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      const SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('tenders')
                            .doc(tenderId)
                            .collection('bids')
                            .orderBy('bidAmount', descending: auctionType != 'Lowest Bidder Wins')
                            .limit(1)
                            .snapshots(),
                        builder: (context, bidSnapshot) {
                          String currentBidInfo = 'No bids yet';
                          Color bidInfoColor = Colors.grey;

                          if (bidSnapshot.connectionState == ConnectionState.waiting) {
                            currentBidInfo = 'Loading bids...';
                          } else if (bidSnapshot.hasData && bidSnapshot.data!.docs.isNotEmpty) {
                            final winningBid = bidSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            final bidAmountDisplay = double.tryParse(winningBid['bidAmount']?.toString() ?? '0.0') ?? 0.0;
                            currentBidInfo = '${auctionType == 'Lowest Bidder Wins' ? 'Lowest' : 'Highest'} Bid: \$${bidAmountDisplay.toStringAsFixed(2)} by ${winningBid['bidderName']}';
                            bidInfoColor = Colors.greenAccent;
                          }

                          return Text(
                            currentBidInfo,
                            style: TextStyle(
                              color: bidInfoColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Deadline:',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        _remainingTime,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!isTenderClosed)
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.showBidDialog(context, tenderId, auctionType),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 5,
                    ),
                    icon: const Icon(Icons.gavel),
                    label: const Text(
                      'Place Bid',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

// --- Main BiddingSuppier Widget ---
class BiddingSuppier extends StatefulWidget {
  const BiddingSuppier({Key? key}) : super(key: key);

  @override
  _BiddingSuppierState createState() => _BiddingSuppierState();
}

class _BiddingSuppierState extends State<BiddingSuppier> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _bidAmountController = TextEditingController();
  final TextEditingController _perUnitPriceController = TextEditingController();
  final TextEditingController _siUnitController = TextEditingController();

  String _selectedTenderStatus = 'Active';
  String? _currentCompanyName;

  @override
  void initState() {
    super.initState();
    _updateTenderStatuses();
    _fetchCompanyName();
  }

  @override
  void dispose() {
    _bidAmountController.dispose();
    _perUnitPriceController.dispose();
    _siUnitController.dispose();
    super.dispose();
  }

  Future<void> _fetchCompanyName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _currentCompanyName = userDoc.data()?['name'] ?? 'Unknown Company';
          });
        } else {
          setState(() {
            _currentCompanyName = 'Unknown Company';
          });
          print('No user document found for UID: ${user.uid}');
        }
      } catch (e) {
        setState(() {
          _currentCompanyName = 'Unknown Company';
        });
        print('Error fetching company name: $e');
      }
    } else {
      setState(() {
        _currentCompanyName = 'Not Logged In';
      });
      print('No authenticated user found');
    }
  }

  Future<void> _updateTenderStatuses() async {
    try {
      final activeTendersSnapshot = await _firestore
          .collection('tenders')
          .where('status', isEqualTo: 'Active')
          .get();

      for (var doc in activeTendersSnapshot.docs) {
        final tenderData = doc.data();
        final deadlineString = tenderData['tenderDeadline'] as String?;
        if (deadlineString != null) {
          final DateTime deadline = DateTime.parse(deadlineString);
          if (deadline.isBefore(DateTime.now())) {
            await _firestore.collection('tenders').doc(doc.id).update({'status': 'Completed'});
            print('Tender ${doc.id} moved to Completed status.');
          }
        }
      }
    } catch (e) {
      print('Error updating tender statuses: $e');
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'Not set';
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildDetailTable(Map<String, dynamic> tenderData) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
      },
      children: [
        _buildDetailTableRow('Company', tenderData['companyName'] ?? 'N/A'),
        _buildDetailTableRow('Auction Type', tenderData['auctionType']),
        _buildDetailTableRow('Category', tenderData['category']),
        _buildDetailTableRow('Item', tenderData['item']),
        _buildDetailTableRow('Quantity', tenderData['quantity']),
        _buildDetailTableRow('Delivery Timeline', tenderData['deliveryTimeline']),
        _buildDetailTableRow('Delivery Location', tenderData['deliveryLocation']),
        _buildDetailTableRow('Base Budget', tenderData['baseBudget'] ?? 'Not specified'),
        _buildDetailTableRow('Pricing Type', tenderData['pricingType']),
        _buildDetailTableRow('Payment Terms', tenderData['paymentTerms']),
        _buildDetailTableRow('Taxes', tenderData['taxes']),
        _buildDetailTableRow('Packaging', tenderData['packagingRequirements']),
        _buildDetailTableRow('Special Handling', tenderData['specialHandling']),
        _buildDetailTableRow('License Duration', tenderData['licenseDuration']),
        _buildDetailTableRow('Penalty Clauses', tenderData['penaltyClauses']),
        _buildDetailTableRow('Insurance', tenderData['insuranceRequirement']),
        _buildDetailTableRow('Carbon Footprint Bonus', tenderData['carbonFootprintBonus'].toString()),
        _buildDetailTableRow('Tender Deadline', _formatDateTime(tenderData['tenderDeadline'])),
        _buildDetailTableRow('Opening Time', _formatDateTime(tenderData['openingTime'])),
        _buildDetailTableRow('Status', tenderData['status']),
      ],
    );
  }

  TableRow _buildDetailTableRow(String label, String? value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '$label:',
            style: const TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            value ?? 'Not specified',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildBidsList(String tenderId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('tenders')
          .doc(tenderId)
          .collection('bids')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF64B5F6)));
        }
        if (snapshot.hasError) {
          return const Text(
            'Error loading bids',
            style: TextStyle(color: Colors.redAccent),
          );
        }
        final bids = snapshot.data?.docs ?? [];
        if (bids.isEmpty) {
          return const Text(
            'No bids yet. Be the first!',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          );
        }
        return Column(
          children: bids.map((bid) {
            final bidData = bid.data() as Map<String, dynamic>;
            final bidStatus = bidData['status'] ?? 'Active';
            Color statusColor;
            IconData statusIcon;

            switch (bidStatus) {
              case 'Winning':
                statusColor = Colors.greenAccent;
                statusIcon = Icons.military_tech;
                break;
              case 'Lost':
                statusColor = Colors.redAccent;
                statusIcon = Icons.r_mobiledata_outlined;
                break;
              default:
                statusColor = Colors.orangeAccent;
                statusIcon = Icons.info;
            }

            final bidAmountDisplay = double.tryParse(bidData['bidAmount']?.toString() ?? '0.0') ?? 0.0;
            final perUnitPriceDisplay = double.tryParse(bidData['perUnitPrice']?.toString() ?? '0.0') ?? 0.0;

            return Card(
              color: const Color(0xFF0D1B2A).withOpacity(0.4),
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: Icon(statusIcon, color: statusColor, size: 20),
                title: Text(
                  'Bidder: ${bidData['bidderName']}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Amount: \$${bidAmountDisplay.toStringAsFixed(2)} | Per Unit: \$${perUnitPriceDisplay.toStringAsFixed(2)} ${bidData['siUnit'] ?? ''}\nStatus: $bidStatus | Placed: ${_formatDateTime(bidData['createdAt']?.toDate().toString())}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                trailing: Text(
                  '\$${bidAmountDisplay.toStringAsFixed(2)}',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showBidDialog(BuildContext context, String tenderId, String? auctionType) {
    final String currentBidderName = _currentCompanyName ?? "Your Company Name";

    _bidAmountController.clear();
    _perUnitPriceController.clear();
    _siUnitController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Place Your Bid',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Bidding as: $currentBidderName',
                    style: const TextStyle(color: Color(0xFF64B5F6), fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              TextFormField(
                controller: _bidAmountController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Your Total Bid Amount',
                  labelStyle: const TextStyle(color: Color(0xFF64B5F6)),
                  hintText: 'e.g., 1000.00',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF0D1B2A).withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: const Color(0xFF4A90E2).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter bid amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _perUnitPriceController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Your Per Unit Price',
                  labelStyle: const TextStyle(color: Color(0xFF64B5F6)),
                  hintText: 'e.g., 10.50',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF0D1B2A).withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: const Color(0xFF4A90E2).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter per unit price';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _siUnitController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'SI Unit (e.g., Kg, Litre, Pcs)',
                  labelStyle: const TextStyle(color: Color(0xFF64B5F6)),
                  hintText: 'e.g., Kg',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF0D1B2A).withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: const Color(0xFF4A90E2).withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter SI unit' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_bidAmountController.text.isNotEmpty &&
                  _perUnitPriceController.text.isNotEmpty &&
                  _siUnitController.text.isNotEmpty) {
                try {
                  final bidAmount = double.parse(_bidAmountController.text);
                  final perUnitPrice = double.parse(_perUnitPriceController.text);
                  final siUnit = _siUnitController.text;

                  if (bidAmount <= 0 || perUnitPrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bid amounts must be greater than 0'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final tenderDoc = await _firestore.collection('tenders').doc(tenderId).get();
                  final tenderData = tenderDoc.data() as Map<String, dynamic>;
                  final baseBudget = double.tryParse(tenderData['baseBudget']?.toString() ?? '0.0') ?? 0.0;

                  if (auctionType == 'Lowest Bidder Wins' && baseBudget != 0.0 && bidAmount > baseBudget) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Your total bid exceeds the base budget for this lowest bid auction.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newBidRef = await _firestore
                      .collection('tenders')
                      .doc(tenderId)
                      .collection('bids')
                      .add({
                    'bidderName': currentBidderName,
                    'bidAmount': bidAmount,
                    'perUnitPrice': perUnitPrice,
                    'siUnit': siUnit,
                    'createdAt': FieldValue.serverTimestamp(),
                    'status': 'Active',
                  });

                  final bidsSnapshot = await _firestore
                      .collection('tenders')
                      .doc(tenderId)
                      .collection('bids')
                      .get();

                  double? bestBidAmount;
                  String? bestBidId;

                  if (auctionType == 'Lowest Bidder Wins') {
                    for (var bidDoc in bidsSnapshot.docs) {
                      final bidData = bidDoc.data();
                      final currentBidAmount = double.tryParse(bidData['bidAmount']?.toString() ?? '0.0') ?? 0.0;
                      if (bestBidAmount == null || currentBidAmount < bestBidAmount) {
                        bestBidAmount = currentBidAmount;
                        bestBidId = bidDoc.id;
                      }
                    }
                  } else {
                    for (var bidDoc in bidsSnapshot.docs) {
                      final bidData = bidDoc.data();
                      final currentBidAmount = double.tryParse(bidData['bidAmount']?.toString() ?? '0.0') ?? 0.0;
                      if (bestBidAmount == null || currentBidAmount > bestBidAmount) {
                        bestBidAmount = currentBidAmount;
                        bestBidId = bidDoc.id;
                      }
                    }
                  }

                  for (var bidDoc in bidsSnapshot.docs) {
                    final currentBidId = bidDoc.id;
                    String newStatus = 'Active';

                    if (bestBidId != null && currentBidId == bestBidId) {
                      newStatus = 'Winning';
                    } else {
                      newStatus = 'Lost';
                    }

                    await _firestore
                        .collection('tenders')
                        .doc(tenderId)
                        .collection('bids')
                        .doc(currentBidId)
                        .update({'status': newStatus});
                  }

                  _bidAmountController.clear();
                  _perUnitPriceController.clear();
                  _siUnitController.clear();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bid placed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error placing bid: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all bid details.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Submit Bid',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64B5F6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showTenderDetails(BuildContext context, Map<String, dynamic> tenderData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tender Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: _buildDetailTable(tenderData),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64B5F6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Tender Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B263B),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'Active',
                  label: Text('Active'),
                  icon: Icon(Icons.play_arrow),
                ),
                ButtonSegment<String>(
                  value: 'Completed',
                  label: Text('Completed'),
                  icon: Icon(Icons.check_circle),
                ),
              ],
              selected: <String>{_selectedTenderStatus},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedTenderStatus = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                foregroundColor: Colors.white,
                selectedForegroundColor: Colors.white,
                selectedBackgroundColor: const Color(0xFF4A90E2),
                backgroundColor: const Color(0xFF0D1B2A),
                side: const BorderSide(color: Color(0xFF64B5F6), width: 1),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.white], // Blue to white gradient
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('tenders')
              .where('status', isEqualTo: _selectedTenderStatus)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF64B5F6)));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading tenders: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }
            final tenders = snapshot.data?.docs ?? [];
            if (tenders.isEmpty) {
              return Center(
                child: Text(
                  'No ${_selectedTenderStatus.toLowerCase()} tenders available',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tenders.length,
              itemBuilder: (context, index) {
                final tenderData = tenders[index].data() as Map<String, dynamic>;
                final tenderId = tenders[index].id;

                return TenderCard(
                  tenderData: tenderData,
                  tenderId: tenderId,
                  selectedTenderStatus: _selectedTenderStatus,
                  showTenderDetails: _showTenderDetails,
                  showBidDialog: _showBidDialog,
                );
              },
            );
          },
        ),
      ),
    );
  }
}