import 'package:flutter/material.dart';
import 'package:otpand/objects/history.dart';
import 'package:otpand/objects/search_history.dart';
import 'package:otpand/utils/colors.dart';

class HistoryWidget extends StatefulWidget {
  final void Function()? onHistorySelected;

  const HistoryWidget({super.key, this.onHistorySelected});

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  List<SearchHistory> searchHistory = SearchHistory.currentHistory.value;

  @override
  void initState() {
    super.initState();
    SearchHistory.currentHistory.addListener(_loadHistory);
  }

  @override
  void dispose() {
    SearchHistory.currentHistory.removeListener(_loadHistory);
    super.dispose();
  }

  void _loadHistory() {
    setState(() {
      searchHistory = SearchHistory.currentHistory.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (searchHistory.isEmpty) {
      return const SizedBox();
    }

    final recentHistory = searchHistory.take(5).toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent searches',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentHistory.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final history = recentHistory[index];
              return _HistoryCard(
                history: history,
                onTap: () {
                  History.update(
                    fromLocation: history.fromLocation,
                    toLocation: history.toLocation,
                  );

                  if (widget.onHistorySelected != null) {
                    widget.onHistorySelected!();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final SearchHistory history;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.history,
    required this.onTap,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: primary500,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              history.fromLocationDisplayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              history.toLocationDisplayName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Profile ${history.profileId}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimeAgo(history.searchedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
