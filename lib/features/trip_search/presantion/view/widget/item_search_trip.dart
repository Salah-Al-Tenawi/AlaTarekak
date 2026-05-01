import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/status_trip.dart';

class ItemSearchTrip extends StatefulWidget {
  final TripModel trip;
  const ItemSearchTrip({super.key, required this.trip});

  @override
  State<ItemSearchTrip> createState() => _ItemSearchTripState();
}

class _ItemSearchTripState extends State<ItemSearchTrip> {
  @override
  Widget build(BuildContext context) {
    final statusInfo = getStatusInfo(widget.trip.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: MyColors.accent, width: 0.1)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Get.toNamed(RouteName.tripDetails, arguments: widget.trip.id);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: MyColors.primary.withOpacity(0.3),
                              width: 2,
                            ),
                            image: widget.trip.driver.avatar != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        widget.trip.driver.avatar!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: widget.trip.driver.avatar == null
                              ? const Icon(Icons.person,
                                  color: MyColors.primary, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.trip.driver.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: MyColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: statusInfo.color.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      statusInfo.text,
                      style: TextStyle(
                        color: statusInfo.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.airline_seat_recline_normal,
                        size: 16, color: MyColors.primary.withOpacity(0.7)),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        height: 1,
                        color: Colors.grey.shade300,
                        indent: 8,
                        endIndent: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Locations
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LocationRowModern(
                    icon: Icons.circle,
                    iconColor: MyColors.primary,
                    text: widget.trip.pickup.address,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: Container(
                      height: 20,
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LocationRowModern(
                    icon: Icons.location_pin,
                    iconColor: MyColors.accent,
                    text: widget.trip.destination.address,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 30.w),
                    child: _InfoChip(
                      icon: Icons.calendar_today,
                      label: DateTimeUtils.formatDate(widget.trip.departure),
                      color: MyColors.primary,
                    ),
                  ),
                  const Spacer(),
                  _InfoChip(
                    icon: Icons.access_time,
                    label: DateTimeUtils.formatTime(widget.trip.departure),
                    color: MyColors.accent,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: _InfoChip(
                      icon: Icons.price_change,
                      label:
                          " تكلفة الراكب الواحد   ${widget.trip.pricePerSeat} ل.س",
                      color: Colors.red,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: _InfoChip(
                      icon: Icons.event_seat,
                      label:
                          "${widget.trip.seatsAvailable} مقاعد متاحة | ${widget.trip.seatsBooked} محجوزة",
                      color: Colors.red.shade200,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LocationRowModern extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _LocationRowModern(
      {required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: MyColors.textPrimary
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
