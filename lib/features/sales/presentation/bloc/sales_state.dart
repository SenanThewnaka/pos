import 'package:equatable/equatable.dart';
import '../../../../core/logic/transaction_service.dart';

enum SalesStatus { initial, loading, success, failure }

class SalesState extends Equatable {
  final SalesStatus status;
  final List<CartItem> cartItems;
  final double subTotal;
  final double taxTotal;
  final double discountTotal;
  final double grandTotal;
  final String? errorMessage;
  final String? lastSuccessUuid;

  const SalesState({
    this.status = SalesStatus.initial,
    this.cartItems = const [],
    this.subTotal = 0.0,
    this.taxTotal = 0.0,
    this.discountTotal = 0.0,
    this.grandTotal = 0.0,
    this.errorMessage,
    this.lastSuccessUuid,
  });

  SalesState copyWith({
    SalesStatus? status,
    List<CartItem>? cartItems,
    double? subTotal,
    double? taxTotal,
    double? discountTotal,
    double? grandTotal,
    String? errorMessage,
    String? lastSuccessUuid,
  }) {
    return SalesState(
      status: status ?? this.status,
      cartItems: cartItems ?? this.cartItems,
      subTotal: subTotal ?? this.subTotal,
      taxTotal: taxTotal ?? this.taxTotal,
      discountTotal: discountTotal ?? this.discountTotal,
      grandTotal: grandTotal ?? this.grandTotal,
      errorMessage: errorMessage,
      lastSuccessUuid: lastSuccessUuid ?? this.lastSuccessUuid,
    );
  }

  @override
  List<Object?> get props => [status, cartItems, subTotal, taxTotal, discountTotal, grandTotal, errorMessage, lastSuccessUuid];
}
