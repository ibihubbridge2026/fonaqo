import 'package:flutter/material.dart';

/// Étape 2 : détails selon type (catégories + procuration ou lieu administratif).
class CreateMissionStepDetails extends StatelessWidget {
  final String flowType;
  final List<Map<String, dynamic>> categories;
  final int? selectedCategoryId;
  final ValueChanged<int> onCategorySelected;
  final bool needsProcuration;
  final ValueChanged<bool> onProcurationChanged;
  final TextEditingController adminPlaceController;
  final VoidCallback onNext;

  const CreateMissionStepDetails({
    super.key,
    required this.flowType,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.needsProcuration,
    required this.onProcurationChanged,
    required this.adminPlaceController,
    required this.onNext,
  });

  bool get _canContinue {
    if (flowType == 'queue') {
      return adminPlaceController.text.trim().isNotEmpty;
    }
    return selectedCategoryId != null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            flowType == 'queue' ? 'Lieu administratif' : 'Service & options',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: flowType == 'queue' ? _queueBody() : _serviceBody(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _canContinue ? onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD400),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[300],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: adminPlaceController,
          decoration: InputDecoration(
            labelText: 'Lieu ou administration',
            hintText: 'Ex. Mairie de Cotonou — état civil',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _serviceBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Catégorie',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: categories.isEmpty
              ? Center(
                  child: Text(
                    'Aucune catégorie disponible. Vérifiez le serveur.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    final id = c['id'] is int
                        ? c['id'] as int
                        : int.tryParse('${c['id']}') ?? i;
                    final name = c['name']?.toString() ?? '—';
                    final sel = selectedCategoryId == id;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onCategorySelected(id),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFFFF9E6)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFFFFD400)
                                  : const Color(0xFFE5E5E5),
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Besoin d'une procuration ?",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Switch.adaptive(
                value: needsProcuration,
                onChanged: onProcurationChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
