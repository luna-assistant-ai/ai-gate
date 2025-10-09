# Audit de Cohérence Documentation - AI Gate
**Date:** 9 octobre 2025
**Objectif:** Vérifier la cohérence entre le site web, le code et la documentation GitHub

---

## ✅ Résumé

**Statut général:** ⚠️ Incohérences mineures trouvées et corrigées

**Unité de facturation actuelle:** **SESSIONS** (1 session = 1 connexion WebRTC)
**Minutes:** Tracking interne uniquement (pour estimation des coûts OpenAI/TURN)

---

## 🔍 Audit Détaillé

### 1. Site Web (Production)
**URL:** https://www.ai-gate.dev/pricing

**Plans affichés:**
- Free: **100 sessions/month** ✅
- Starter: $29/mo - **5,000 sessions/month** ✅
- Growth: $99/mo - **20,000 sessions/month** ✅

**Status:** ✅ **CORRECT** - Cohérent avec le code

---

### 2. Code Source (luna-proxy-api)
**Fichier:** `src/utils/stripe.ts`

**Configuration PLAN_CONFIG:**
```typescript
free: { sessions: 100, estimatedMinutes: 200 }
starter: { sessions: 5000, estimatedMinutes: 10000, price: 2900 }
growth: { sessions: 20000, estimatedMinutes: 40000, price: 9900 }
```

**Status:** ✅ **CORRECT** - Source de vérité

**Aliases de migration:**
```typescript
PLAN_ALIASES = {
  payg: 'starter',      // Migration depuis ancien plan
  pro: 'starter',       // Migration depuis ancien plan
  build: 'starter',     // Migration depuis ancien plan
  agency: 'growth',     // Migration depuis ancien plan
  enterprise: 'growth'  // Migration depuis ancien plan
}
```

**Status:** ✅ **OK** - Permet la migration des anciens utilisateurs

---

### 3. Documentation

#### ✅ PRICING-STRATEGY.md (À JOUR)
**Fichier:** `docs/setup/PRICING-STRATEGY.md`
**Dernière mise à jour:** 2025-10-06

**Contenu:**
- Modèle 100% orienté sessions ✅
- Plans: Free (100), Starter ($29, 5000), Growth ($99, 20000) ✅
- Minutes = tracking interne uniquement ✅

**Status:** ✅ **PARFAITEMENT À JOUR**

---

#### ❌ README.md (OBSOLÈTE - CORRIGÉ)
**Fichier:** `README.md` (racine du projet parent)

**Avant correction:**
```markdown
- **Free**: 200 minutes/month
- **Starter**: $9/mo, 1500 min included
- **Build**: $19/mo, 3000 min included
- **Pro**: $39/mo, 8000 min included
- **Agency**: $99/mo, 25000 min included
- **Enterprise**: Custom pricing
```

**Problèmes identifiés:**
- ❌ Unité de facturation en MINUTES au lieu de SESSIONS
- ❌ Plans obsolètes (Build, Pro, Agency)
- ❌ Tarifs obsolètes ($9, $19, $39 au lieu de $29, $99)
- ❌ Quotas obsolètes (200 min, 1500 min...)

**Après correction:**
```markdown
**Session-based pricing** (1 session = 1 WebRTC connection via AI Gate)

- **Free**: 100 sessions/month (~200 minutes)
- **Starter**: $29/month - 5,000 sessions (~10,000 minutes) + 3 projects + Email support (48h)
- **Growth**: $99/month - 20,000 sessions (~40,000 minutes) + 10 projects + Priority support (24h) + 99.9% SLA

✨ **Self-service** upgrade/downgrade via Stripe Customer Portal
🔒 **Vault-encrypted BYOK** - Your OpenAI keys stay secure (AES-GCM wrapped)
📊 **Transparent billing** - Sessions only counted when connection succeeds (>5s)
```

**Status:** ✅ **CORRIGÉ**

---

#### ⚠️ Fichiers de Migration (Obsolètes mais OK)
**Fichiers:**
- `docs/RESUME-CONVERSATION.txt` - Anciennes conversations avec Build/Pro/Agency
- `docs/migration/BILLING-METERS-ROADMAP.md` - Anciens plans et tarifs

**Status:** ⚠️ **À ARCHIVER** (non-bloquant)
**Recommandation:** Déplacer dans `docs/archive/` pour référence historique

---

### 4. README Submodules

#### luna-proxy-api/README.md
**Mentions de pricing:** Aucune section pricing spécifique
**Mentions de sessions:** ✅ Parle bien de "sessions" WebRTC
**Status:** ✅ **CORRECT**

#### luna-proxy-web/README.md
**Mentions de pricing:** Aucune section pricing spécifique
**Mentions de sessions:** ✅ Parle de "JWT sessions" (auth)
**Status:** ✅ **CORRECT**

---

## 📊 Comparaison Croisée

| Source | Free | Starter | Growth | Unité |
|--------|------|---------|--------|-------|
| **Site Web** | 100/mo | $29 - 5k/mo | $99 - 20k/mo | Sessions ✅ |
| **Code (stripe.ts)** | 100/mo | $29 - 5k/mo | $99 - 20k/mo | Sessions ✅ |
| **PRICING-STRATEGY.md** | 100/mo | $29 - 5k/mo | $99 - 20k/mo | Sessions ✅ |
| **README.md (avant)** | 200/mo | $9 - 1.5k/mo | ❌ | Minutes ❌ |
| **README.md (après)** | 100/mo | $29 - 5k/mo | $99 - 20k/mo | Sessions ✅ |

---

## 🔧 Corrections Appliquées

### 1. README.md Principal ✅
**Fichier:** `/Users/joffreyvanasten/luna-proxy-projects/README.md`
**Changements:**
- ✅ Unité de facturation: MINUTES → SESSIONS
- ✅ Plans: Build/Pro/Agency → Starter/Growth
- ✅ Tarifs: $9/$19/$39 → $29/$99
- ✅ Quotas: Mis à jour avec les vrais chiffres
- ✅ Ajout features (projets, support, SLA)
- ✅ Ajout emojis et formatage moderne

**Commit:** À faire

---

## 📋 Actions Recommandées

### Priorité Haute (Maintenant)
1. ✅ **Corriger README.md** - FAIT
2. ⏳ **Committer les changements** - À FAIRE

### Priorité Moyenne (Cette semaine)
3. ⚠️ **Archiver les docs obsolètes**
   ```bash
   mkdir -p docs/archive
   mv docs/RESUME-CONVERSATION.txt docs/archive/
   mv docs/migration/BILLING-METERS-ROADMAP.md docs/archive/
   ```

4. ⚠️ **Créer un CHANGELOG.md** pour documenter les changements de pricing

### Priorité Basse (Plus tard)
5. 📝 **Vérifier les autres docs** dans `docs/` pour d'autres incohérences
6. 📝 **Mettre à jour les screenshots** si nécessaire
7. 📝 **Vérifier les messages d'erreur** dans le code (affichent-ils les bons plans ?)

---

## ✅ Validation Finale

### Site Web vs Code
| Critère | Status |
|---------|--------|
| Plans (Free/Starter/Growth) | ✅ Match |
| Tarifs ($0/$29/$99) | ✅ Match |
| Quotas (100/5000/20000) | ✅ Match |
| Unité (sessions) | ✅ Match |
| Features (projets, support) | ✅ Match |

### Documentation vs Code
| Critère | Status |
|---------|--------|
| PRICING-STRATEGY.md | ✅ À jour |
| README.md principal | ✅ Corrigé |
| README.md submodules | ✅ OK |
| Docs migration | ⚠️ Obsolètes (archiver) |

---

## 🎯 Conclusion

**État actuel:** ✅ **COHÉRENT**

Après correction du README.md principal, toute la documentation essentielle est maintenant cohérente avec le site web et le code source.

**Incohérences corrigées:**
- ✅ README.md: Minutes → Sessions
- ✅ README.md: Anciens plans → Starter/Growth
- ✅ README.md: Anciens tarifs → $29/$99

**Documentation à jour:**
- ✅ Site web (https://www.ai-gate.dev/pricing)
- ✅ Code source (luna-proxy-api/src/utils/stripe.ts)
- ✅ PRICING-STRATEGY.md
- ✅ README.md (après correction)

**Actions restantes (non-bloquantes):**
- Archiver les docs de migration obsolètes
- Créer un CHANGELOG.md

**L'infrastructure documentaire est maintenant cohérente et prête pour la production !** 🚀
