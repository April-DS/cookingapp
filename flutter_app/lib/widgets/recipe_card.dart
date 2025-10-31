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

class _RecipeCardState extends State<RecipeCard> {
  double _dragOffset = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    const swipeThreshold = 50.0;

    if (_dragOffset > swipeThreshold) {
      // Swipe right - like
      widget.onSwipeRight();
    } else if (_dragOffset < -swipeThreshold) {
      // Swipe left - skip
      widget.onSwipeLeft();
    }

    // Reset
    setState(() => _dragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Transform.translate(
        offset: Offset(_dragOffset, 0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.cardCornerRadius),
          ),
          child: _buildCardContent(context),
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
                colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
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
        print('Image error: $imagePath - $error');
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
                      '⏱️ ${StringExtensions.formatDuration(widget.recipe.totalTime)}',
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
            '${widget.recipe.kcal} kcal • ${widget.recipe.proteinG.toStringAsFixed(1)}g protein',
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