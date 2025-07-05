import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class Activeagreement extends StatefulWidget {
  const Activeagreement({Key? key}) : super(key: key);

  @override
  _ActiveagreementState createState() => _ActiveagreementState();
}

class _ActiveagreementState extends State<Activeagreement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define the primary and accent colors for consistency
  final Color _primaryBlue = const Color(0xFF0D1B2A);
  final Color _secondaryBlue = const Color(0xFF1B263B);
  final Color _accentBlue = const Color(0xFF4A90E2);
  final Color _brightAccentBlue = const Color(0xFF64B5F6);
  final Color _textColor = Colors.white;
  final Color _subtleTextColor = Colors.grey[400]!;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Three tabs: Active, Past, Active Agreements
      child: Scaffold(
        backgroundColor: _primaryBlue,
        appBar: AppBar(
          title: Text(
            'Tender Overview',
            style: TextStyle(
              color: _textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _secondaryBlue,
          elevation: 4,
          iconTheme: IconThemeData(color: _textColor),
          bottom: TabBar(
            indicatorColor: _accentBlue, // Highlight active tab
            labelColor: _accentBlue, // Color of selected tab label
            unselectedLabelColor: _subtleTextColor, // Color of unselected tab label
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Active Tenders', icon: Icon(Icons.flash_on)),
              Tab(text: 'Past Tenders', icon: Icon(Icons.history)),
              Tab(text: 'Active Agreements', icon: Icon(Icons.assignment_turned_in)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTenderList('Active'), // Active Tenders Tab
            _buildTenderList('Completed'), // Past Tenders Tab (after deadline)
            _buildTenderList('Awarded'), // Active Agreements Tab (after owner awards)
          ],
        ),
      ),
    );
  }

  // Helper function to build a list of tenders based on status
  Widget _buildTenderList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tenders').where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No $status tenders found.',
              style: TextStyle(color: _subtleTextColor, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot tenderDoc = snapshot.data!.docs[index];
            Map<String, dynamic> tenderData = tenderDoc.data() as Map<String, dynamic>;

            // Extract data safely, providing default values
            String tenderId = tenderData['tenderId'] ?? 'N/A';
            String auctionType = tenderData['auctionType'] ?? 'N/A';
            String category = tenderData['category'] ?? 'N/A';
            String item = tenderData['item'] ?? 'N/A';
            String quantity = tenderData['quantity']?.toString() ?? 'N/A'; // Ensure quantity is string
            String deliveryLocation = tenderData['deliveryLocation'] ?? 'N/A';
            String tenderDeadline = tenderData['tenderDeadline'] != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(tenderData['tenderDeadline']).toLocal())
                : 'N/A';

            return _buildTenderCard(
              tenderDoc: tenderDoc, // Pass the whole document for status update
              tenderId: tenderId,
              auctionType: auctionType,
              category: category,
              item: item,
              quantity: quantity,
              deliveryLocation: deliveryLocation,
              tenderDeadline: tenderDeadline,
              currentTenderStatus: status, // Pass the current tab status
            );
          },
        );
      },
    );
  }

  // Helper function to build a single tender card
  Widget _buildTenderCard({
    required DocumentSnapshot tenderDoc, // Now receiving the whole doc
    required String tenderId,
    required String auctionType,
    required String category,
    required String item,
    required String quantity,
    required String deliveryLocation,
    required String tenderDeadline,
    required String currentTenderStatus, // To determine button visibility
  }) {
    final String tenderDocId = tenderDoc.id; // Get the actual document ID
    final Map<String, dynamic> tenderData = tenderDoc.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      color: _secondaryBlue.withOpacity(0.8), // Slightly transparent for depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _accentBlue.withOpacity(0.5), width: 1),
      ),
      elevation: 6, // Formal elevation
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tender ID: $tenderId',
              style: TextStyle(
                color: _brightAccentBlue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow(Icons.gavel, 'Auction Type:', auctionType),
            _buildDetailRow(Icons.category, 'Category:', category),
            _buildDetailRow(Icons.inventory, 'Item:', item),
            _buildDetailRow(Icons.numbers, 'Quantity:', quantity),
            _buildDetailRow(Icons.location_on, 'Delivery Location:', deliveryLocation),
            _buildDetailRow(Icons.schedule, 'Deadline:', tenderDeadline),
            const SizedBox(height: 16),
            _buildAllBiddersSection(tenderDocId, auctionType, currentTenderStatus), // Pass auctionType and current status

            // New: Agreement button for Completed tenders
            if (currentTenderStatus == 'Completed')
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAwardTenderDialog(context, tenderDocId, tenderData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Green for "Award"
                      foregroundColor: _textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.assignment_turned_in),
                    label: const Text('Award Tender', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper function for consistent detail rows
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accentBlue, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: _subtleTextColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // Section to display ALL bidders for a given tender (for owner view)
  Widget _buildAllBiddersSection(String tenderDocId, String auctionType, String currentTenderStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: _accentBlue.withOpacity(0.3), thickness: 1),
        const SizedBox(height: 8),
        Text(
          'All Bidders:',
          style: TextStyle(
            color: _brightAccentBlue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('tenders')
              .doc(tenderDocId)
              .collection('bids')
              .orderBy('createdAt', descending: true) // Order by latest bid
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Error loading bids: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text(
                'No bids yet for this tender.',
                style: TextStyle(color: _subtleTextColor),
              );
            }

            final List<DocumentSnapshot> bids = snapshot.data!.docs;

            // Determine the winning bid for highlighting
            DocumentSnapshot? winningBidDoc;
            double? bestBidAmount;

            for (var bidDoc in bids) {
              final bidData = bidDoc.data() as Map<String, dynamic>;
              final currentBidAmount = double.tryParse(bidData['bidAmount']?.toString() ?? '0.0') ?? 0.0;

              if (bestBidAmount == null) {
                bestBidAmount = currentBidAmount;
                winningBidDoc = bidDoc;
              } else if (auctionType == 'Lowest Bidder Wins') {
                if (currentBidAmount < bestBidAmount) {
                  bestBidAmount = currentBidAmount;
                  winningBidDoc = bidDoc;
                }
              } else { // Highest Bidder Wins
                if (currentBidAmount > bestBidAmount) {
                  bestBidAmount = currentBidAmount;
                  winningBidDoc = bidDoc;
                }
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bids.map((bidDoc) {
                Map<String, dynamic> bidData = bidDoc.data() as Map<String, dynamic>;
                String bidderName = bidData['bidderName'] ?? 'Anonymous Bidder';
                double bidAmount = double.tryParse(bidData['bidAmount']?.toString() ?? '0.0') ?? 0.0;
                double perUnitPrice = double.tryParse(bidData['perUnitPrice']?.toString() ?? '0.0') ?? 0.0;
                String siUnit = bidData['siUnit'] ?? '';
                String bidStatus = bidData['status'] ?? 'Active'; // 'Winning', 'Lost', 'Active', 'Awarded'
                Timestamp? createdAt = bidData['createdAt'] as Timestamp?;
                String bidTime = createdAt != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate().toLocal())
                    : 'N/A';

                bool isWinningBid = (winningBidDoc != null && bidDoc.id == winningBidDoc.id);

                // Determine highlight color based on bid status or if it's the winning bid
                Color highlightColor = _subtleTextColor;
                if (currentTenderStatus == 'Active' && isWinningBid) {
                  highlightColor = Colors.greenAccent; // Highlight winning bid in active tender
                } else if (bidStatus == 'Awarded') {
                  highlightColor = Colors.lightBlueAccent; // Special color for awarded bid
                } else if (bidStatus == 'Winning') {
                   highlightColor = Colors.greenAccent; // Already winning
                } else if (bidStatus == 'Lost') {
                   highlightColor = Colors.redAccent; // Already lost
                }


                return Card(
                  color: highlightColor.withOpacity(0.1), // Subtle highlight background
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isWinningBid && currentTenderStatus == 'Active'
                          ? Colors.greenAccent.withOpacity(0.5) // Stronger border for current winner
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: _brightAccentBlue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                bidderName,
                                style: TextStyle(
                                  color: _textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: bidStatus == 'Winning' ? Colors.green.shade700.withOpacity(0.6)
                                    : bidStatus == 'Lost' ? Colors.red.shade700.withOpacity(0.6)
                                    : bidStatus == 'Awarded' ? Colors.lightBlue.shade700.withOpacity(0.6)
                                    : Colors.grey.shade700.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                bidStatus,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 26.0), // Align with bidder name
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Bid: ₹${bidAmount.toStringAsFixed(2)}',
                                style: TextStyle(color: highlightColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Per Unit: ₹${perUnitPrice.toStringAsFixed(2)} / $siUnit',
                                style: TextStyle(color: _subtleTextColor, fontSize: 13),
                              ),
                              Text(
                                'Placed: $bidTime',
                                style: TextStyle(color: _subtleTextColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Dialog to confirm awarding a tender
  Future<void> _showAwardTenderDialog(BuildContext context, String tenderDocId, Map<String, dynamic> tenderData) async {
    // Find the current winning bid
    QuerySnapshot bidsSnapshot = await _firestore
        .collection('tenders')
        .doc(tenderDocId)
        .collection('bids')
        .orderBy('bidAmount', descending: tenderData['auctionType'] != 'Lowest Bidder Wins')
        .limit(1)
        .get();

    if (bidsSnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No bids available to award for this tender.'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final winningBidDoc = bidsSnapshot.docs.first;
    final winningBidData = winningBidDoc.data() as Map<String, dynamic>;
    final winningBidderName = winningBidData['bidderName'] ?? 'Unknown Bidder';
    final winningBidAmount = double.tryParse(winningBidData['bidAmount']?.toString() ?? '0.0') ?? 0.0;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: _secondaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirm Award Tender',
            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to award this tender to "$winningBidderName" for ₹${winningBidAmount.toStringAsFixed(2)}?',
            style: TextStyle(color: _subtleTextColor),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: _brightAccentBlue),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: _textColor,
              ),
              child: const Text('Award'),
              onPressed: () async {
                try {
                  // 1. Update the tender status to 'Awarded'
                  await _firestore.collection('tenders').doc(tenderDocId).update({'status': 'Awarded'});

                  // 2. Update all bids for this tender
                  final allBidsSnapshot = await _firestore
                      .collection('tenders')
                      .doc(tenderDocId)
                      .collection('bids')
                      .get();

                  WriteBatch batch = _firestore.batch();

                  for (var bid in allBidsSnapshot.docs) {
                    if (bid.id == winningBidDoc.id) {
                      // Mark the winning bid as 'Awarded'
                      batch.update(bid.reference, {'status': 'Awarded'});
                    } else {
                      // Mark all other bids as 'Lost'
                      batch.update(bid.reference, {'status': 'Lost'});
                    }
                  }
                  await batch.commit();

                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tender successfully awarded!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to award tender: $e'), backgroundColor: Colors.red),
                    );
                  }
                  print('Error awarding tender: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }
}