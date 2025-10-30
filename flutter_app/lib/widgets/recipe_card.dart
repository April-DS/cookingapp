import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final int currentIndex;
  final int totalCards;

  const RecipeCard({
    required this.recipe,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.currentIndex,
    required this.totalCards,
    Key? key,
  }) : super(key: key);

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = Offset(
        _dragOffset.dx + details.delta.dx,
        _dragOffset.dy + details.delta.dy,
      );
      _isDragging = true;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    const swipeThreshold = 100.0;
    const velocityThreshold = 500.0;

    final velocity = details.primaryVelocity ?? 0;
    final distance = _dragOffset.dx;

    if (distance.abs() > swipeThreshold ||
        velocity.abs() > velocityThreshold) {
      if (distance > 0 || velocity > velocityThreshold) {
        // Swipe right - like
        _animateExit(true);
      } else {
        // Swipe left - skip
        _animateExit(false);
      }
    } else {
      // Reset position
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    }
  }

  void _animateExit(bool isRight) {
    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(isRight ? 500 : -500, 0),
    ).animate(_animationController);

    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward().then((_) {
      if (isRight) {
        widget.onSwipeRight();
      } else {
        widget.onSwipeLeft();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _isDragging && !_animationController.isAnimating
                ? 0.8
                : (_animationController.isAnimating
                    ? _opacityAnimation.value
                    : 1.0),
            child: Transform.translate(
              offset: _animationController.isAnimating
                  ? _offsetAnimation.value
                  : _dragOffset,
              child: Transform.rotate(
                angle: _dragOffset.dx * 0.01,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.cardCornerRadius),
                  ),
                  child: _buildCardContent(context),
                ),
              ),
            ),
          );
        },
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
          // Image section
          Expanded(
            flex: 3,
            child: _buildImageSection(),
          ),
          // Info section
          Expanded(
            flex: 2,
            child: _buildInfoSection(context),
          ),
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
          // Image or placeholder
          _buildImage(),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    try {
      return Image.asset(
        'assets/recipe_images/${widget.recipe.imageFilename}',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(),
      );
    } catch (_) {
      return _buildPlaceholder();
    }
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
        child: Text(
          widget.recipe.dishName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.darkBg,
              ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final ingredients =
        widget.recipe.ingredients.parseIngredients();
    final ingredientPreview =
        ingredients.take(2).join(', ');

    return Padding(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipe.dishName,
                      style: Theme.of(context).textTheme.displayMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '⏱️ ${StringExtensions.formatDuration(widget.recipe.totalTime)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (widget.recipe.isLight)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelMint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Light',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.darkBg,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          // Nutrition and ingredients
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.recipe.kcal.toCalorieString()} • ${widget.recipe.proteinG.toProteinString()}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.pastelPeach,
                    ),
              ),
              SizedBox(height: 4),
              Text(
                ingredientPreview,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}