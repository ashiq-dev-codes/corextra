part of 'network_tab.dart';

// ---------------- Narrow layout ----------------

/// The phone-width detail screen: a back button over the selected request's detail, in place of the wide layout's right-hand pane.
class _NarrowDetailScreen extends StatelessWidget {
  const _NarrowDetailScreen({required this.event, required this.onBack});

  final NetworkEvent event;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BackHandlerScope(
      onBack: onBack,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to requests',
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: onBack,
                ),
                FindText(
                  'Request detail',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _NetworkEventDetail(event: event)),
        ],
      ),
    );
  }
}

// ---------------- Wide layout ----------------

/// The wide-screen layout: the request list on the left, the selected request's detail on the right.
class _MasterDetailView extends StatelessWidget {
  const _MasterDetailView({
    required this.events,
    required this.selected,
    required this.onSelect,
  });

  final List<NetworkEvent> events;
  final NetworkEvent? selected;
  final ValueChanged<NetworkEvent> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedEvent = selected;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    FindText(
                      'Requests',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FindText(
                      '(${events.length})',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: DevToolsScrollToTop(
                  scrollbar: true,
                  builder:
                      (context, controller) => FindListView(
                        controller: controller,
                        itemCount: events.length,
                        itemKey: (index) => events[index].id,
                        indexOfHit: (hit) => _rowIndexOf(events, hit),
                        separatorBuilder:
                            (context, index) => const Divider(
                              height: 1,
                              indent: 12,
                              endIndent: 12,
                            ),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return _CompactNetworkRow(
                            event: event,
                            selected: identical(event, selected),
                            onTap: () => onSelect(event),
                          );
                        },
                      ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child:
              selectedEvent == null
                  ? const DevToolsEmptyState(
                    icon: LucideIcons.mousePointerClick,
                    message: 'Select a request to see its details',
                  )
                  : _NetworkEventDetail(event: selectedEvent),
        ),
      ],
    );
  }
}
