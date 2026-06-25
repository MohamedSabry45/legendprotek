import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

import 'dart:ui' as ui;

import 'package:reservation_workshop/config/routes/routes_name.dart';

import 'package:reservation_workshop/modules/customer/domain/entities/customer_car.dart';



class HomeHeroSection extends StatefulWidget {

  final ScrollController scrollController;

  final String greeting;

  final String carLabel;

  final List<CustomerCar> cars;

  final int? selectedCarId;

  final Function(int?) onCarSelected;



  const HomeHeroSection({

    super.key,

    required this.scrollController,

    required this.greeting,

    required this.carLabel,

    required this.cars,

    required this.selectedCarId,

    required this.onCarSelected,

  });



  @override

  State<HomeHeroSection> createState() => _HomeHeroSectionState();

}



class _HomeHeroSectionState extends State<HomeHeroSection> {

  @override

  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.sizeOf(context).width;

    final isMobile = screenWidth < 600;



    return SizedBox(

      height: MediaQuery.of(context).size.height,

      child: AnimatedBuilder(

        animation: widget.scrollController,

        builder: (context, child) {

          final scrollOffset = widget.scrollController.hasClients

              ? widget.scrollController.offset

              : 0.0;



          // Calculate opacity and transform for each element

          final logoOpacity = _calculateOpacity(scrollOffset, 0, 150);

          final logoOffset = _calculateOffset(scrollOffset, 0, 150);

          final logoScale = _calculateScale(scrollOffset, 0, 150);



          final headlineOpacity = _calculateOpacity(scrollOffset, 50, 220);

          final headlineOffset = _calculateOffset(scrollOffset, 50, 220);

          final headlineScale = _calculateScale(scrollOffset, 50, 220);



          final descriptionOpacity = _calculateOpacity(scrollOffset, 120, 300);

          final descriptionOffset = _calculateOffset(scrollOffset, 120, 300);

          final descriptionScale = _calculateScale(scrollOffset, 120, 300);



          final buttonsOpacity = _calculateOpacity(scrollOffset, 180, 380);

          final buttonsOffset = _calculateOffset(scrollOffset, 180, 380);

          final buttonsScale = _calculateScale(scrollOffset, 180, 380);



          final scrollIndicatorOpacity = _calculateOpacity(scrollOffset, 0, 100);



          return Stack(

            children: [

              // Background Image with Parallax

              Positioned.fill(

                child: Transform.translate(

                  offset: Offset(0, scrollOffset * 0.3),

                  child: Image.asset(

                    'assets/images/bgd.png',

                    fit: BoxFit.cover,

                  ),

                ),

              ),

              // Dark overlay

              Positioned.fill(

                child: Container(

                  decoration: BoxDecoration(

                    gradient: LinearGradient(

                      begin: Alignment.topCenter,

                      end: Alignment.bottomCenter,

                      colors: [

                        Colors.black.withOpacity(0.7),

                        Colors.black.withOpacity(0.5),

                        Colors.black.withOpacity(0.7),

                      ],

                    ),

                  ),

                ),

              ),

              // Greeting and Car Info - Left/Right based on language

              Positioned(

                top: isMobile ? 160 : 180,

                left: isMobile ? 16 : 32,

                right: isMobile ? 16 : 32,

                child: Directionality(

                  textDirection: context.locale.languageCode == 'ar' 

                      ? ui.TextDirection.rtl 

                      : ui.TextDirection.ltr,

                  child: Row(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Expanded(

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            _buildGreeting(widget.greeting, isMobile),

                            const SizedBox(height: 8),

                            _buildCustomDropdown(context, isMobile),

                          ],

                        ),

                      ),

                    ],

                  ),

                ),

              ),

              // Hero Content

              Center(

                child: Column(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    const SizedBox(height: 40),

                    // Logo with golden glow

                    Opacity(

                      opacity: logoOpacity,

                      child: Transform.translate(

                        offset: Offset(0, -logoOffset),

                        child: Transform.scale(

                          scale: logoScale,

                          child: Container(

                            decoration: BoxDecoration(

                              boxShadow: [

                                BoxShadow(

                                  color: const Color(0xFFD4AF37).withOpacity(0.4),

                                  blurRadius: 50,

                                  spreadRadius: 0,

                                ),

                              ],

                            ),

                            child: Image.asset(

                              'assets/images/logo.png',

                              width: isMobile ? 180 : 240,

                              height: isMobile ? 180 : 240,

                            ),

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(height: 32),

                    // Headline

                    Opacity(

                      opacity: headlineOpacity,

                      child: Transform.translate(

                        offset: Offset(0, -headlineOffset),

                        child: Transform.scale(

                          scale: headlineScale,

                          child: ShaderMask(

                            shaderCallback: (bounds) => const LinearGradient(

                              colors: [Color(0xFFFFFFFF), Color(0xFFD4AF37), Color(0xFFB8942E)],

                              stops: [0.0, 0.5, 1.0],

                            ).createShader(bounds),

                            child: Text(

                              'home.hero_headline'.tr(),

                              style: TextStyle(

                                fontSize: isMobile ? 28 : 42,

                                fontWeight: FontWeight.bold,

                                color: Colors.white,

                                letterSpacing: 2,

                                height: 1.2,

                              ),

                              textAlign: TextAlign.center,

                            ),

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(height: 24),

                    // Description

                    Opacity(

                      opacity: descriptionOpacity,

                      child: Transform.translate(

                        offset: Offset(0, -descriptionOffset),

                        child: Transform.scale(

                          scale: descriptionScale,

                          child: SizedBox(

                            width: isMobile ? 300 : 600,

                            child: Text(

                              'home.hero_description'.tr(),

                              style: TextStyle(

                                fontSize: isMobile ? 14 : 18,

                                color: Colors.white.withOpacity(0.7),

                                letterSpacing: 1,

                                height: 1.5,

                                fontWeight: FontWeight.w400,

                              ),

                              textAlign: TextAlign.center,

                            ),

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(height: 40),

                    // Buttons

                    Opacity(

                      opacity: buttonsOpacity,

                      child: Transform.translate(

                        offset: Offset(0, -buttonsOffset),

                        child: Transform.scale(

                          scale: buttonsScale,

                          child: Row(

                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [

                              // Primary CTA Button

                              GestureDetector(

                                onTap: () => Navigator.pushNamed(context, RoutesName.mainScreen, arguments: 2),

                                child: Container(

                                  decoration: BoxDecoration(

                                    gradient: const LinearGradient(

                                      colors: [Color(0xFFD4AF37), Color(0xFFB8942E)],

                                    ),

                                    borderRadius: BorderRadius.circular(8),

                                    boxShadow: [

                                      BoxShadow(

                                        color: const Color(0xFFD4AF37).withOpacity(0.3),

                                        blurRadius: 20,

                                        offset: const Offset(0, 4),

                                      ),

                                    ],

                                  ),

                                  child: Padding(

                                    padding: EdgeInsets.symmetric(

                                      horizontal: isMobile ? 32 : 48,

                                      vertical: isMobile ? 14 : 18,

                                    ),

                                    child: Text(

                                      'home.hero_primary_cta'.tr().toUpperCase(),

                                      style: TextStyle(

                                        fontSize: isMobile ? 14 : 16,

                                        fontWeight: FontWeight.bold,

                                        color: Colors.black,

                                        letterSpacing: 2,

                                      ),

                                    ),

                                  ),

                                ),

                              ),

                              const SizedBox(width: 20),

                              // Secondary CTA Button

                              GestureDetector(

                                onTap: () => Navigator.pushNamed(context, RoutesName.chooseCarScreen),

                                child: Container(

                                  decoration: BoxDecoration(

                                    border: Border.all(

                                      color: const Color(0xFFD4AF37),

                                      width: 1.5,

                                    ),

                                    borderRadius: BorderRadius.circular(8),

                                  ),

                                  child: Padding(

                                    padding: EdgeInsets.symmetric(

                                      horizontal: isMobile ? 32 : 48,

                                      vertical: isMobile ? 14 : 18,

                                    ),

                                    child: Text(

                                      'home.hero_secondary_cta'.tr().toUpperCase(),

                                      style: TextStyle(

                                        fontSize: isMobile ? 14 : 16,

                                        fontWeight: FontWeight.bold,

                                        color: const Color(0xFFD4AF37),

                                        letterSpacing: 2,

                                      ),

                                    ),

                                  ),

                                ),

                              ),

                            ],

                          ),

                        ),

                      ),

                    ),

                  ],

                ),

              ),

              // Scroll indicator at bottom

              Positioned(

                bottom: 64,

                left: 0,

                right: 0,

                child: Opacity(

                  opacity: scrollIndicatorOpacity,

                  child: Column(

                    children: [

                      Text(

                        'home.hero_scroll_hint'.tr().toUpperCase(),

                        style: TextStyle(

                          fontSize: 10,

                          color: Colors.white.withOpacity(0.3),

                          letterSpacing: 4,

                          fontWeight: FontWeight.w500,

                        ),

                      ),

                      const SizedBox(height: 12),

                      Container(

                        width: 1,

                        height: 64,

                        decoration: BoxDecoration(

                          gradient: LinearGradient(

                            begin: Alignment.topCenter,

                            end: Alignment.bottomCenter,

                            colors: [

                              const Color(0xFFD4AF37),

                              Colors.transparent,

                            ],

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

              ),

            ],

          );

        },

      ),

    );

  }



  double _calculateOpacity(double scrollOffset, double start, double end) {

    if (scrollOffset <= start) return 1.0;

    if (scrollOffset >= end) return 0.0;

    return 1.0 - ((scrollOffset - start) / (end - start));

  }



  double _calculateOffset(double scrollOffset, double start, double end) {

    if (scrollOffset <= start) return 0.0;

    if (scrollOffset >= end) return 50.0;

    return ((scrollOffset - start) / (end - start)) * 50.0;

  }



  double _calculateScale(double scrollOffset, double start, double end) {

    if (scrollOffset <= start) return 1.0;

    if (scrollOffset >= end) return 0.9;

    return 1.0 - ((scrollOffset - start) / (end - start)) * 0.1;

  }



  Widget _buildCarLabel(String carLabel, bool isMobile) {

    // Parse car label to make plate number yellow

    // Format: "device model plate"

    final parts = carLabel.split(' ');

    if (parts.length < 2) {

      return Text(

        carLabel,

        style: TextStyle(

          fontSize: isMobile ? 14 : 16,

          color: Colors.white,

          fontWeight: FontWeight.w500,

        ),

        maxLines: 1,

        overflow: TextOverflow.ellipsis,

      );

    }

    

    // Assume last part is plate number

    final plateNumber = parts.last;

    final carName = parts.sublist(0, parts.length - 1).join(' ');

    

    return RichText(

      text: TextSpan(

        children: [

          TextSpan(

            text: carName,

            style: TextStyle(

              fontSize: isMobile ? 14 : 16,

              color: Colors.white,

              fontWeight: FontWeight.w500,

            ),

          ),

          TextSpan(

            text: ' $plateNumber',

            style: TextStyle(

              fontSize: isMobile ? 14 : 16,

              color: const Color(0xFFD4AF37),

              fontWeight: FontWeight.w500,

            ),

          ),

        ],

      ),

      maxLines: 1,

      overflow: TextOverflow.ellipsis,

    );

  }



  Widget _buildGreeting(String greeting, bool isMobile) {

    // Parse greeting to make name yellow

    // Format: "Hello, Name" or "مرحبا، الاسم"

    if (context.locale.languageCode == 'ar') {

      final parts = greeting.split('،');

      if (parts.length > 1) {

        return RichText(

          text: TextSpan(

            children: [

              TextSpan(

                text: parts[0] + '،',

                style: TextStyle(

                  fontSize: isMobile ? 18 : 22,

                  color: Colors.white,

                  fontWeight: FontWeight.w700,

                ),

              ),

              TextSpan(

                text: ' ' + parts.sublist(1).join('،'),

                style: TextStyle(

                  fontSize: isMobile ? 18 : 22,

                  color: const Color(0xFFD4AF37),

                  fontWeight: FontWeight.w700,

                ),

              ),

            ],

          ),

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

        );

      }

    } else {

      final parts = greeting.split(',');

      if (parts.length > 1) {

        return RichText(

          text: TextSpan(

            children: [

              TextSpan(

                text: parts[0] + ',',

                style: TextStyle(

                  fontSize: isMobile ? 18 : 22,

                  color: Colors.white,

                  fontWeight: FontWeight.w700,

                ),

              ),

              TextSpan(

                text: ' ' + parts.sublist(1).join(','),

                style: TextStyle(

                  fontSize: isMobile ? 18 : 22,

                  color: const Color(0xFFD4AF37),

                  fontWeight: FontWeight.w700,

                ),

              ),

            ],

          ),

          maxLines: 1,

          overflow: TextOverflow.ellipsis,

        );

      }

    }

    

    return Text(

      greeting,

      style: TextStyle(

        fontSize: isMobile ? 18 : 22,

        color: Colors.white,

        fontWeight: FontWeight.w700,

      ),

      maxLines: 1,

      overflow: TextOverflow.ellipsis,

    );

  }



  Widget _buildCustomDropdown(BuildContext context, bool isMobile) {

    return PopupMenuButton<int>(

      initialValue: widget.selectedCarId,

      position: PopupMenuPosition.under,

      color: const Color(0xFF050505),

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(12),

      ),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(

            Icons.directions_car_filled_outlined,

            size: isMobile ? 18 : 20,

            color: const Color(0xFFD4AF37),

          ),

          const SizedBox(width: 8),

          Flexible(

            child: _buildCarLabel(widget.carLabel, isMobile),

          ),

          const SizedBox(width: 4),

          Icon(

            Icons.keyboard_arrow_down,

            size: isMobile ? 18 : 20,

            color: const Color(0xFFD4AF37),

          ),

        ],

      ),

      itemBuilder: (context) {

        if (widget.cars.isEmpty) {

          return [

            PopupMenuItem<int>(

              value: null,

              enabled: false,

              height: 56,

              child: Text(

                'home.no_cars'.tr(),

                style: TextStyle(

                  fontSize: isMobile ? 16 : 18,

                  color: Colors.white.withOpacity(0.7),

                ),

              ),

            ),

          ];

        }

        

        final items = widget.cars.map((car) {

          final carLabel = '${car.device} ${car.model} ${(car.plateNumber ?? '').trim()}'.trim();

          return PopupMenuItem<int>(

            value: car.id,

            height: 56,

            child: _buildCarLabel(carLabel, isMobile),

          );

        }).toList();

        

        items.add(

          PopupMenuItem<int>(

            value: -1,

            height: 56,

            child: Row(

              children: [

                Icon(

                  Icons.add,

                  size: isMobile ? 18 : 20,

                  color: const Color(0xFFD4AF37),

                ),

                const SizedBox(width: 8),

                Text(

                  'home.add_car'.tr(),

                  style: TextStyle(

                    fontSize: isMobile ? 16 : 18,

                    color: const Color(0xFFD4AF37),

                    fontWeight: FontWeight.w600,

                  ),

                ),

              ],

            ),

          ),

        );

        

        return items;

      },

      onSelected: (value) {

        if (value == -1) {

          Navigator.pushNamed(context, RoutesName.chooseCarScreen);

        } else if (value != null) {

          widget.onCarSelected(value);

        }

      },

    );

  }

}

