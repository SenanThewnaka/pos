import 'package:equatable/equatable.dart';
import '../../../../core/logic/transaction_service.dart'; // For CartItem DTO if needed or create domain model

abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object?> get props => [];
}

class ScanBarcode extends SalesEvent {
  final String barcode;
  const ScanBarcode(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

class AddProductToCart extends SalesEvent {
  final int productId;
  const AddProductToCart(this.productId);
}

class UpdateCartItemQuantity extends SalesEvent {
  final int index;
  final double quantity;
  const UpdateCartItemQuantity(this.index, this.quantity);
}

class VoidCartItem extends SalesEvent {
  final int index;
  const VoidCartItem(this.index);
}

class ProcessCheckout extends SalesEvent {
  final String paymentMethod;
  const ProcessCheckout(this.paymentMethod);
}

class ResetSale extends SalesEvent {}
