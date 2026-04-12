enum PropertyStatus {
  forSale,
  sold,
  pending,
}

extension PropertyStatusX on PropertyStatus {
  String get displayLabel => switch (this) {
        PropertyStatus.forSale => 'For sale',
        PropertyStatus.sold => 'Sold',
        PropertyStatus.pending => 'Pending',
      };
}

PropertyStatus propertyStatusFromString(String value) {
  switch (value.toLowerCase()) {
    case 'sold':
      return PropertyStatus.sold;
    case 'pending':
      return PropertyStatus.pending;
    case 'forsale':
    case 'for_sale':
    case 'for sale':
      return PropertyStatus.forSale;
    default:
      return PropertyStatus.forSale;
  }
}
