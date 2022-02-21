import 'package:flutter/material.dart';
import 'package:kioskflutter/blocs/cart/cart_event.dart';
import 'package:kioskflutter/component/button.dart';
import 'package:kioskflutter/component/image_entity.dart';
import 'package:kioskflutter/component/quantity.dart';
import 'package:kioskflutter/model/cart.dart';

import '../constants.dart';

class ItemSidePanel extends StatelessWidget {
  final CartItem cartItem;
  final Function() addToCartClicked;
  final Function() cancelClicked;
  final Function(QuantityChangeType) onQuantityChanged;

  const ItemSidePanel({
    Key? key,
    required this.addToCartClicked,
    required this.cancelClicked,
    required this.onQuantityChanged,
    required this.cartItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var orientation = MediaQuery.of(context).orientation;
    var item = cartItem.itemRef;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ItemImage(
          imageUrl: item.imageUrl,
          width: double.infinity,
          height: 300,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            item.name.toUpperCase(),
            style: Theme.of(context).textTheme.headline2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            item.description,
            style: Theme.of(context).textTheme.bodyText1?.copyWith(height: 1.5),
          ),
        ),
        if (item.calories != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              "${item.calories} Cal",
              style: Theme.of(context).textTheme.subtitle2,
            ),
          )
        ],
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Quantity(
                  qty: cartItem.quantity,
                  onIncrease: () =>
                      onQuantityChanged(QuantityChangeType.increment),
                  onDecrease: () =>
                      onQuantityChanged(QuantityChangeType.decrement),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        "TOTAL: ",
                        style: Theme.of(context)
                            .textTheme
                            .headline5
                            ?.copyWith(color: kSecondaryTextColor),
                      ),
                    ),
                    PriceLabel(
                      price: cartItem.getItemSubTotal(),
                      color: theme.primaryColor,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: (orientation == Orientation.landscape)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 9,
                      child: _addToCartButton(),
                    ),
                    Flexible(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _cancelButton(),
                      ),
                    )
                  ],
                )
              : Column(
                  children: [
                    _cancelButton(),
                    const SizedBox(height: 16),
                    if (item.availableStockCount > 0) _addToCartButton(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _cancelButton() {
    return KioskButton(
      text: "CANCEL",
      onClicked: cancelClicked,
      inactive: true,
      inactiveColor: kSecondaryTextColor,
    );
  }

  Widget _addToCartButton() {
    return KioskButton(
      text: "ADD TO CART",
      onClicked: addToCartClicked,
    );
  }
}
