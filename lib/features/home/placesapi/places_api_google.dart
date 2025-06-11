import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taketaxi/core/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

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

  final TextEditingController _searchController = TextEditingController();

  void makeSuggestions(String input) async {
    if (input.isEmpty) {
      if (mounted) {
        setState(() {
          placesList = [];
        });
      }
      return;
    }
    String googleApiKey = "AIzaSyBpxYpVUtQlXjQgBCJNDvLkADlgTQ9IbLs";
    String groundURL =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    // Add 'components=country:CM' to restrict results to Cameroon
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
        // Optionally handle error
      }
    }
  }

  @override
  void initState() {
    super.initState();
    tokenForSession = uuid.v4();
    _searchController.addListener(() {
      makeSuggestions(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInputEmpty = _searchController.text.isEmpty;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Where are you going to ?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(Icons.arrow_back, color: AppColors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
        child: Column(
          children: [
            TextFormField(
              style: TextStyle(color: AppColors.white),
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBackground,
                hintText: "Search for a place",
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.search, color: AppColors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Expanded(
              child:
                  isInputEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_location_alt_outlined,
                              size: 48,
                              color: AppColors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Type in a location to search",
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
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
                                SizedBox(height: 16),
                                Text(
                                  "Location not found",
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: placesList.length,
                            itemBuilder: (context, index) {
                              final placeDescription =
                                  placesList[index]['description'];
                              return ListTile(
                                onTap: () async {
                                  widget.onLocationSelected(placeDescription);
                                  context.pop();
                                },
                                title: Text(placeDescription),
                              );
                            },
                          )),
            ),
          ],
        ),
      ),
    );
  }
}
