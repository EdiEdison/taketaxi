import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:taketaxi/features/home/controller/home_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:taketaxi/shared/widgets/custom_button.dart';

class PlacesApiGoogleMapSearch extends StatefulWidget {
  final Function(String location) onLocationSelected;
  const PlacesApiGoogleMapSearch({super.key, required this.onLocationSelected});

  @override
  State<PlacesApiGoogleMapSearch> createState() =>
      _PlacesApiGoogleMapSearchState();
}

class _PlacesApiGoogleMapSearchState extends State<PlacesApiGoogleMapSearch> {
  late String tokenForSession;
  final uuid = Uuid();

  List<dynamic> placesList = [];
  String? _selectedDestination;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void makeSuggestions(String input) async {
    if (input.isEmpty) {
      if (mounted) {
        setState(() {
          placesList = [];
          _selectedDestination = null;
        });
      }
      return;
    }
    String googleApiKey = "AIzaSyBpxYpVUtQlXjQgBCJNDvLkADlgTQ9IbLs";
    String groundURL =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    String request =
        '$groundURL?input=$input&key=$googleApiKey&sessiontoken=$tokenForSession&components=country:CM';

    var searchResponse = await http.get(Uri.parse(request));
    var responseBody = searchResponse.body.toString();

    if (mounted) {
      if (searchResponse.statusCode == 200) {
        setState(() {
          placesList = jsonDecode(responseBody)['predictions'];
        });
      } else {
        setState(() {
          placesList = [];
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    tokenForSession = uuid.v4();
    _searchController.addListener(() {
      if (_selectedDestination == null ||
          _searchController.text != _selectedDestination) {
        makeSuggestions(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isRequestingTaxi = false;

  void _showPaymentOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        String? _selectedPaymentType;
        String? _selectedCashAmount;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isDirectlySelected = _selectedPaymentType == 'Directly';
            bool canRequestTaxi =
                (_selectedPaymentType != null && !isDirectlySelected) ||
                (isDirectlySelected && _selectedCashAmount != null);

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Choose Payment Method",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isDirectlySelected)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPaymentOptionTile(
                          context,
                          'Momo',
                          _selectedPaymentType == 'Momo',
                          () => setModalState(() {
                            _selectedPaymentType = 'Momo';
                            _selectedCashAmount = null;
                          }),
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentOptionTile(
                          context,
                          'Orange Money',
                          _selectedPaymentType == 'Orange Money',
                          () => setModalState(() {
                            _selectedPaymentType = 'Orange Money';
                            _selectedCashAmount = null;
                          }),
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentOptionTile(
                          context,
                          'Directly',
                          _selectedPaymentType == 'Directly',
                          () => setModalState(() {
                            _selectedPaymentType = 'Directly';
                          }),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Cash Amount",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: [
                            _buildCashAmountChip(
                              context,
                              '10k',
                              _selectedCashAmount == '10k',
                              () => setModalState(() {
                                _selectedCashAmount = '10k';
                              }),
                            ),
                            _buildCashAmountChip(
                              context,
                              '5k',
                              _selectedCashAmount == '5k',
                              () => setModalState(() {
                                _selectedCashAmount = '5k';
                              }),
                            ),
                            _buildCashAmountChip(
                              context,
                              '2k',
                              _selectedCashAmount == '2k',
                              () => setModalState(() {
                                _selectedCashAmount = '2k';
                              }),
                            ),
                            _buildCashAmountChip(
                              context,
                              '1k',
                              _selectedCashAmount == '1k',
                              () => setModalState(() {
                                _selectedCashAmount = '1k';
                              }),
                            ),
                            _buildCashAmountChip(
                              context,
                              '500',
                              _selectedCashAmount == '500',
                              () => setModalState(() {
                                _selectedCashAmount = '500';
                              }),
                            ),
                            _buildCashAmountChip(
                              context,
                              'I have cash',
                              _selectedCashAmount == 'I have cash',
                              () => setModalState(() {
                                _selectedCashAmount = 'I have cash';
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed:
                                () => setModalState(() {
                                  _selectedPaymentType = null;
                                  _selectedCashAmount = null;
                                }),
                            child: Text(
                              "Back to Payment Methods",
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  CustomRoundedButton(
                    text: _isRequestingTaxi ? 'Requesting...' : 'TakeTaxi',
                    backgroundColor:
                        canRequestTaxi && !_isRequestingTaxi
                            ? AppColors.primary
                            : Colors.grey,
                    onPressed:
                        canRequestTaxi
                            ? () async {
                              setModalState(() {
                                _isRequestingTaxi = true;
                              });
                              // Get the HomeController instance
                              final homeController =
                                  Provider.of<HomeController>(
                                    context,
                                    listen: false,
                                  );

                              // Set the destination first
                              if (_selectedDestination != null) {
                                await widget.onLocationSelected(
                                  _selectedDestination!,
                                );
                              }

                              await homeController.onLocationSelected(
                                _selectedDestination!,
                              );

                              // Set payment method
                              if (_selectedPaymentType == 'Momo') {
                                homeController.updateSelectedPaymentMode(
                                  PaymentMode.momo,
                                );
                              } else if (_selectedPaymentType ==
                                  'Orange Money') {
                                homeController.updateSelectedPaymentMode(
                                  PaymentMode.orange,
                                );
                              } else if (_selectedPaymentType == 'Directly') {
                                homeController.updateSelectedPaymentMode(
                                  PaymentMode.directCash,
                                );
                                homeController.selectCashDenomination(
                                  _selectedCashAmount,
                                );
                              }

                              // Set estimated fare (you might want to calculate this based on distance)
                              homeController.setEstimatedFare(
                                1500,
                              ); // Default fare

                              // Close the bottom sheet
                              Navigator.of(sheetContext).pop();

                              // Navigate back to home screen
                              context.pop();
                            }
                            : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOptionTile(
    BuildContext context,
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: isSelected ? AppColors.primary : AppColors.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCashAmountChip(
    BuildContext context,
    String amount,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isSelected ? Colors.white : AppColors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRequestButtonEnabled =
        _selectedDestination != null && _selectedDestination!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Where to?",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(color: AppColors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: "Enter destination",
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Estimated Fare",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "The fare for this shared ride is estimated to be between 1,500 and 2,000 CFA francs. The final fare may vary depending on the route and traffic conditions.",
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.black),
            ),
            Expanded(
              child:
                  _selectedDestination != null
                      ? const SizedBox.shrink()
                      : (_searchController.text.isEmpty
                          ? const SizedBox.shrink()
                          : (placesList.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_off,
                                      size: 48,
                                      color: AppColors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No results found",
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textMuted,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                // Display results
                                itemCount: placesList.length,
                                itemBuilder: (context, index) {
                                  final placeDescription =
                                      placesList[index]['description'];
                                  return ListTile(
                                    leading: Icon(
                                      Icons.location_on,
                                      color: AppColors.grey,
                                    ),
                                    title: Text(
                                      placeDescription,
                                      style: GoogleFonts.poppins(
                                        color: AppColors.black,
                                      ),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedDestination = placeDescription;
                                        _searchController.text =
                                            placeDescription;
                                        _searchController.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset:
                                                    _searchController
                                                        .text
                                                        .length,
                                              ),
                                            );
                                        placesList = [];
                                      });
                                    },
                                  );
                                },
                              ))),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: CustomRoundedButton(
                  text: 'Continue',
                  backgroundColor:
                      isRequestButtonEnabled ? AppColors.primary : Colors.grey,
                  onPressed:
                      isRequestButtonEnabled
                          ? () {
                            if (_selectedDestination != null) {
                              _showPaymentOptionsBottomSheet();
                            }
                          }
                          : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
