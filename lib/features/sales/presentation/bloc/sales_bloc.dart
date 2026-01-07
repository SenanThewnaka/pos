import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/logic/transaction_service.dart';
import '../../../../core/database/daos/product_dao.dart';
import '../../../../core/database/app_database.dart'; // For Product Entity access? Or use DTO
import 'sales_event.dart';
import 'sales_state.dart';

import '../../../../core/logic/receipt_service.dart';

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final TransactionService _transactionService;
  final ProductDao _productDao;
  final ReceiptService _receiptService; // Add this
  final int _currentUserId;

  SalesBloc({
    required TransactionService transactionService,
    required ProductDao productDao,
    required int currentUserId,
  }) : _transactionService = transactionService,
       _productDao = productDao,
       _receiptService = ReceiptService(), // Init here or inject
       _currentUserId = currentUserId,
       super(const SalesState()) {
    
    on<ScanBarcode>(_onScanBarcode);
    on<ProcessCheckout>(_onProcessCheckout);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<ResetSale>(_onResetSale);
  }
  
  Future<void> _onScanBarcode(ScanBarcode event, Emitter<SalesState> emit) async {
    emit(state.copyWith(status: SalesStatus.loading));
    try {
      final product = await _productDao.getProductByBarcode(event.barcode);
      if (product == null) {
        emit(state.copyWith(
          status: SalesStatus.failure, 
          errorMessage: 'Product not found: ${event.barcode}'
        ));
        return;
      }

      // Logic: If already in cart, increment qty. Else add new.
      final currentItems = List<CartItem>.from(state.cartItems);
      final existingIndex = currentItems.indexWhere((i) => i.productId == product.id);

      if (existingIndex >= 0) {
        final existingItem = currentItems[existingIndex];
        currentItems[existingIndex] = CartItem(
          productId: existingItem.productId,
          productName: existingItem.productName,
          quantity: existingItem.quantity + 1,
          unitPrice: existingItem.unitPrice,
          tax: existingItem.tax,
          discount: existingItem.discount,
        );
      } else {
        currentItems.add(CartItem(
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitPrice: product.price,
          tax: 0, // Implement Tax Logic later
          discount: 0,
        ));
      }

      _emitUpdatedTotals(emit, currentItems);
      
    } catch (e) {
      emit(state.copyWith(status: SalesStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateQuantity(UpdateCartItemQuantity event, Emitter<SalesState> emit) async {
     final currentItems = List<CartItem>.from(state.cartItems);
     if (event.index >= 0 && event.index < currentItems.length) {
       final item = currentItems[event.index];
       if (event.quantity <= 0) {
         currentItems.removeAt(event.index);
       } else {
         currentItems[event.index] = CartItem(
            productId: item.productId,
            productName: item.productName,
            quantity: event.quantity,
            unitPrice: item.unitPrice,
            tax: item.tax,
            discount: item.discount,
         );
       }
       _emitUpdatedTotals(emit, currentItems);
     }
  }

  Future<void> _onProcessCheckout(ProcessCheckout event, Emitter<SalesState> emit) async {
    if (state.cartItems.isEmpty) return;
    
    emit(state.copyWith(status: SalesStatus.loading));

    try {
      // 1. Process Sale (Atomic)
      await _transactionService.processSale(
        cashierId: _currentUserId,
        items: state.cartItems,
        totalAmount: state.grandTotal,
        taxAmount: state.taxTotal,
        discountAmount: state.discountTotal,
        paymentMethod: event.paymentMethod,
      );

      // 2. Print Receipt (Async, don't block UI success indefinitely)
      final receipt = _receiptService.generateReceipt(
        shopName: "SYNTHORA POS",
        cashierName: "User $_currentUserId",
        saleUuid: "PENDING-UUID", // Refactor service to return UUID if needed
        date: DateTime.now(),
        items: state.cartItems,
        total: state.grandTotal,
        paymentMethod: event.paymentMethod,
      );
      
      await _receiptService.printReceipt(receipt);
      
      emit(state.copyWith(
        status: SalesStatus.success,
        lastSuccessUuid: "SUCCESS",
        cartItems: [],
        grandTotal: 0,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SalesStatus.failure,
        errorMessage: "Transaction Failed: ${e.toString()}"
      ));
    }
  }
  
  void _onResetSale(ResetSale event, Emitter<SalesState> emit) {
    emit(const SalesState());
  }

  void _emitUpdatedTotals(Emitter<SalesState> emit, List<CartItem> items) {
    double sub = 0;
    double tax = 0;
    double disc = 0;

    for (var i in items) {
      sub += (i.quantity * i.unitPrice);
      tax += i.tax;
      disc += i.discount;
    }

    emit(state.copyWith(
      status: SalesStatus.initial,
      cartItems: items,
      subTotal: sub,
      taxTotal: tax,
      discountTotal: disc,
      grandTotal: (sub + tax) - disc,
    ));
  }
}
