import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';

class FlipRecipeCard extends StatefulWidget {
  final Recipe recipe;
  final bool isCooked;
  final Function(bool) onCookedChanged;

  const FlipRecipeCard({
    required this.recipe,
    required this.isCooked,
    required this.onCookedChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<FlipRecipeCard> createState() => _FlipRecipeCardState();
}

class _FlipRecipeCardState extends State<FlipRecipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_showBack) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_controller.value * 3.14159),
            child: _controller.value < 0.5 ? _buildFront() : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
      ),
      child: Container(
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
            Expanded(flex: 2, child: _buildFrontInfo()),
          ],
        ),
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

  Widget _buildFrontInfo() {
    final ingredients = widget.recipe.ingredients.isNotEmpty
        ? widget.recipe.ingredients.parseIngredients()
        : [];

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
                            decoration: widget.isCooked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: widget.isCooked
                                ? AppTheme.textMuted
                                : AppTheme.textLight,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '⏱️ ${StringExtensions.formatDuration(widget.recipe.totalTime)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.isCooked
                                ? AppTheme.textMuted
                                : AppTheme.textLight,
                          ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${widget.recipe.kcal} kcal • ${widget.recipe.proteinG.toStringAsFixed(1)}g protein',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: widget.isCooked
                                ? AppTheme.textMuted
                                : AppTheme.pastelPeach,
                          ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: widget.isCooked,
                onChanged: (value) {
                  widget.onCookedChanged(value ?? false);
                },
                fillColor: MaterialStateProperty.all(AppTheme.pastelMint),
              ),
            ],
          ),
          SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                ingredients.isNotEmpty 
                    ? ingredients.join(', ')
                    : 'No ingredients',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.isCooked
                          ? AppTheme.textMuted
                          : AppTheme.textLight,
                    ),
                maxLines: null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(AppConstants.cardCornerRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.darkBgSecondary, AppTheme.darkBg],
          ),
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateY(3.14159),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                SizedBox(height: AppConstants.defaultPadding),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.recipe.instructions,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}