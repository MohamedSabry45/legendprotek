class JobOrderSparePartModel {
  final int id;
  final int jobOrderId;
  final int productId;
  final int deliveredStatus;
  final int outForDeliver;
  final int clientApproval;
  final int inventoryDelivery;
  final String price;
  final String? purchasePrice;
  final String createdAt;
  final String quantity;
  final int? supplierId;
  final String productStatus;
  final String? notes;
  final String updatedAt;
  final int? jobEstimatorId;
  final String productName;
  final String sku;
  final int? productCategoryId;
  final String? productCategoryName;

  const JobOrderSparePartModel({
    required this.id,
    required this.jobOrderId,
    required this.productId,
    required this.deliveredStatus,
    required this.outForDeliver,
    required this.clientApproval,
    required this.inventoryDelivery,
    required this.price,
    required this.purchasePrice,
    required this.createdAt,
    required this.quantity,
    required this.supplierId,
    required this.productStatus,
    required this.notes,
    required this.updatedAt,
    required this.jobEstimatorId,
    required this.productName,
    required this.sku,
    required this.productCategoryId,
    required this.productCategoryName,
  });

  double get priceValue => double.tryParse(price.toString()) ?? 0.0;
  double get quantityValue => double.tryParse(quantity.toString()) ?? 0.0;
  double get lineTotal => priceValue * quantityValue;

  factory JobOrderSparePartModel.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    return JobOrderSparePartModel(
      id: _asInt(json['id']),
      jobOrderId: _asInt(json['job_order_id']),
      productId: _asInt(json['product_id']),
      deliveredStatus: _asInt(json['delivered_status']),
      outForDeliver: _asInt(json['out_for_deliver']),
      clientApproval: _asInt(json['client_approval']),
      inventoryDelivery: _asInt(json['inventory_delivery']),
      price: json['price']?.toString() ?? '0',
      purchasePrice: json['purchase_price']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      quantity: json['quantity']?.toString() ?? '0',
      supplierId: json['supplier_id'] == null
          ? null
          : _asInt(json['supplier_id']),
      productStatus: json['product_status']?.toString() ?? '',
      notes: json['Notes']?.toString(),
      updatedAt: json['updated_at']?.toString() ?? '',
      jobEstimatorId: json['job_estimator_id'] == null
          ? null
          : _asInt(json['job_estimator_id']),
      productName: json['product_name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      productCategoryId: json['product_category_id'] == null
          ? null
          : _asInt(json['product_category_id']),
      productCategoryName: json['product_category_name']?.toString(),
    );
  }
}
