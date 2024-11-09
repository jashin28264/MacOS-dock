import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DockDemo(),
    );
  }
}

class AppIcon {
  final String label;
  final List<Color> colors;
  final IconData icon;

  AppIcon({
    required this.label,
    required this.colors,
    required this.icon,
  });
}

class DockDemo extends StatefulWidget {
  const DockDemo({super.key});

  @override
  _DockDemoState createState() => _DockDemoState();
}

class _DockDemoState extends State<DockDemo> {
  final List<AppIcon> apps = [
    AppIcon(
      label: 'Messages',
      colors: [Color(0xFF5CE466), Color(0xFF00D53F)],
      icon: Icons.message,
    ),
    AppIcon(
      label: 'Safari',
      colors: [Color(0xFF4C9FFF), Color(0xFF0069E6)],
      icon: Icons.public,
    ),
    AppIcon(
      label: 'Photos',
      colors: [Color(0xFFFF5C5C), Color(0xFFFF3B3B)],
      icon: Icons.photo,
    ),
    AppIcon(
      label: 'Music',
      colors: [Color(0xFFFF5CAA), Color(0xFFFF2D89)],
      icon: Icons.music_note,
    ),
    AppIcon(
      label: 'Settings',
      colors: [Color(0xFF8C8C8C), Color(0xFF666666)],
      icon: Icons.settings,
    ),
  ];

  Map<int, Offset> containerPositions = {};
  List<int> dockSlots = [0, 1, 2, 3, 4];
  int? draggedIndex;
  int? dragOverIndex;

  final double slotWidth = 70.0;
  final double dockPadding = 10.0;
  final double minDockWidth = 100.0;

  double getDockWidth(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width * 0.9;
    double idealWidth = (dockSlots.length * slotWidth) + (dockPadding * 2);
    return idealWidth.clamp(minDockWidth, maxWidth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2E),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ColorFilter.mode(
                      Colors.white.withOpacity(0.1),
                      BlendMode.srcOver,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 90,
                      width: getDockWidth(context),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: dockPadding),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(dockSlots.length, (slotIndex) {
                              return _buildDockSlot(slotIndex);
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ...containerPositions.entries.map((entry) {
            return Positioned(
              left: entry.value.dx,
              top: entry.value.dy,
              child: _buildDraggableContainer(entry.key, inDock: false),
            );
          })
        ],
      ),
    );
  }

  Widget _buildDockSlot(int slotIndex) {
    final containerIndex = dockSlots[slotIndex];
    return DragTarget<int>(
      onWillAccept: (fromIndex) {
        setState(() => dragOverIndex = slotIndex);
        return true;
      },
      onLeave: (data) {
        setState(() => dragOverIndex = null);
      },
      onAccept: (fromIndex) {
        setState(() {
          dragOverIndex = null;
          if (!dockSlots.contains(fromIndex)) {
            dockSlots.insert(slotIndex, fromIndex);
          } else {
            final fromPosition = dockSlots.indexOf(fromIndex);
            final temp = dockSlots[fromPosition];
            dockSlots[fromPosition] = dockSlots[slotIndex];
            dockSlots[slotIndex] = temp;
          }
          containerPositions.remove(fromIndex);
        });
      },
      builder: (context, acceptedData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: slotWidth,
          height: 90,
          margin: EdgeInsets.symmetric(
            horizontal: dragOverIndex == slotIndex ? 8 : 0,
          ),
          child: Center(
            child: containerIndex != null && dockSlots.contains(containerIndex)
                ? _buildDraggableContainer(containerIndex, inDock: true)
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  Widget _buildDraggableContainer(int index, {required bool inDock}) {
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.1,
          child: _buildAppIcon(index),
        ),
      ),
      onDragStarted: () => setState(() => draggedIndex = index),
      onDragEnd: (details) {
        setState(() {
          if (inDock) {
            final dropPosition = details.offset;
            final dockBottom = MediaQuery.of(context).size.height - 120;
            if (dropPosition.dy < dockBottom - 100) {
              dockSlots.remove(index);
              containerPositions[index] = dropPosition;
            }
          } else {
            _snapToDockOrKeepPosition(index, details.offset);
          }
          draggedIndex = null;
        });
      },
      childWhenDragging: const SizedBox(
        width: 60,
        height: 60,
      ),
      child: inDock && containerPositions.containsKey(index)
          ? const SizedBox.shrink()
          : _buildAppIcon(index),
    );
  }

  void _snapToDockOrKeepPosition(int index, Offset offset) {
    final dockBottom = MediaQuery.of(context).size.height - 120;
    bool isNearDock = (offset.dy > dockBottom - 50 && offset.dy < dockBottom + 50);

    if (isNearDock) {
      if (!dockSlots.contains(index)) {
        dockSlots.add(index);
      }
      containerPositions.remove(index);
    } else {
      containerPositions[index] = offset;
    }
  }

  Widget _buildAppIcon(int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: apps[index].colors,
            ),
            boxShadow: [
              BoxShadow(
                color: apps[index].colors[1].withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            apps[index].icon,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          apps[index].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}