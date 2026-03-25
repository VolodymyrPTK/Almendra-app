import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputCard extends StatelessWidget {
  const InputCard({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        autocorrect: autocorrect,
        enableSuggestions: autocorrect,
        onChanged: onChanged,
        style: TextStyle(
          color: titleCol,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: subCol,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: subCol, size: 20),
          suffixIcon: suffix,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          errorStyle: const TextStyle(
            color: Color(0xFFE5395E),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class SuggestionList extends StatelessWidget {
  const SuggestionList({
    super.key,
    required this.suggestions,
    required this.onSelect,
    required this.itemBuilder,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
  });
  final List<dynamic> suggestions;
  final Function(dynamic) onSelect;
  final Widget Function(dynamic) itemBuilder;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          itemBuilder: (context, index) {
            final item = suggestions[index];
            return InkWell(
              onTap: () => onSelect(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: itemBuilder(item),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MiniTab extends StatelessWidget {
  const MiniTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.cardBg,
    required this.borderCol,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardBg;
  final Color borderCol;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF8CAF7B);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? green.withValues(alpha: 0.1) : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? green : borderCol,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? green : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

class NovaFields extends StatelessWidget {
  const NovaFields({
    super.key,
    required this.cityCtrl,
    required this.warehouseCtrl,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
    required this.cityFocus,
    required this.warehouseFocus,
    required this.citySuggestions,
    required this.warehouseSuggestions,
    required this.loadingCities,
    required this.loadingWarehouses,
    required this.onCitySearch,
    required this.onCitySelect,
    required this.onWarehouseSearch,
    required this.onWarehouseSelect,
    required this.category,
    required this.onCategoryChange,
  });

  final TextEditingController cityCtrl;
  final TextEditingController warehouseCtrl;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;
  final FocusNode cityFocus;
  final FocusNode warehouseFocus;
  final List<dynamic> citySuggestions;
  final List<dynamic> warehouseSuggestions;
  final bool loadingCities;
  final bool loadingWarehouses;
  final Function(String) onCitySearch;
  final Function(dynamic) onCitySelect;
  final Function(String) onWarehouseSearch;
  final Function(dynamic) onWarehouseSelect;
  final String category;
  final Function(String) onCategoryChange;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF8CAF7B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputCard(
          controller: cityCtrl,
          focusNode: cityFocus,
          label: 'Населений пункт',
          icon: Icons.location_city_outlined,
          isDark: isDark,
          cardBg: cardBg,
          titleCol: titleCol,
          subCol: subCol,
          borderCol: borderCol,
          onChanged: onCitySearch,
          validator: (v) => v == null || v.trim().isEmpty ? 'Введіть місто' : null,
          suffix: loadingCities
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(green),
                  ),
                )
              : null,
        ),
        if (citySuggestions.isNotEmpty)
          SuggestionList(
            suggestions: citySuggestions,
            isDark: isDark,
            cardBg: cardBg,
            titleCol: titleCol,
            subCol: subCol,
            onSelect: onCitySelect,
            itemBuilder: (city) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city['Present'] ?? city['Description'] ?? '',
                  style: TextStyle(
                    color: titleCol,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (city['AreaDescription'] != null)
                  Text(
                    '${city['RegionsDescription'] ?? ''} ${city['AreaDescription']} обл.',
                    style: TextStyle(color: subCol, fontSize: 11),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            MiniTab(
              label: 'Відділення',
              selected: category == 'Warehouse',
              onTap: () => onCategoryChange('Warehouse'),
              isDark: isDark,
              cardBg: cardBg,
              borderCol: borderCol,
            ),
            const SizedBox(width: 8),
            MiniTab(
              label: 'Поштомат',
              selected: category == 'Postomat',
              onTap: () => onCategoryChange('Postomat'),
              isDark: isDark,
              cardBg: cardBg,
              borderCol: borderCol,
            ),
          ],
        ),
        const SizedBox(height: 12),
        InputCard(
          controller: warehouseCtrl,
          focusNode: warehouseFocus,
          label: category == 'Warehouse' ? 'Відділення' : 'Поштомат',
          icon: Icons.store_mall_directory_outlined,
          isDark: isDark,
          cardBg: cardBg,
          titleCol: titleCol,
          subCol: subCol,
          borderCol: borderCol,
          onChanged: onWarehouseSearch,
          validator: (v) => v == null || v.trim().isEmpty ? 'Виберіть місце доставки' : null,
          suffix: loadingWarehouses
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(green),
                  ),
                )
              : null,
        ),
        if (warehouseSuggestions.isNotEmpty)
          SuggestionList(
            suggestions: warehouseSuggestions,
            isDark: isDark,
            cardBg: cardBg,
            titleCol: titleCol,
            subCol: subCol,
            onSelect: onWarehouseSelect,
            itemBuilder: (w) => Text(
              w['Description'] ?? '',
              style: TextStyle(
                color: titleCol,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class UkrFields extends StatelessWidget {
  const UkrFields({
    super.key,
    required this.cityCtrl,
    required this.indexCtrl,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
  });

  final TextEditingController cityCtrl;
  final TextEditingController indexCtrl;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InputCard(
          controller: cityCtrl,
          label: 'Місто / Село',
          icon: Icons.location_on_outlined,
          isDark: isDark,
          cardBg: cardBg,
          titleCol: titleCol,
          subCol: subCol,
          borderCol: borderCol,
          validator: (v) => v == null || v.trim().isEmpty ? 'Введіть місто' : null,
        ),
        const SizedBox(height: 12),
        InputCard(
          controller: indexCtrl,
          label: 'Поштовий індекс',
          icon: Icons.local_post_office_outlined,
          isDark: isDark,
          cardBg: cardBg,
          titleCol: titleCol,
          subCol: subCol,
          borderCol: borderCol,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v == null || v.length < 5 ? 'Введіть коректний індекс (5 цифр)' : null,
        ),
      ],
    );
  }
}

class DeliveryChip extends StatelessWidget {
  const DeliveryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.borderCol,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color borderCol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF8CAF7B);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? green.withValues(alpha: 0.12) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? green : borderCol,
            width: selected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? green.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? green : titleCol.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? green : titleCol,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
