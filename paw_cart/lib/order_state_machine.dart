
enum OrderStatus {
  placed,
  paymentVerified,
  packing,
  shipped,
  delivered,
  paymentFailed,
  cancelled,
}

enum OrderEvent {
  paymentSuccess,
  paymentFailure,
  retryPayment,
  startPacking,
  ship,
  deliver,
  cancel,
}

class OrderStateMachine {
  OrderStateMachine({OrderStatus initialStatus = OrderStatus.placed})
      : _status = initialStatus;

  OrderStatus _status;

  OrderStatus get status => _status;

  // Defines the valid transitions of the order.
  static const Map<OrderStatus, Map<OrderEvent, OrderStatus>>
      transitions = {
    OrderStatus.placed: {
      OrderEvent.paymentSuccess: OrderStatus.paymentVerified,
      OrderEvent.paymentFailure: OrderStatus.paymentFailed,
      OrderEvent.cancel: OrderStatus.cancelled,
    },
    OrderStatus.paymentFailed: {
      OrderEvent.retryPayment: OrderStatus.placed,
      OrderEvent.cancel: OrderStatus.cancelled,
    },
    OrderStatus.paymentVerified: {
      OrderEvent.startPacking: OrderStatus.packing,
      OrderEvent.cancel: OrderStatus.cancelled,
    },
    OrderStatus.packing: {
      OrderEvent.ship: OrderStatus.shipped,
    },
    OrderStatus.shipped: {
      OrderEvent.deliver: OrderStatus.delivered,
    },
    OrderStatus.delivered: {},
    OrderStatus.cancelled: {},
  };

  bool canApply(OrderEvent event) {
    return transitions[_status]?.containsKey(event) ?? false;
  }

  bool apply(OrderEvent event) {
    final nextStatus = transitions[_status]?[event];

    if (nextStatus == null) {
      return false;
    }

    _status = nextStatus;
    return true;
  }

  static String label(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.paymentVerified:
        return 'Payment Verified';
      case OrderStatus.packing:
        return 'Packing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.paymentFailed:
        return 'Payment Failed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

