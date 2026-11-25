import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/tab_refresh.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/core/utility/widgets/custom_loader.dart';

import 'package:solufine/features/products/domain/entity/fertilizer_category_entity.dart';
import 'package:solufine/features/products/domain/entity/fertilizer_product_entity.dart';
import 'package:solufine/features/products/domain/entity/product_name.dart';
import 'package:solufine/features/products/presentation/bloc/product_bloc.dart';
import 'package:solufine/features/products/presentation/bloc/product_event.dart';
import 'package:solufine/features/products/presentation/bloc/product_state.dart';
import 'package:solufine/features/products/presentation/pages/widget/category_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// class ProductCategoryScreen extends StatefulWidget {
//   const ProductCategoryScreen({super.key});

//   @override
//   State<ProductCategoryScreen> createState() => _ProductCategoryScreenState();
// }

// class _ProductCategoryScreenState extends State<ProductCategoryScreen> {
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();

//     // Load all categories
//     context.read<ProductBloc>().add(const ProductListingEvent(''));
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _searchCategories(String value) {
//     context.read<ProductBloc>().add(ProductNameListingEvent(value.trim()));
//   }

//   void openProducts(FertilizerCategoryEntity category) {
//     context.push('/productList', extra: category);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundColor,
//       appBar: CustomAppBar(
//         title: 'Product Category',
//         showBackButton: true,
//         onBackTap: () => context.go(AppRouter.home),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.only(left: 16, right: 16),
//         child: Column(
//           children: [
//             _buildSearchBar(),

//             const SizedBox(height: 8),

//             Expanded(
//               child: BlocBuilder<ProductBloc, ProductState>(
//                 builder: (context, state) {
//                   if (state.productStatus == ProductStatus.loading) {
//                     return const CustomLoader(

//             );
//                   }

//                   if (state.productStatus == ProductStatus.failure) {
//                     return Center(
//                       child: Text(state.message, textAlign: TextAlign.center),
//                     );
//                   }

//                   if (state.fertilizerCategoryList.isEmpty) {
//                     return const Center(child: Text('No categories found'));
//                   }

//                   return _buildCategoryGrid(state.fertilizerCategoryList);
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//       child: TextField(
//         controller: _searchController,
//         onChanged: _searchCategories,
//         decoration: InputDecoration(
//           hintText: 'Search category...',
//           prefixIcon: const Icon(Icons.search_rounded),
//           suffixIcon: _searchController.text.isNotEmpty
//               ? IconButton(
//                   onPressed: () {
//                     _searchController.clear();

//                     context.read<ProductBloc>().add(
//                       const ProductListingEvent(''),
//                     );

//                     setState(() {});
//                   },
//                   icon: const Icon(Icons.close_rounded),
//                 )
//               : null,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(22),
//             borderSide: BorderSide(color: Colors.grey.shade200),
//           ),

//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(22),
//             borderSide: BorderSide(color: Colors.grey.shade200),
//           ),

//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(22),
//             borderSide: const BorderSide(color: Color(0xFF087C3A), width: 1.5),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCategoryGrid(List<FertilizerCategoryEntity> categories) {
//     return GridView.builder(
//       padding: const EdgeInsets.only(top: 8, bottom: 16),
//       itemCount: categories.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//         childAspectRatio: 0.85,
//       ),
//       itemBuilder: (context, index) {
//         final category = categories[index];

//         return CategoryCard(
//           category: category,
//           index: index,

//           // IMPORTANT
//           onTap: () => openProducts(category),
//         );
//       },
//     );
//   }
// }

class ProductCategoryScreen extends StatefulWidget {
  const ProductCategoryScreen({super.key});

  @override
  State<ProductCategoryScreen> createState() => _ProductCategoryScreenState();
}

class _ProductCategoryScreenState extends State<ProductCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    TabRefresh.products.addListener(_onTabRefresh);

    // Load categories
    context.read<ProductBloc>().add(const ProductListingEvent(''));
  }

  @override
  void dispose() {
    TabRefresh.products.removeListener(_onTabRefresh);
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCH PRODUCT
  // ============================================================

  void _onTabRefresh() {
    context.read<ProductBloc>().add(const ProductListingEvent(''));
    if (_searchController.text.trim().isNotEmpty) {
      _searchProducts(_searchController.text);
    }
  }

  void _searchProducts(String value) {
    final String query = value.trim();

    setState(() {});

    context.read<ProductBloc>().add(ProductNameListingEvent(query));
  }

  // ============================================================
  // CATEGORY -> PRODUCT LIST
  // ============================================================

  void openProducts(FertilizerCategoryEntity category) {
    context.push('/productList', extra: category);
  }

  // ============================================================
  // SEARCH RESULT -> PRODUCT DETAILS
  // ============================================================

  void _openSearchProduct(ProductEntityy product) {
    debugPrint('OPEN SEARCH PRODUCT: ${product.productName}');

    debugPrint('OPEN SEARCH PRODUCT ID: ${product.productId}');

    // Convert search API ProductEntity
    // to FertilizerProductEntity because your existing
    // ProductDetails screen expects FertilizerProductEntity.
    final FertilizerProductEntity fertilizerProduct = FertilizerProductEntity(
      productId: product.productId,
      productName: product.productName,
      productPath: product.productPath,
      productContents: product.productContents,
      productDosage: product.productDosage,

      // These fields are not returned by search API
      productShortDetails: '',
      diseasePath: '',
      productContentHindi: '',
      productContentMarathi: '',
      productNameMarathi: '',
      productNameHindi: '',
      productNameKannad: '',
    );

    // Clear search before navigation
    _searchController.clear();

    context.read<ProductBloc>().add(const ProductNameListingEvent(''));

    context.push('/productDetails', extra: fertilizerProduct);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(
        title: 'Product Category',
        showBackButton: true,
        onBackTap: () {
          context.go(AppRouter.home);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          children: [
            // ==================================================
            // SEARCH BAR
            // ==================================================
            _buildSearchBar(),

            const SizedBox(height: 4),

            // ==================================================
            // SEARCH RESULTS
            // ==================================================
            BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                return _buildSearchResults(state);
              },
            ),

            const SizedBox(height: 8),

            // ==================================================
            // CATEGORY GRID
            // ==================================================
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  final bool isSearching = _searchController.text
                      .trim()
                      .isNotEmpty;

                  if (!isSearching &&
                      state.productStatus == ProductStatus.loading) {
                    return CustomLoader(color: context.appPrimary);
                  }

                  if (!isSearching && state.fertilizerCategoryList.isEmpty) {
                    return Center(
                      child: Text(
                        'No categories found',
                        style: AppTextStyles.body,
                      ),
                    );
                  }

                  return _buildCategoryGrid(state.fertilizerCategoryList);
                },
              ),
            ),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _searchProducts,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.input.copyWith(color: context.appText),
        decoration: InputDecoration(
          hintText: 'Search product...',
          hintStyle: AppTextStyles.inputHint.copyWith(
            color: context.appSubText,
          ),
          prefixIconColor: context.appPrimary,
          suffixIconColor: context.appSubText,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();

                    context.read<ProductBloc>().add(
                      const ProductNameListingEvent(''),
                    );

                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
          filled: true,
          fillColor: context.appInputBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: context.appBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: context.appBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(color: context.appPrimary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH RESULTS
  // ============================================================

  Widget _buildSearchResults(ProductState state) {
    final String query = _searchController.text.trim();

    // ==========================================================
    // EMPTY SEARCH
    // ==========================================================

    if (query.isEmpty) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // SEARCH LOADING
    // ==========================================================

    if (state.productStatus == ProductStatus.productNameLoading) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(14),
        decoration: _searchDecoration(),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Searching products...', style: AppTextStyles.body),
          ],
        ),
      );
    }

    // ==========================================================
    // SEARCH FAILURE
    // ==========================================================

    if (state.productStatus == ProductStatus.failure) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(14),
        decoration: _searchDecoration(),
        child: Text(
          state.message,
          style: AppTextStyles.body.copyWith(color: context.appError),
        ),
      );
    }

    // ==========================================================
    // NO PRODUCT FOUND
    // ==========================================================

    if (state.productStatus == ProductStatus.productNameSuccess &&
        state.productNames.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(14),
        decoration: _searchDecoration(),
        child: Row(
          children: [
            Icon(Icons.search_off_rounded, color: context.appSubText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No product found for "$query"',
                style: AppTextStyles.body.copyWith(color: context.appSubText),
              ),
            ),
          ],
        ),
      );
    }

    if (state.productNames.isEmpty) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // SEARCH RESULT LIST
    // ==========================================================

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.only(top: 4),
      decoration: _searchDecoration(),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: state.productNames.length,
        separatorBuilder: (context, index) {
          return Divider(height: 1, color: context.appBorder);
        },
        itemBuilder: (context, index) {
          final ProductEntityy product = state.productNames[index];

          return InkWell(
            onTap: () {
              _openSearchProduct(product);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // ============================================
                  // PRODUCT ICON
                  // ============================================
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.appPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: context.appPrimary,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ============================================
                  // PRODUCT NAME
                  // ============================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: context.appOnCard,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          'View product details',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.appSubText,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: context.appSubText,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SEARCH DECORATION
  // ============================================================

  BoxDecoration _searchDecoration() {
    return BoxDecoration(
      color: context.appCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.appBorder),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withOpacity(0.07),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ============================================================
  // CATEGORY GRID
  // ============================================================

  Widget _buildCategoryGrid(List<FertilizerCategoryEntity> categories) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        return CategoryCard(
          category: category,
          index: index,
          onTap: () {
            openProducts(category);
          },
        );
      },
    );
  }
}
