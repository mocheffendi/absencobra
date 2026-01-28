import 'package:flutter/material.dart';
import 'package:cobra_apps/utility/settings.dart';
import 'package:cobra_apps/utility/formatters.dart';
import 'package:cobra_apps/pages/patrol_image_preview_page.dart';
import 'package:cobra_apps/providers/patrol_provider.dart';

class DashboardTablePatrol extends StatelessWidget {
  final String title;
  final List<String> headers;
  final PatrolState patrolState;

  const DashboardTablePatrol({
    super.key,
    required this.title,
    required this.headers,
    required this.patrolState,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12.0),
                ),
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Table(
              border: TableBorder.symmetric(
                inside: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                outside: BorderSide(
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                  children: headers
                      .map(
                        (h) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            h,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (patrolState.isLoading)
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      SizedBox(),
                    ],
                  )
                else if (patrolState.error != null)
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Error: ${patrolState.error}",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      SizedBox(),
                    ],
                  )
                else if (patrolState.patrolList.isEmpty)
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Tidak ada data",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(),
                    ],
                  )
                else
                  ...patrolState.patrolList.map<TableRow>((row) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatPatrolDateTime(row.timestamp),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              if (row.status.isNotEmpty)
                                Text(
                                  row.status,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (row.address.isNotEmpty)
                                Text(
                                  row.address,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: row.fotoUrl.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    final imageUrl =
                                        '$kBaseUrl$kPatrolUrl${row.fotoUrl}';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PatrolImagePreviewPage(
                                          imageUrl: imageUrl,
                                          heroTag: 'patrol-${row.id}',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Hero(
                                    tag: 'patrol-${row.id}',
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          '$kBaseUrl$kPatrolUrl${row.fotoUrl}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey,
                                                    size: 20,
                                                  ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 20,
                                ),
                        ),
                      ],
                    );
                  }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
