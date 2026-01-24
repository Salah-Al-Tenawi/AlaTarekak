// // ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'package:dropdown_search/dropdown_search.dart';
// import 'package:flutter/material.dart';

// // ignore: must_be_immutable
// class MultiDropDownSearch extends StatelessWidget {
//   List<String> items;
//   List<String> selectedItems;
//   double? paddingH;
//   double? paddingV;
//   String title;
//   void Function(List<String>)? onChanged;
//   MultiDropDownSearch(

//       {super.key,
//       required this.items,
//       required this.selectedItems,
//       this.paddingH,
//       this.paddingV,
//       this.onChanged,
//       required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//           horizontal: paddingH ?? 0, vertical: paddingV ?? 0),
//       child: DropdownSearch<String>.multiSelection(
//         // validator: ,
//         // asyncItems: ,
//         popupProps: PopupPropsMultiSelection.menu(
//             showSelectedItems: true,
//             disabledItemFn: (String s) => s.startsWith('I'),
//             showSearchBox: true),
//         dropdownDecoratorProps: DropDownDecoratorProps(
//           dropdownSearchDecoration: InputDecoration(
//             filled: true,
//             // fillColor: Color.greyColor,
//             border: const OutlineInputBorder(),
//             labelText: title,
//           ),
//         ),

//         // popupProps: const PopupPropsMultiSelection.menu(),
//         // items: items,
//         onChanged: (List<String> items) {
//           onChanged!(items);

//           // selectedItems.assignAll(items);
//         },
//         selectedItems: selectedItems,
//       ),
//     );
//   }
// }
