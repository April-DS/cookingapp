import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback? onTap;
  final int currentIndex;
  final int totalCards;

  const RecipeCard({
    required this.recipe,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    this.onTap,
    required this.currentIndex,
    required this.totalCards,
    Key? key,
  }) : super(key: key);

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _animController;
  late Animation<double> _animation;
  bool _isAnimating = false;
  bool _hasDragged = false;

  static const double _swipeThreshold = 50.0;
  static const double _flyOffDistance = 500.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this);
    _animController.addListener(_onAnimationTick);
    _animController.addStatusListener(_onAnimationStatus);
  }

  @override
  void dispose() {
    _animController.removeListener(_onAnimationTick);
    _animController.removeStatusListener(_onAnimationStatus);
    _animController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    setState(() {
      _dragOffset = _animation.value;
    });
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_isAnimating) {
        _isAnimating = false;
        // Determine if it was a fly-off
        if (_dragOffset.abs() >= _flyOffDistance - 1) {
          if (_dragOffset > 0) {
            widget.onSwipeRight();
          } else {
            widget.onSwipeLeft();
          }
          // Reset offset after callback
          setState(() => _dragOffset = 0);
        }
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    _hasDragged = true;
    setState(() {
      _dragOffset += details.delta.dx;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final velocity = details.primaryVelocity ?? 0;

    if (_dragOffset > _swipeThreshold || velocity > 800) {
      // Fly off to the right
      _flyOff(_flyOffDistance);
    } else if (_dragOffset < -_swipeThreshold || velocity < -800) {
      // Fly off to the left
      _flyOff(-_flyOffDistance);
    } else {
      // Spring back to center
      _springBack();
    }
  }

  void _flyOff(double target) {
    _isAnimating = true;
    _animation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut,
      ),
    );
    _animController.duration = const Duration(milliseconds: 250);
    _animController.forward(from: 0);
  }

  void _springBack() {
    _isAnimating = true;

    // Estimate spring duration based on offset distance
    final duration = (_dragOffset.abs() * 4 + 200).clamp(200.0, 600.0);
    _animController.duration = Duration(milliseconds: duration.toInt());

    // Use an elastic curve for a bouncy snap-back
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.elasticOut,
      ),
    );
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate indicator opacity based on drag distance
    final swipeProgress = (_dragOffset.abs() / _swipeThreshold).clamp(0.0, 1.0);
    // Slight rotation based on drag
    final rotation = _dragOffset / 1500;

    return GestureDetector(
      onTap: () {
        if (!_isAnimating && !_hasDragged && widget.onTap != null) {
          widget.onTap!();
        }
      },
      onHorizontalDragStart: (_) {
        _hasDragged = false;
      },
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Transform.translate(
        offset: Offset(_dragOffset, 0),
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            // Fade out as card flies off
            opacity: _isAnimating && _dragOffset.abs() > _swipeThreshold
                ? (1 - ((_dragOffset.abs() - _swipeThreshold) / (_flyOffDistance - _swipeThreshold)).clamp(0.0, 0.6))
                : 1.0,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.cardCornerRadius),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppConstants.cardCornerRadius),
                child: Stack(
                  children: [
                    _buildCardContent(context),
                    // Left red indicator (skip)
                    if (_dragOffset < 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          color: AppTheme.error.withValues(alpha:swipeProgress),
                        ),
                      ),
                    // Right green indicator (like)
                    if (_dragOffset > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          color: AppTheme.success.withValues(alpha:swipeProgress),
                        ),
                      ),
                    // Swipe label overlay
                    if (swipeProgress > 0.3)
                      Positioned(
                        top: 24,
                        left: _dragOffset > 0 ? 24 : null,
                        right: _dragOffset < 0 ? 24 : null,
                        child: Transform.rotate(
                          angle: _dragOffset > 0 ? -0.2 : 0.2,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _dragOffset > 0
                                    ? AppTheme.success
                                    : AppTheme.error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _dragOffset > 0 ? 'KEEP' : 'SKIP',
                              style: TextStyle(
                                color: _dragOffset > 0
                                    ? AppTheme.success
                                    : AppTheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
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
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(AppConstants.cardCornerRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.darkBgSecondary, AppTheme.darkBg],
        ),
      ),
      child: Column(
        children: [
          Expanded(flex: 3, child: _buildImageSection()),
          Expanded(flex: 2, child: _buildInfoSection(context)),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppConstants.cardCornerRadius),
        topRight: Radius.circular(AppConstants.cardCornerRadius),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha:0.3)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final imagePath =
        'assets/recipe_images/${widget.recipe.imageFilename}';

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.pastelMint, AppTheme.pastelPeach],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Text(
            widget.recipe.dishName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.darkBg,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final ingredients =
        widget.recipe.ingredients.parseIngredients();

    return Padding(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipe.dishName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '\u23f1\ufe0f ${StringExtensions.formatDuration(widget.recipe.totalTime)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (widget.recipe.isLight)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelMint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Light',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.darkBg,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '${widget.recipe.kcal} kcal \u2022 ${widget.recipe.proteinG.toStringAsFixed(1)}g protein',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.pastelPeach,
                  fontSize: 12,
                ),
          ),
          SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                ingredients.join(', '),
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
