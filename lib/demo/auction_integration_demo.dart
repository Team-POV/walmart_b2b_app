import 'package:flutter/material.dart';
import '../widgets/auction_navigation_helper.dart';

class AuctionIntegrationDemo extends StatelessWidget {
  const AuctionIntegrationDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: const Text(
          'Auction Integration Demo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B263B),
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Integration Examples',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Example 1: Simple button
              const Text(
                '1. Simple Button',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              AuctionNavigationHelper.buildAuctionButton(context),
              
              const SizedBox(height: 24),
              
              // Example 2: Custom button
              const Text(
                '2. Custom Button',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              AuctionNavigationHelper.buildAuctionButton(
                context,
                label: 'Join Auction Now',
                backgroundColor: const Color(0xFF4CAF50),
                height: 48,
              ),
              
              const SizedBox(height: 24),
              
              // Example 3: Card-style navigation
              const Text(
                '3. Card-style Navigation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              AuctionNavigationHelper.buildAuctionCard(context),
              
              const SizedBox(height: 24),
              
              // Example 4: Grid of options
              const Text(
                '4. Grid Layout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  AuctionNavigationHelper.buildAuctionCard(
                    context,
                    title: 'Live Auctions',
                    subtitle: 'Join active bidding',
                    icon: Icons.gavel,
                  ),
                  AuctionNavigationHelper.buildAuctionCard(
                    context,
                    title: 'Tender Creation',
                    subtitle: 'Create new tender',
                    icon: Icons.add_business,
                    backgroundColor: const Color(0xFF2D4A3B),
                    textColor: const Color(0xFF4CAF50),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Example 5: List tile style
              const Text(
                '5. List Tile Style',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B263B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.gavel,
                    color: Color(0xFF64B5F6),
                    size: 32,
                  ),
                  title: const Text(
                    'Live Auctions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'View and participate in active bidding',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF64B5F6),
                    size: 16,
                  ),
                  onTap: () => AuctionNavigationHelper.navigateToAuction(context),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Example 6: Floating Action Button
              const Text(
                '6. Floating Action Button',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add this to your scaffold:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B263B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
                ),
                child: const Text(
                  '''floatingActionButton: FloatingActionButton.extended(
  onPressed: () => AuctionNavigationHelper.navigateToAuction(context),
  backgroundColor: Color(0xFF4A90E2),
  icon: Icon(Icons.gavel, color: Colors.white),
  label: Text('Auctions', style: TextStyle(color: Colors.white)),
),''',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // How to use
              const Text(
                'How to Use in Your App:',
                style: TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildHowToUseStep(
                '1. Import the Helper',
                "import '../widgets/auction_navigation_helper.dart';",
              ),
              
              _buildHowToUseStep(
                '2. Add Navigation Button',
                '''AuctionNavigationHelper.buildAuctionButton(context)''',
              ),
              
              _buildHowToUseStep(
                '3. Or Use Direct Navigation',
                '''AuctionNavigationHelper.navigateToAuction(context)''',
              ),
              
              _buildHowToUseStep(
                '4. Or Import AuctionPage Directly',
                '''import '../pages/auction_page.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AuctionPage(),
  ),
);''',
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHowToUseStep(String title, String code) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B263B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64B5F6),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}