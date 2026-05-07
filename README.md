# MiniFlow

Gestionnaire de tâches minimaliste, hors ligne et conçu pour la simplicité structurelle. Un démonstration pragmatique de bonnes pratiques architecturales sans surcharge.

## Philosophie

MiniFlow repose sur trois principes :

- **Minimaliste** : Aucune dépendance externe inutile. Seulement ce qui est nécessaire.
- **Hors ligne** : Fonctionnement complet sans connexion réseau. Synchronisation locale via LocalStorage.
- **Structuré** : Architecture MVVM claire séparant présentation, logique métier et persistance.

Pas de frameworks lourds. Pas de complexité cachée. Juste une architecture solide, lisible et maintenable.

---

## Caractéristiques

- ✅ **Gestion rapide de tâches** - Ajout, édition, suppression en millisecondes
- ✅ **État persistant** - Sauvegarde automatique via LocalStorage
- ✅ **Interfaces minimalistes** - UI dépouillée, zéro distraction
- ✅ **Architecture MVVM** - Séparation claire des responsabilités
- ✅ **TypeScript** - Sécurité des types dès le départ
- ✅ **Responsive** - Fonctionne sur desktop, tablette, mobile
- ✅ **Performance** - Bundle size minimal, rendu optimisé

---

## Démarrage rapide

### Prérequis

- Node.js 18+
- pnpm (ou npm/yarn)

### Installation

```bash
# Cloner le repository
git clone <repository-url>
cd miniflow

# Installer les dépendances
pnpm install

# Lancer le serveur de développement
pnpm dev
```

L'application est accessible à `http://localhost:3000`.

### Build production

```bash
pnpm build
pnpm start
```

---

## Architecture

### Structure MVVM

MiniFlow utilise le pattern **Model-View-ViewModel** pour une séparation claire :

```
┌─────────────────────────────────────┐
│          Vue (UI Components)        │
│         (React/TypeScript)          │
└─────────────────┬───────────────────┘
                  │
                  ↓
┌─────────────────────────────────────┐
│    ViewModel (State Management)     │
│      (Hooks, Business Logic)        │
└─────────────────┬───────────────────┘
                  │
                  ↓
┌─────────────────────────────────────┐
│  Model (Data & Persistence Layer)   │
│    (LocalStorage, Type Safety)      │
└─────────────────────────────────────┘
```

### Couches

#### 1. **Model** (`lib/storage.ts`, `types/`)
- Définition des entités (Task, Project, etc.)
- Logique de persistance (LocalStorage)
- Validation des données
- Pas de dépendances React

#### 2. **ViewModel** (`hooks/`)
- Gestion d'état (useState, useReducer)
- Logique métier (tri, filtrage, calculs)
- Communication Model ↔ Vue
- Hooks réutilisables

#### 3. **Vue** (`components/`)
- Composants React purs
- Zéro logique métier
- Props bien typées
- Émettre des événements vers ViewModel

### Flux de données

```
Utilisateur interagit → Composant → ViewModel → Model → LocalStorage
                         ↑                              ↓
                         ←─────────────────────────────
```

---

## Structure du projet

```
miniflow/
├── app/
│   ├── layout.tsx          # Root layout
│   ├── page.tsx            # Page d'accueil
│   └── globals.css         # Styles globaux
│
├── components/
│   ├── TaskList.tsx        # Affichage des tâches
│   ├── TaskForm.tsx        # Formulaire ajout/édition
│   ├── TaskItem.tsx        # Élément individual
│   └── ui/                 # Composants génériques
│
├── hooks/
│   ├── useTaskManager.ts   # ViewModel principal
│   └── useLocalStorage.ts  # Abstraction persistence
│
├── lib/
│   ├── storage.ts          # Logique LocalStorage
│   ├── utils.ts            # Utilitaires
│   └── constants.ts        # Constantes métier
│
├── types/
│   └── index.ts            # Définitions TypeScript
│
├── public/                 # Assets statiques
└── README.md               # Ce fichier
```

---

## Modèle de données

### Task

```typescript
interface Task {
  id: string;                    // UUID unique
  title: string;                 // Titre (1-255 chars)
  description?: string;          // Description optionnelle
  completed: boolean;            // État d'accomplissement
  priority: 'low' | 'medium' | 'high';  // Priorité
  dueDate?: Date;               // Date limite optionnelle
  createdAt: Date;              // Timestamp création
  updatedAt: Date;              // Timestamp modification
  tags?: string[];              // Étiquettes optionnelles
}
```

### Persistance

Les tâches sont sérialisées en JSON et stockées sous la clé `miniflow_tasks` dans LocalStorage :

```typescript
// Écriture
localStorage.setItem('miniflow_tasks', JSON.stringify(tasks));

// Lecture
const tasks = JSON.parse(localStorage.getItem('miniflow_tasks') || '[]');
```

---

## Développement

### Stack technique

- **Framework** : Next.js 16 (App Router)
- **Langage** : TypeScript 5
- **Styling** : Tailwind CSS
- **State** : React Hooks (useState, useReducer, useContext)
- **Storage** : LocalStorage (navigateur)
- **UI Components** : shadcn/ui (optionnel)

### Conventions de code

#### Nommage
- Composants React : `PascalCase` (TaskList.tsx)
- Hooks : `camelCase` avec préfixe `use` (useTaskManager)
- Fichiers utilitaires : `camelCase` (storage.ts)
- Types/Interfaces : `PascalCase` (Task, TaskState)

#### Structure de fichier
```typescript
// Imports React
import React, { useState } from 'react';

// Imports locaux
import { Task } from '@/types';
import { cn } from '@/lib/utils';

// Composant
export interface Props { /* ... */ }

export const MyComponent: React.FC<Props> = ({ /* ... */ }) => {
  // Logique
  return (
    // JSX
  );
};
```

#### Gestion d'état
Privilégier les hooks simples pour cette taille de projet. Si complexité : `useReducer`.

```typescript
const [tasks, setTasks] = useState<Task[]>([]);
const [filter, setFilter] = useState<'all' | 'completed' | 'pending'>('all');
```

---

## Bonnes pratiques

### ✅ À faire

- ✔ Garder les composants petits et focalisés (< 150 lignes)
- ✔ Valider les entrées utilisateur côté client ET serveur
- ✔ Typer tout avec TypeScript
- ✔ Documenter les logiques métier complexes
- ✔ Utiliser des clés stables pour les listes React
- ✔ Tester les hooks métier
- ✔ Débouncer les appels storage fréquents

### ❌ À éviter

- ❌ Logique métier dans les composants
- ❌ Props drilling profond (> 3 niveaux)
- ❌ Rendre des objets inline comme props
- ❌ Dépendances externes non justifiées
- ❌ États implicites ou dupliqués
- ❌ Mutations directes de l'état React

---

## Patterns courants

### Initialiser l'état depuis LocalStorage

```typescript
const useLocalStorageState = <T,>(key: string, initialValue: T) => {
  const [state, setState] = useState<T>(() => {
    try {
      const stored = localStorage.getItem(key);
      return stored ? JSON.parse(stored) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setState_ = (value: T | ((prev: T) => T)) => {
    setState((prev) => {
      const next = typeof value === 'function' ? (value as Function)(prev) : value;
      localStorage.setItem(key, JSON.stringify(next));
      return next;
    });
  };

  return [state, setState_] as const;
};
```

### Filtrer et trier les tâches

```typescript
const getFilteredTasks = (tasks: Task[], filter: Filter): Task[] => {
  return tasks
    .filter(task => {
      if (filter.status === 'completed') return task.completed;
      if (filter.status === 'pending') return !task.completed;
      return true;
    })
    .filter(task => {
      if (!filter.search) return true;
      return task.title.toLowerCase().includes(filter.search.toLowerCase());
    })
    .sort((a, b) => {
      const priorityOrder = { high: 0, medium: 1, low: 2 };
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    });
};
```

### Debouncing des appels fréquents

```typescript
const useDebouncedEffect = (effect: () => void, deps: any[], delay = 500) => {
  useEffect(() => {
    const timer = setTimeout(effect, delay);
    return () => clearTimeout(timer);
  }, deps);
};
```

---

## Performance

### Optimisations apportées

- **Code splitting** : Composants lazy loaded si nécessaire
- **Memoization** : `useMemo` pour calculs complexes, `useCallback` pour callbacks
- **Virtualisation** : Pour listes > 100 éléments
- **Debouncing** : Sur les modifications fréquentes (recherche, input)
- **CSS optimisé** : Tailwind purgé en production

### Métriques cibles

| Métrique | Cible |
|----------|-------|
| Bundle size | < 100 KB (gzipped) |
| Time to Interactive | < 1s (4G) |
| First Paint | < 500ms |
| FCP (First Contentful Paint) | < 1s |

---

## Tester l'application

### Tests unitaires (hooks)

```bash
pnpm test
```

Structure recommandée :

```
__tests__/
├── hooks/
│   └── useTaskManager.test.ts
├── lib/
│   └── storage.test.ts
└── utils/
    └── utils.test.ts
```

### Tests manuels

1. Ajouter une tâche → Rafraîchir la page → Vérifie persistance
2. Marquer complétée → Filtrer → Vérifier l'état
3. DevTools → Application → LocalStorage → Inspecter `miniflow_tasks`

---

## Déploiement

### Vercel (recommandé)

```bash
# Connecter le repository
vercel login

# Déployer
vercel deploy
```

### Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .
RUN pnpm install
RUN pnpm build
EXPOSE 3000
CMD ["pnpm", "start"]
```

```bash
docker build -t miniflow .
docker run -p 3000:3000 miniflow
```

---

## Troubleshooting

### LocalStorage plein

```typescript
// Nettoyer les anciennes clés
localStorage.removeItem('miniflow_tasks_backup');
```

### État désynchronisé après rechargement

Vérifier que la sérialisation JSON ne perd pas de données (Dates, fonctions).

### Performance dégradée avec 1000+ tâches

- Implémenter la virtualisation (react-window)
- Pagination
- Web Workers pour le filtrage intensif

---

## Contribution

Les contributions sont bienvenues. Pour modifier MiniFlow :

1. Fork le repository
2. Créer une branche (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

**Standards** :
- Respecter les conventions de code
- Ajouter des tests pour nouvelle logique
- Documenter les changements architecturaux
- Maintenir le bundle size petit

---

## Roadmap

- [ ] Drag & drop pour réordonner
- [ ] Catégories/Projets
- [ ] Récurrence des tâches
- [ ] Synchronisation cloud (optionnelle)
- [ ] Raccourcis clavier
- [ ] Dark mode
- [ ] Export/Import (JSON, CSV)
- [ ] Notifications (date limite approchante)

---

## FAQ

**Q : Pourquoi LocalStorage et pas IndexedDB ?**  
A : Pour cette taille de données (< 10K tâches), LocalStorage suffit. IndexedDB ajouterait de la complexité. À revisiter si > 100K items.

**Q : Comment gérer les conflits en offline ?**  
A : MiniFlow est single-user par défaut. Pour multi-user, implémenter un système de versioning (CRDTs ou Event sourcing).

**Q : Peut-on ajouter une synchronisation cloud ?**  
A : Oui, facilement. Ajouter un hook `useSyncToCloud` qui envoie les changes au serveur de temps en temps.

**Q : Quelle taille peut atteindre le projet ?**  
A : L'architecture MVVM scale bien jusqu'à ~50K lignes de code. Au-delà, envisager une séparation front/back ou une architecture modulaire.

---

## Licence

MIT – Libre d'utilisation commerciale et personnelle.

---

## Auteur & Crédits

Construit comme démonstration de bonnes pratiques architecturales en développement frontend.

Inspiré par :
- MVVM patterns
- Domain-Driven Design
- The Pragmatic Programmer

---

## Ressources

- [Next.js Documentation](https://nextjs.org/docs)
- [React Hooks API](https://react.dev/reference/react/hooks)
- [TypeScript Best Practices](https://www.typescriptlang.org/docs/handbook/)
- [Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)

---

**Dernière mise à jour** : mai 2026  
**Version** : 1.0.0
