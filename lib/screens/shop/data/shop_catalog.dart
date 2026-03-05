import '../models/shop_models.dart';

class ShopCatalog {
  static const List<ShopProduct> products = [
    ShopProduct(
      id: 'ff_diamond',
      name: 'Free Fire Diamonds',
      category: ShopCategory.gameTopups,
      imageAsset: 'assets/freefire.jpg',
      badge: 'HOT',
      deliveryType: DeliveryType.instant,
      deliveryMode: DeliveryMode.directTopup,
      rating: 4.8,
      soldCount: 12840,
      popularity: 100,
      description: 'Top up Free Fire diamonds to your UID securely.',
      rules: ['Enter correct Free Fire UID.', 'Wrong UID is non-refundable.'],
      packs: [
        ProductPack(id: 'ff_100', label: '100 Diamonds', price: 50000),
        ProductPack(id: 'ff_310', label: '310 Diamonds', price: 145000),
        ProductPack(id: 'ff_520', label: '520 Diamonds', price: 250000),
      ],
      inputFields: [
        ProductInputField(
          type: ProductInputType.playerId,
          label: 'Free Fire UID',
        ),
        ProductInputField(
          type: ProductInputType.server,
          label: 'Server',
          options: ['Global', 'India', 'BD'],
        ),
      ],
    ),
    ShopProduct(
      id: 'pubg_uc',
      name: 'PUBG UC TopUp',
      category: ShopCategory.gameTopups,
      imageAsset: 'assets/freefire2.jpg',
      deliveryType: DeliveryType.minutes5to30,
      deliveryMode: DeliveryMode.directTopup,
      rating: 4.7,
      soldCount: 9450,
      popularity: 96,
      description: 'Top up PUBG UC by Player ID and region.',
      rules: [
        'Do not enter guest account ID.',
        'Double-check player ID and region.',
      ],
      packs: [
        ProductPack(id: 'pubg_60', label: '60 UC', price: 120000),
        ProductPack(id: 'pubg_325', label: '325 UC', price: 550000),
        ProductPack(id: 'pubg_660', label: '660 UC', price: 1050000),
      ],
      inputFields: [
        ProductInputField(
          type: ProductInputType.playerId,
          label: 'PUBG Player ID',
        ),
        ProductInputField(
          type: ProductInputType.region,
          label: 'Region',
          options: ['Global', 'Asia', 'Europe', 'Middle East'],
        ),
      ],
    ),
    ShopProduct(
      id: 'netflix_gift',
      name: 'Netflix Gift Card',
      category: ShopCategory.giftCards,
      imageAsset: 'assets/freefire.jpg',
      deliveryType: DeliveryType.instant,
      deliveryMode: DeliveryMode.code,
      rating: 4.6,
      soldCount: 3020,
      popularity: 88,
      description: 'Official Netflix gift card code delivery.',
      rules: ['No account password required.', 'Codes are region-specific.'],
      packs: [
        ProductPack(id: 'nf_1m', label: '1 Month', price: 1599000),
        ProductPack(id: 'nf_3m', label: '3 Month', price: 4599000),
      ],
      inputFields: [
        ProductInputField(type: ProductInputType.email, label: 'Email Address'),
        ProductInputField(
          type: ProductInputType.region,
          label: 'Country/Region',
          options: ['US', 'IN', 'NP', 'UK'],
        ),
      ],
    ),
    ShopProduct(
      id: 'prime_gift',
      name: 'Prime Gift Card',
      category: ShopCategory.giftCards,
      imageAsset: 'assets/freefire2.jpg',
      deliveryType: DeliveryType.instant,
      deliveryMode: DeliveryMode.code,
      rating: 4.5,
      soldCount: 2100,
      popularity: 82,
      description: 'Official Prime gift code. Redeem directly in account.',
      rules: ['Region must match account region.'],
      packs: [
        ProductPack(id: 'pr_1m', label: '1 Month', price: 449000),
        ProductPack(id: 'pr_1y', label: '1 Year', price: 4499000),
      ],
      inputFields: [
        ProductInputField(type: ProductInputType.email, label: 'Email Address'),
        ProductInputField(
          type: ProductInputType.region,
          label: 'Country/Region',
          options: ['US', 'IN', 'NP'],
        ),
      ],
    ),
    ShopProduct(
      id: 'chatgpt_plus',
      name: 'ChatGPT Plus',
      category: ShopCategory.subscriptions,
      imageAsset: 'assets/freefire.jpg',
      deliveryType: DeliveryType.hours1to24,
      deliveryMode: DeliveryMode.directTopup,
      rating: 4.7,
      soldCount: 1300,
      popularity: 90,
      description: 'Official ChatGPT Plus activation process.',
      rules: [
        'Provide correct OpenAI account email.',
        'No password is needed.',
      ],
      packs: [
        ProductPack(id: 'gpt_plus_1m', label: '1 Month Plus', price: 2999000),
      ],
      inputFields: [
        ProductInputField(
          type: ProductInputType.email,
          label: 'OpenAI Account Email',
        ),
      ],
    ),
    ShopProduct(
      id: 'canva_pro',
      name: 'Canva Pro',
      category: ShopCategory.subscriptions,
      imageAsset: 'assets/freefire2.jpg',
      deliveryType: DeliveryType.hours1to24,
      deliveryMode: DeliveryMode.directTopup,
      rating: 4.6,
      soldCount: 1540,
      popularity: 84,
      description: 'Official Canva Pro subscription activation.',
      rules: ['Provide correct Canva account email.', 'No password required.'],
      packs: [
        ProductPack(id: 'canva_1m', label: '1 Month', price: 899000),
        ProductPack(id: 'canva_3m', label: '3 Month', price: 2499000),
        ProductPack(id: 'canva_1y', label: '1 Year', price: 7999000),
      ],
      inputFields: [
        ProductInputField(
          type: ProductInputType.email,
          label: 'Canva Account Email',
        ),
      ],
    ),
  ];

  static List<ShopProduct> byCategory(ShopCategory category) {
    return products.where((p) => p.category == category).toList();
  }

  static List<ShopProduct> featured() {
    final list = List<ShopProduct>.from(products);
    list.sort((a, b) => b.popularity.compareTo(a.popularity));
    return list.take(6).toList();
  }
}
