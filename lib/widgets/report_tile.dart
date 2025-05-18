import 'package:flutter/material.dart';
import 'package:governmentapp/models/reports.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ReportTile extends StatelessWidget {
  final Report report;
  final Function()? onPressedView;
  final Function()? onPressedUpdateStatus;
  final Function()? onPressedDelete;
  final bool isGovernment;

  const ReportTile({
    super.key,
    required this.report,
    this.onPressedView,
    this.onPressedUpdateStatus,
    this.onPressedDelete,
    this.isGovernment = false,
  });

  Color _getStatusColor() {
    switch (report.status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report header
          ListTile(
            title: Text(
              report.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(report.timestamp),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report.status,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(report.description),
          ),
          
          // Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Map preview
          if (report.latitude != 0 && report.longitude != 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(report.latitude, report.longitude),
                      initialZoom: 15.0,
                      interactionOptions: InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.governmentapp',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(report.latitude, report.longitude),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Images
          if (report.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Photos (${report.imageUrls.length})",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // Show full image
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: Image.network(
                                  report.imageUrls[index],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 8),
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(report.imageUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onPressedView != null)
                  TextButton.icon(
                    onPressed: onPressedView,
                    icon: Icon(Icons.visibility),
                    label: Text("View Details"),
                  ),
                if (isGovernment && onPressedUpdateStatus != null)
                  TextButton.icon(
                    onPressed: onPressedUpdateStatus,
                    icon: Icon(Icons.update),
                    label: Text("Update Status"),
                  ),
                if (onPressedDelete != null)
                  TextButton.icon(
                    onPressed: onPressedDelete,
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 