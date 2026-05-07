import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


// ─────────────────────────────────────────────────────────────────────────────
// NOTE: persistance locale via shared_preferences.
// Ajoutez dans pubspec.yaml :
//   dependencies:
//     shared_preferences: ^2.2.3
// ─────────────────────────────────────────────────────────────────────────────
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MiniFlowApp(prefs: prefs));
}

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum Priorite { basse, normale, elevee }

extension PrioriteExt on Priorite {
  String get label {
    switch (this) {
      case Priorite.basse:
        return 'Basse';
      case Priorite.normale:
        return 'Normale';
      case Priorite.elevee:
        return 'Élevée';
    }
  }

  Color get color {
    switch (this) {
      case Priorite.basse:
        return const Color(0xFF43D9AD);
      case Priorite.normale:
        return const Color(0xFF6C63FF);
      case Priorite.elevee:
        return const Color(0xFFFF6584);
    }
  }
}

class Tache {
  final String id;
  String titre;
  String? description;
  bool terminee;
  Priorite priorite;
  DateTime? dateEcheance;
  List<String> etiquettes;
  final DateTime creeeA;
  DateTime modifieeA;

  Tache({
    required this.id,
    required this.titre,
    this.description,
    this.terminee = false,
    this.priorite = Priorite.normale,
    this.dateEcheance,
    List<String>? etiquettes,
    required this.creeeA,
    required this.modifieeA,
  }) : etiquettes = etiquettes ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'description': description,
        'terminee': terminee,
        'priorite': priorite.index,
        'dateEcheance': dateEcheance?.toIso8601String(),
        'etiquettes': etiquettes,
        'creeeA': creeeA.toIso8601String(),
        'modifieeA': modifieeA.toIso8601String(),
      };

  factory Tache.fromJson(Map<String, dynamic> json) => Tache(
        id: json['id'] as String,
        titre: json['titre'] as String,
        description: json['description'] as String?,
        terminee: json['terminee'] as bool,
        priorite: Priorite.values[json['priorite'] as int],
        dateEcheance: json['dateEcheance'] != null
            ? DateTime.parse(json['dateEcheance'] as String)
            : null,
        etiquettes: List<String>.from(json['etiquettes'] as List),
        creeeA: DateTime.parse(json['creeeA'] as String),
        modifieeA: DateTime.parse(json['modifieeA'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// STORAGE (persistence layer)
// ─────────────────────────────────────────────────────────────────────────────

class StorageService {
  static const _cle = 'miniflow_taches';
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  List<Tache> charger() {
    final raw = _prefs.getString(_cle);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Tache.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> sauvegarder(List<Tache> taches) async {
    final json = jsonEncode(taches.map((t) => t.toJson()).toList());
    await _prefs.setString(_cle, json);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW-MODEL (business logic hook — ChangeNotifier)
// ─────────────────────────────────────────────────────────────────────────────

enum FiltreStatut { toutes, enCours, terminees }

enum TriPar { creeeA, priorite, dateEcheance, titre }

class GestionnaireTaches extends ChangeNotifier {
  final StorageService _storage;

  GestionnaireTaches(this._storage) {
    _taches = _storage.charger();
  }

  List<Tache> _taches = [];
  String _recherche = '';
  FiltreStatut _filtre = FiltreStatut.toutes;
  TriPar _tri = TriPar.creeeA;

  String get recherche => _recherche;
  FiltreStatut get filtre => _filtre;
  TriPar get tri => _tri;

  int get total => _taches.length;
  int get terminees => _taches.where((t) => t.terminee).length;
  double get progression => total == 0 ? 0 : terminees / total;

  List<Tache> get tachesFiltrees {
    var resultat = _taches.where((t) {
      // Filtre statut
      if (_filtre == FiltreStatut.enCours && t.terminee) return false;
      if (_filtre == FiltreStatut.terminees && !t.terminee) return false;
      // Recherche
      if (_recherche.isNotEmpty) {
        final q = _recherche.toLowerCase();
        final danstitre = t.titre.toLowerCase().contains(q);
        final dansDesc =
            t.description?.toLowerCase().contains(q) ?? false;
        final dansEtiq =
            t.etiquettes.any((e) => e.toLowerCase().contains(q));
        if (!danstitre && !dansDesc && !dansEtiq) return false;
      }
      return true;
    }).toList();

    // Tri
    resultat.sort((a, b) {
      switch (_tri) {
        case TriPar.priorite:
          return b.priorite.index.compareTo(a.priorite.index);
        case TriPar.dateEcheance:
          if (a.dateEcheance == null && b.dateEcheance == null) return 0;
          if (a.dateEcheance == null) return 1;
          if (b.dateEcheance == null) return -1;
          return a.dateEcheance!.compareTo(b.dateEcheance!);
        case TriPar.titre:
          return a.titre.compareTo(b.titre);
        case TriPar.creeeA:
          return b.creeeA.compareTo(a.creeeA);
      }
    });

    return resultat;
  }

  void setRecherche(String v) {
    _recherche = v;
    notifyListeners();
  }

  void setFiltre(FiltreStatut f) {
    _filtre = f;
    notifyListeners();
  }

  void setTri(TriPar t) {
    _tri = t;
    notifyListeners();
  }

  void ajouterTache({
    required String titre,
    String? description,
    Priorite priorite = Priorite.normale,
    DateTime? dateEcheance,
    List<String>? etiquettes,
  }) {
    final now = DateTime.now();
    _taches.insert(
      0,
      Tache(
        id: now.millisecondsSinceEpoch.toString(),
        titre: titre,
        description: description,
        priorite: priorite,
        dateEcheance: dateEcheance,
        etiquettes: etiquettes,
        creeeA: now,
        modifieeA: now,
      ),
    );
    _sauvegarder();
  }

  void toggleTerminee(String id) {
    final t = _taches.firstWhere((t) => t.id == id);
    t.terminee = !t.terminee;
    t.modifieeA = DateTime.now();
    _sauvegarder();
  }

  void supprimerTache(String id) {
    _taches.removeWhere((t) => t.id == id);
    _sauvegarder();
  }

  void modifierTache(Tache updated) {
    final i = _taches.indexWhere((t) => t.id == updated.id);
    if (i >= 0) {
      _taches[i] = updated;
      _sauvegarder();
    }
  }

  void _sauvegarder() {
    _storage.sauvegarder(_taches);
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────────────────────────────────────

class MiniFlowApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MiniFlowApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final vm = GestionnaireTaches(StorageService(prefs));
    return ListenableBuilder(
      listenable: vm,
      builder: (_, __) => MaterialApp(
        title: 'MiniFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
          ).copyWith(
            primary: const Color(0xFF6C63FF),
            secondary: const Color(0xFFFF6584),
            tertiary: const Color(0xFF43D9AD),
            surface: const Color(0xFFF7F7FB),
          ),
          scaffoldBackgroundColor: const Color(0xFFF7F7FB),
          fontFamily: 'Roboto',
        ),
        home: PageAccueil(vm: vm),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('fr', 'FR'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE ACCUEIL
// ─────────────────────────────────────────────────────────────────────────────

class PageAccueil extends StatelessWidget {
  final GestionnaireTaches vm;
  const PageAccueil({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final taches = vm.tachesFiltrees;
            final enCours = taches.where((t) => !t.terminee).toList();
            final faites = taches.where((t) => t.terminee).toList();

            return Column(
              children: [
                _EnteteApp(vm: vm),
                _ZoneRechercheFiltres(vm: vm),
                Expanded(
                  child: taches.isEmpty
                      ? _EtatVide(vm: vm)
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          children: [
                            if (enCours.isNotEmpty) ...[
                              _EnTeteSection(
                                  label: 'À FAIRE', count: enCours.length),
                              ...enCours.map((t) => _CarteTache(
                                    key: ValueKey(t.id),
                                    tache: t,
                                    vm: vm,
                                  )),
                            ],
                            if (faites.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _EnTeteSection(
                                  label: 'TERMINÉES', count: faites.length),
                              ...faites.map((t) => _CarteTache(
                                    key: ValueKey(t.id),
                                    tache: t,
                                    vm: vm,
                                  )),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrirFormulaire(context, vm),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle tâche'),
        elevation: 4,
      ),
    );
  }

  void _ouvrirFormulaire(BuildContext context, GestionnaireTaches vm,
      {Tache? tache}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FormulaireTache(vm: vm, tache: tache),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTÊTE APP
// ─────────────────────────────────────────────────────────────────────────────

class _EnteteApp extends StatelessWidget {
  final GestionnaireTaches vm;
  const _EnteteApp({required this.vm});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = (vm.progression * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'MiniFlow',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              if (vm.total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${vm.terminees} / ${vm.total}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (vm.total > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  vm.terminees == vm.total
                      ? '🎉 Tout est fait !'
                      : '${vm.total - vm.terminees} tâche${vm.total - vm.terminees > 1 ? 's' : ''} restante${vm.total - vm.terminees > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: vm.progression),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: cs.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARRE RECHERCHE + FILTRES
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneRechercheFiltres extends StatelessWidget {
  final GestionnaireTaches vm;
  const _ZoneRechercheFiltres({required this.vm});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: vm.setRecherche,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Rechercher une tâche…',
              hintStyle:
                  TextStyle(color: cs.onSurface.withOpacity(0.35), fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded,
                  color: cs.onSurface.withOpacity(0.4), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: vm.recherche.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => vm.setRecherche(''),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          // Filtres + Tri
          Row(
            children: [
              // Filtre statut
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: FiltreStatut.values.map((f) {
                      final labels = {
                        FiltreStatut.toutes: 'Toutes',
                        FiltreStatut.enCours: 'En cours',
                        FiltreStatut.terminees: 'Terminées',
                      };
                      final isActive = vm.filtre == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => vm.setFiltre(f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? cs.primary
                                  : cs.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              labels[f]!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? Colors.white
                                    : cs.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Tri
              PopupMenuButton<TriPar>(
                onSelected: vm.setTri,
                icon: Icon(Icons.sort_rounded,
                    color: cs.onSurface.withOpacity(0.5), size: 20),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: TriPar.creeeA,
                      child: Text('Créée le')),
                  const PopupMenuItem(
                      value: TriPar.priorite,
                      child: Text('Priorité')),
                  const PopupMenuItem(
                      value: TriPar.dateEcheance,
                      child: Text('Échéance')),
                  const PopupMenuItem(
                      value: TriPar.titre,
                      child: Text('Titre A–Z')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EN-TÊTE SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _EnTeteSection extends StatelessWidget {
  final String label;
  final int count;
  const _EnTeteSection({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE TÂCHE
// ─────────────────────────────────────────────────────────────────────────────

class _CarteTache extends StatelessWidget {
  final Tache tache;
  final GestionnaireTaches vm;
  const _CarteTache({super.key, required this.tache, required this.vm});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  bool get _enRetard =>
      tache.dateEcheance != null &&
      !tache.terminee &&
      tache.dateEcheance!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final couleurPrio = tache.priorite.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(tache.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: cs.secondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              Icon(Icons.delete_sweep_rounded, color: cs.secondary, size: 26),
        ),
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          vm.supprimerTache(tache.id);
        },
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            vm.toggleTerminee(tache.id);
          },
          onLongPress: () => _ouvrirEdition(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: tache.terminee ? Colors.white.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tache.terminee
                    ? Colors.transparent
                    : couleurPrio.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: tache.terminee
                  ? []
                  : [
                      BoxShadow(
                        color: couleurPrio.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barre priorité
                  Container(
                    width: 3,
                    height: 44,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color:
                          tache.terminee ? Colors.grey.shade200 : couleurPrio,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Checkbox
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      vm.toggleTerminee(tache.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tache.terminee ? couleurPrio : Colors.transparent,
                        border: Border.all(
                          color: tache.terminee
                              ? couleurPrio
                              : cs.onSurface.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: tache.terminee
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 13)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Contenu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tache.terminee
                                ? cs.onSurface.withOpacity(0.35)
                                : cs.onSurface,
                            decoration: tache.terminee
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: cs.onSurface.withOpacity(0.3),
                          ),
                          child: Text(tache.titre),
                        ),
                        if (tache.description != null &&
                            tache.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            tache.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.45),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Méta (date + étiquettes)
                        if (tache.dateEcheance != null ||
                            tache.etiquettes.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (tache.dateEcheance != null)
                                _PilluLE(
                                  label:
                                      _formatDate(tache.dateEcheance!),
                                  icon: Icons.calendar_today_rounded,
                                  color: _enRetard
                                      ? cs.secondary
                                      : cs.onSurface.withOpacity(0.4),
                                ),
                              ...tache.etiquettes.map(
                                (e) => _PilluLE(
                                  label: e,
                                  icon: Icons.label_outline_rounded,
                                  color: cs.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Bouton supprimer
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      vm.supprimerTache(tache.id);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: cs.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: cs.secondary.withOpacity(0.6), size: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _ouvrirEdition(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FormulaireTache(vm: vm, tache: tache),
    );
  }
}

class _PilluLE extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _PilluLE(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ÉTAT VIDE
// ─────────────────────────────────────────────────────────────────────────────

class _EtatVide extends StatelessWidget {
  final GestionnaireTaches vm;
  const _EtatVide({required this.vm});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avecFiltre = vm.recherche.isNotEmpty ||
        vm.filtre != FiltreStatut.toutes;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              avecFiltre
                  ? Icons.search_off_rounded
                  : Icons.check_circle_outline_rounded,
              size: 36,
              color: cs.primary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            avecFiltre ? 'Aucun résultat' : 'Tout est libre !',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withOpacity(0.55),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            avecFiltre
                ? 'Essayez un autre filtre ou terme de recherche.'
                : 'Ajoutez votre première tâche ci-dessous.',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withOpacity(0.35),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORMULAIRE AJOUT / ÉDITION
// ─────────────────────────────────────────────────────────────────────────────

class FormulaireTache extends StatefulWidget {
  final GestionnaireTaches vm;
  final Tache? tache;
  const FormulaireTache({super.key, required this.vm, this.tache});

  @override
  State<FormulaireTache> createState() => _FormulaireTacheState();
}

class _FormulaireTacheState extends State<FormulaireTache> {
  late TextEditingController _titreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _etiqCtrl;
  late Priorite _priorite;
  DateTime? _dateEcheance;
  late List<String> _etiquettes;

  @override
  void initState() {
    super.initState();
    final t = widget.tache;
    _titreCtrl = TextEditingController(text: t?.titre ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _etiqCtrl = TextEditingController();
    _priorite = t?.priorite ?? Priorite.normale;
    _dateEcheance = t?.dateEcheance;
    _etiquettes = List.from(t?.etiquettes ?? []);
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _etiqCtrl.dispose();
    super.dispose();
  }

  void _soumettre() {
    if (_titreCtrl.text.trim().isEmpty) return;
    if (widget.tache == null) {
      widget.vm.ajouterTache(
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        priorite: _priorite,
        dateEcheance: _dateEcheance,
        etiquettes: _etiquettes,
      );
    } else {
      final updated = widget.tache!
        ..titre = _titreCtrl.text.trim()
        ..description = _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim()
        ..priorite = _priorite
        ..dateEcheance = _dateEcheance
        ..etiquettes = _etiquettes
        ..modifieeA = DateTime.now();
      widget.vm.modifierTache(updated);
    }
    Navigator.pop(context);
  }

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateEcheance ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      locale: const Locale('fr'),
    );
    if (d != null) setState(() => _dateEcheance = d);
  }

  void _ajouterEtiquette() {
    final val = _etiqCtrl.text.trim();
    if (val.isEmpty || _etiquettes.contains(val)) return;
    setState(() {
      _etiquettes.add(val);
      _etiqCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estEdition = widget.tache != null;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                estEdition ? 'Modifier la tâche' : 'Nouvelle tâche',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // Titre
              TextField(
                controller: _titreCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Titre *',
                  hintText: 'Que faut-il faire ?',
                  filled: true,
                  fillColor: const Color(0xFFF7F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _soumettre(),
              ),
              const SizedBox(height: 10),

              // Description
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Description (optionnel)',
                  filled: true,
                  fillColor: const Color(0xFFF7F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Priorité
              Text('Priorité',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: Priorite.values.map((p) {
                  final isSelected = _priorite == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _priorite = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? p.color
                                : p.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            p.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : p.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Date d'échéance
              Text('Date d\'échéance',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _choisirDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16,
                          color: _dateEcheance != null
                              ? cs.primary
                              : cs.onSurface.withOpacity(0.3)),
                      const SizedBox(width: 10),
                      Text(
                        _dateEcheance != null
                            ? '${_dateEcheance!.day.toString().padLeft(2, '0')}/${_dateEcheance!.month.toString().padLeft(2, '0')}/${_dateEcheance!.year}'
                            : 'Choisir une date',
                        style: TextStyle(
                          fontSize: 14,
                          color: _dateEcheance != null
                              ? cs.onSurface
                              : cs.onSurface.withOpacity(0.35),
                        ),
                      ),
                      const Spacer(),
                      if (_dateEcheance != null)
                        GestureDetector(
                          onTap: () => setState(() => _dateEcheance = null),
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: cs.onSurface.withOpacity(0.4)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Étiquettes
              Text('Étiquettes',
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _etiqCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Ajouter une étiquette…',
                        filled: true,
                        fillColor: const Color(0xFFF7F7FB),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _ajouterEtiquette(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _ajouterEtiquette,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.tertiary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.add_rounded,
                          color: cs.tertiary, size: 20),
                    ),
                  ),
                ],
              ),
              if (_etiquettes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _etiquettes
                      .map(
                        (e) => GestureDetector(
                          onTap: () =>
                              setState(() => _etiquettes.remove(e)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cs.tertiary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: cs.tertiary,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                Icon(Icons.close_rounded,
                                    size: 12, color: cs.tertiary),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 20),

              // Bouton valider
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _soumettre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    estEdition ? 'Enregistrer' : 'Ajouter la tâche',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}