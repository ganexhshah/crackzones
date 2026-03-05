import 'dart:async';
import 'package:flutter/material.dart';

class ShopBannerCarousel extends StatefulWidget {
  const ShopBannerCarousel({super.key});

  @override
  State<ShopBannerCarousel> createState() => _ShopBannerCarouselState();
}

class _ShopBannerCarouselState extends State<ShopBannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.94);
  int _index = 0;
  Timer? _timer;

  final List<_BannerData> _banners = const [
    _BannerData(
      imagePath: 'assets/images/bg/bg1.jpg',
      title: 'Weekend Mega Drop',
      subtitle: 'Up to 20% off on top-up packs',
    ),
    _BannerData(
      imagePath: 'assets/images/bg/bg2.jpg',
      title: 'Rare Skin Collection',
      subtitle: 'Limited skins available now',
    ),
    _BannerData(
      imagePath: 'assets/freefire2.jpg',
      title: 'Pro Bundle Release',
      subtitle: 'Get premium bundles with coins',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_index + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => _bannerCard(_banners[i]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFFDE68A),
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _bannerCard(_BannerData banner) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(banner.imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.08),
              ],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                banner.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                banner.subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerData {
  final String imagePath;
  final String title;
  final String subtitle;

  const _BannerData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });
}
