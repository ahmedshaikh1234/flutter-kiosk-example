import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kioskflutter/blocs/cart/cart_bloc.dart';
import 'package:kioskflutter/blocs/cart/cart_event.dart';
import 'package:kioskflutter/blocs/catalog/catalog_bloc.dart';
import 'package:kioskflutter/blocs/catalog/catalog_state.dart';
import 'package:kioskflutter/component/button.dart';
import 'package:kioskflutter/component/image_entity.dart';
import 'package:kioskflutter/component/modifiers.dart';
import 'package:kioskflutter/component/quantity.dart';
import 'package:kioskflutter/model/cart.dart';
import 'package:kioskflutter/model/catalog.dart';

class AddOnGroupViewModel {
  final List<AddOnGroup> addOnGroups;
  final Map<String, List<AddOn>> addOns;
  Map<String, Set<String>> selectedAddOns = {};

  AddOnGroupViewModel(
    this.addOnGroups,
    this.addOns,
  );

  List<AddOn> getAddOnsOf(AddOnGroup group) {
    var addOns = this.addOns[group.id];
    if (addOns != null) {
      return addOns;
    }
    return [];
  }

  Map<String, List<SelectedAddOn>> deriveSelectedAddOns() {
    Map<String, List<SelectedAddOn>> map = {};
    selectedAddOns.forEach((key, value) {
      List<SelectedAddOn> temp = [];
      value.forEach((e) {
        var groupAddOns = addOns[key];
        if (groupAddOns != null) {
          temp.addAll(groupAddOns.where((element) => element.id == e).map(
              (e) => SelectedAddOn(addOnRef: e, unitPrice: e.price ?? 0.0)));
        }
      });
      map[key] = temp;
    });
    return map;
  }

  void deselectAddOns(AddOnGroup group, List<String> addOns) {
    if (_isSingleOption(group)) {
      return;
    }

    Set<String>? selected = selectedAddOns[group.id];
    if (selected != null) {
      var count = selected.length - addOns.length;
      if (count < 0) {
        selected.clear();
        return;
      }
      selected.removeAll(addOns);
    } else {
      selectedAddOns[group.id] = Set.from(addOns);
    }
  }

  void selectAddOns(AddOnGroup group, List<String> addOns) {
    Set<String>? selected = selectedAddOns[group.id];
    if (selected != null) {
      if (_isSingleOption(group)) {
        selected.clear();
        selected.addAll(addOns);
        return;
      }

      var count = selected.length + addOns.length;
      if (count > group.max) {
        return;
      }
      selected.addAll(addOns);
    } else {
      selectedAddOns[group.id] = Set.from(addOns);
    }
  }

  bool _isSingleOption(AddOnGroup group) {
    return group.min == 1 && group.max == 1;
  }

  bool isDisabled(AddOnGroup group) {
    if (_isSingleOption(group)) {
      return false;
    }

    Set<String>? selected = selectedAddOns[group.id];
    if (selected != null) {
      return selected.length >= group.max;
    } else {
      return false;
    }
  }

  bool isSelected(String groupId, String addOn) {
    Set<String>? selected = selectedAddOns[groupId];
    if (selected != null) {
      return selected.contains(addOn);
    }
    return false;
  }

  factory AddOnGroupViewModel.fromState(CatalogState state, Item item) {
    if (item.addOnGroupIds.isEmpty) {
      return AddOnGroupViewModel(const [], const {});
    }

    List<AddOnGroup> addOnGroupsRef = [];
    Map<String, List<AddOn>> addOnRefs = {};
    for (String grpId in item.addOnGroupIds) {
      if (state.addOnGroups.containsKey(grpId)) {
        AddOnGroup grp = state.addOnGroups[grpId]!;
        addOnGroupsRef.add(grp);

        if (grp.addOnIds.isNotEmpty) {
          List<AddOn> children = [];
          for (String id in grp.addOnIds) {
            if (state.addOns[id] != null) {
              children.add(state.addOns[id]!);
            }
          }
          addOnRefs[grpId] = children;
        }
      }
    }

    return AddOnGroupViewModel(addOnGroupsRef, addOnRefs);
  }

  @override
  String toString() =>
      'AddOnGroupViewModel(addOnGroups: $addOnGroups, addOns: $addOns)';
}

class ItemSelectContainer extends StatelessWidget {
  const ItemSelectContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CatalogBloc bloc = BlocProvider.of<CatalogBloc>(context);
    return BlocBuilder<CatalogBloc, CatalogState>(
        bloc: bloc,
        buildWhen: (prevState, currState) {
          return prevState.selectedItemId != currState.selectedItemId &&
              currState.items[currState.selectedItemId] != null;
        },
        builder: (ctx, state) {
          Item? item = state.items[state.selectedItemId];
          if (item != null) {
            return ItemSelect(
              item: item,
              addOnGroupViewModel: AddOnGroupViewModel.fromState(state, item),
            );
          } else {
            return Center(child: Text("Select an Item !"));
          }
        });
  }
}

class ItemSelect extends StatefulWidget {
  final Item item;
  final AddOnGroupViewModel addOnGroupViewModel;

  ItemSelect({Key? key, required this.item, required this.addOnGroupViewModel})
      : super(key: key);

  @override
  State<ItemSelect> createState() =>
      _ItemSelectState(addOnGroupViewModel, item: item);
}

class _ItemSelectState extends State<ItemSelect> {
  final Item item;
  final AddOnGroupViewModel addOnGroupViewModel;
  int quantity = 1;

  _ItemSelectState(this.addOnGroupViewModel, {required this.item});

  void _whenQuantityChanged(QuantityChangeType type) {
    if (type == QuantityChangeType.increment) {
      quantity += 1;
    } else {
      quantity = max(quantity - 1, 1);
    }
    setState(() {
      quantity = quantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Flexible(
              flex: 7,
              child: Container(
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    )
                  ]),
                  child: ItemSidePanel(
                    item: item,
                    addToCartClicked: () {
                      context.read<CartBloc>().itemModifiedEvent(
                          CartItemModificationEvent.fromCartItem(
                              CartItem(item, quantity,
                                  addOns: addOnGroupViewModel
                                      .deriveSelectedAddOns()),
                              CartItemModificationType.added));
                      Navigator.pop(context);
                    },
                    cancelClicked: () => Navigator.pop(context),
                    quantity: quantity,
                    onQuantityChanged: _whenQuantityChanged,
                  ))),
          Flexible(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AddOnPanel(
                  addOnGroupViewModel: addOnGroupViewModel,
                ),
              ))
        ],
      ),
    );
  }
}

class AddOnPanel extends StatefulWidget {
  final AddOnGroupViewModel addOnGroupViewModel;

  AddOnPanel({Key? key, required this.addOnGroupViewModel}) : super(key: key);

  @override
  State<AddOnPanel> createState() =>
      _AddOnPanelState(addOnGroupViewModel: addOnGroupViewModel);
}

class _AddOnPanelState extends State<AddOnPanel> {
  final AddOnGroupViewModel addOnGroupViewModel;
  int updated = 0;

  _AddOnPanelState({required this.addOnGroupViewModel});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (AddOnGroup group in addOnGroupViewModel.addOnGroups) {
      children.addAll(_generateAddOnGroup(context, group));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: children,
      ),
    );
  }

  List<Widget> _generateAddOnGroup(
      BuildContext context, AddOnGroup addOnGroup) {
    final ScrollController _controller = ScrollController();
    List<AddOn> childAddOns = addOnGroupViewModel.getAddOnsOf(addOnGroup);
    return [
      AddOnTitle(
        addOnGroupTitle: addOnGroup.name,
      ),
      Scrollbar(
        showTrackOnHover: true,
        controller: _controller,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _controller,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: childAddOns
                  .map((e) => AddOnOption(
                        addOn: e,
                        isDisabled: addOnGroupViewModel.isDisabled(addOnGroup),
                        isSelected:
                            addOnGroupViewModel.isSelected(addOnGroup.id, e.id),
                        onClicked: (addOnId, selected) {
                          setState(() {
                            updated++;
                            if (selected) {
                              addOnGroupViewModel
                                  .selectAddOns(addOnGroup, [addOnId]);
                            } else {
                              addOnGroupViewModel
                                  .deselectAddOns(addOnGroup, [addOnId]);
                            }
                          });
                        },
                      ))
                  .toList()),
        ),
      ),
      const SizedBox(
        height: 24,
      )
    ];
  }
}

class ItemSidePanel extends StatelessWidget {
  final Item item;
  final int quantity;
  final Function() addToCartClicked;
  final Function() cancelClicked;
  final Function(QuantityChangeType) onQuantityChanged;

  const ItemSidePanel(
      {Key? key,
      required this.item,
      required this.addToCartClicked,
      required this.cancelClicked,
      required this.quantity,
      required this.onQuantityChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ItemImage(
          imageUrl: item.imageUrl,
          width: 500,
          height: 300,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            item.name.toUpperCase(),
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            item.description,
            style: Theme.of(context).textTheme.bodyText1?.copyWith(height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            "700 Cal",
            style: Theme.of(context).textTheme.subtitle2,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Quantity(
                    qty: quantity,
                    onIncrease: () =>
                        onQuantityChanged(QuantityChangeType.increment),
                    onDecrease: () =>
                        onQuantityChanged(QuantityChangeType.decrement)),
                Row(
                  children: [
                    Text(
                      "TOTAL: ",
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    PriceLabel(price: item.price),
                  ],
                )
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  flex: 9,
                  child: KioskButton(
                      text: "ADD TO CART", onClicked: addToCartClicked)),
              Flexible(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: KioskButton(
                    text: "CANCEL",
                    onClicked: cancelClicked,
                    inactive: true,
                    inactiveColor: Colors.grey,
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
