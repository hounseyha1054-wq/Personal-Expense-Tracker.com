import 'package:get/get.dart';

import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

class CategoryController extends GetxController {
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    error.value = '';

    try {
      categories.assignAll(await _categoryRepository.getCategories());
    } catch (e) {
      error.value = 'Unable to load categories: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
