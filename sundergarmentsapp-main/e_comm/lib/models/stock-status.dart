// ignore_for_file: file_names

enum StockStatus { inStock, lowStock, outOfStock }

extension StockStatusX on StockStatus {
  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      // Deliberately different wording from the admin app's "Low Stock"
      // - that's the correct staff-facing label for inventory
      // management, but "Selling Fast" is better customer-facing copy
      // for the exact same underlying state (creates urgency instead
      // of sounding like an inventory problem). Same enum value, same
      // threshold, different audience.
      case StockStatus.lowStock:
        return 'Selling Fast';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  /// Derives status from a stock count and the product's own low-stock
  /// threshold (defaults to 5 units if the product doesn't set one).
  /// Mirrors the admin app's identical logic exactly - both apps read
  /// the same Firestore documents, so the thresholds have to agree.
  static StockStatus fromStock(int stock, {int lowStockThreshold = 5}) {
    if (stock <= 0) return StockStatus.outOfStock;
    if (stock <= lowStockThreshold) return StockStatus.lowStock;
    return StockStatus.inStock;
  }
}
