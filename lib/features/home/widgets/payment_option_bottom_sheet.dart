import 'package:flutter/material.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/shared/widgets/custom_button.dart';

class PaymentOptionBottomSheet extends StatefulWidget {
  final Function(String) onOptionSelected;

  const PaymentOptionBottomSheet({Key? key, required this.onOptionSelected})
    : super(key: key);

  @override
  State<PaymentOptionBottomSheet> createState() =>
      _PaymentOptionBottomSheetState();
}

class _PaymentOptionBottomSheetState extends State<PaymentOptionBottomSheet> {
  String _selectedOption = "I have cash";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Select Payment Option",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          RadioListTile<String>(
            activeColor: AppColors.primary,
            title: const Text("I have cash"),
            value: "I have cash",
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
          ),
          RadioListTile<String>(
            activeColor: AppColors.primary,
            title: const Text("10,000"),
            value: "10000",
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
          ),
          RadioListTile<String>(
            activeColor: AppColors.primary,
            title: const Text("5,000"),
            value: "5000",
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
          ),
          RadioListTile<String>(
            activeColor: AppColors.primary,
            title: const Text("2,000"),
            value: "2000",
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
          ),
          RadioListTile<String>(
            activeColor: AppColors.primary,
            title: const Text("1,000"),
            value: "1000",
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
          ),
          RadioListTile<String>(
            activeColor: AppColors.primary,
            title: const Text("500"),
            value: "500",
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
          ),
          RadioListTile<String>(
            activeColor: AppColors.primary,
            title: const Text("Mobile Money"),
            value: "Mobile Money",
            groupValue: _selectedOption,
            onChanged: (value) {
              setState(() {
                _selectedOption = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          CustomRoundedButton(
            text: "Confirm",
            backgroundColor: AppColors.primary,
            onPressed: () {
              widget.onOptionSelected(_selectedOption);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
