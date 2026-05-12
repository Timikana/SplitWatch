if GetLocale() ~= "frFR" then return end
local addonName, SplitW = ...
local L = SplitW.L

-- Pages / tabs
L["Setup"]    = "Réglages"
L["Players"]  = "Joueurs"
L["Preview"]  = "Aperçu"
L["About"]    = "À propos"
L["Enable test mode"]  = "Activer le mode test"
L["Disable test mode"] = "Désactiver le mode test"
L["not installed"] = "non installé"
L["Item Level (inspect)"] = "Niveau d'objet (inspect)"
L["Details!/Recount/Skada read live DPS+HPS from those addons when loaded. Item Level inspects each raid member (28y range). Manual uses the per-player sliders on the Weights tab."] =
    "Details!/Recount/Skada lisent DPS et HPS en direct depuis ces addons quand ils sont chargés. Niveau d'objet inspecte chaque membre du raid (portée 28y). Manuel utilise les sliders par joueur de l'onglet Joueurs."
L["Scan raid ilvl"] = "Scanner l'ilvl du raid"
L["Inspect every raid member to fetch their average item level. Each inspect is ~1.5s and limited to a 28-yard range. Active only when the Item Level source is selected."] =
    "Inspecte chaque membre du raid pour récupérer son niveau d'objet moyen. Chaque inspect prend ~1.5s et est limité à 28 yards de portée. Actif seulement quand la source Niveau d'objet est sélectionnée."

-- General
L["General"] = "Général"
L["Show minimap icon"] = "Afficher l'icône minimap"
L["Toggle the minimap launcher button"] = "Active/désactive le bouton lanceur sur la minimap"
L["Confirm before applying"] = "Confirmer avant d'appliquer"
L["Show a popup before mass-moving raid members"] = "Affiche une fenêtre de confirmation avant de déplacer tout le raid"
L["Print summary on apply"] = "Afficher le résumé après application"
L["Print a one-line summary to chat after a successful apply"] = "Affiche un résumé d'une ligne dans le chat après une application réussie"
L["Auto-refresh after combat"] = "Auto-refresh après combat"
L["Recompute weights from the DPS source every time combat ends"] = "Recalcule les poids depuis la source DPS à chaque fin de combat"

L["DPS source"] = "Source DPS"
L["Manual (per-player slider)"] = "Manuel (slider par joueur)"
L["Built-in (combat log)"] = "Intégré (combat log)"
L["Pick the data source for DPS / HPS"] = "Choisir la source des poids DPS / HPS"
L["Built-in parses the WoW combat log natively (no addon needed). Details!/Recount/Skada read from those addons when loaded. Manual uses the Weights tab sliders."] =
    "Intégré : parse le combat log WoW nativement (aucun addon requis). Details!/Recount/Skada : lit depuis ces addons quand ils sont chargés. Manuel : utilise les sliders de l'onglet Poids."
L["Active source"] = "Source active"

L["Permission status"] = "Statut des permissions"
L["You can apply splits (leader or assistant in a raid)."] = "Tu peux appliquer un split (chef ou assistant en raid)."
L["not in a raid"] = "Tu n'es pas en raid."
L["leader or assistant required"] = "Tu dois être chef de raid ou assistant pour appliquer un split."
L["test mode active — apply is disabled"] = "Mode test actif — l'application est désactivée."

-- Weights page
L["Manual weights"] = "Poids manuels"
L["Adjust each DPS player's relative weight (1-100). Higher = goes into the lower-scoring team first. Used only when source = Manual."] =
    "Règle le poids relatif de chaque joueur (1-100). Plus élevé = part dans l'équipe la moins chargée en priorité. Utilisé uniquement quand la source = Manuel."
L["Composition rules applied AFTER the score-based snake distribution. Each toggle swaps minimally-disruptive DPS pairs to satisfy the rule."] =
    "Règles de composition appliquées APRÈS la distribution snake basée sur le score. Chaque toggle swap les paires de DPS les plus proches en score pour satisfaire la règle."
L["Drag to resize the options window. Saved account-wide."] =
    "Glisse pour redimensionner la fenêtre. Sauvegardé pour tout le compte."
L["Reset all weights"] = "Réinitialiser tous les poids"
L["Reset every stored weight back to the default value."] = "Remet tous les poids enregistrés à la valeur par défaut."
L["Refresh roster"] = "Rafraîchir le roster"
L["Re-read the raid roster from Blizzard's API."] = "Relit le roster du raid depuis l'API Blizzard."
L["Toggle test mode"] = "Activer le mode test"
L["Use a simulated 20-man roster for UI testing."] = "Utilise un faux roster de 20 joueurs pour tester l'UI."
L["No raid members detected. Use /splitw test for a simulated 20-man roster."] =
    "Aucun membre de raid détecté. Tape /splitw test pour simuler un raid à 20."

-- Preview page
L["Preview the split"] = "Aperçu du split"
L["Compute split"] = "Calculer le split"
L["Read the current roster and run the snake-distribution algorithm."] =
    "Lit le roster actuel et applique l'algorithme de distribution en serpent."
L["Apply split"] = "Appliquer le split"
L["Move every player to their assigned subgroup. Requires leader or assistant."] =
    "Déplace chaque joueur dans son sous-groupe assigné. Nécessite chef ou assistant."
L["Before"] = "Avant"
L["After"]  = "Après"
L["Current raid distribution"] = "Distribution actuelle du raid"
L["Proposed split"] = "Split proposé"
L["Team A"] = "Équipe A"
L["Team B"] = "Équipe B"
L["No split computed yet — click 'Compute split'."] = "Aucun split calculé — clique sur 'Calculer le split'."
L["(empty)"] = "(vide)"
L["Looks good — no warnings."] = "Tout est bon — aucun avertissement."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tOnly one tank — both teams share the same tank? Check your roster."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tUn seul tank — les deux équipes partagent le même tank ? Vérifie ton roster."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo tank detected in the raid."] = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucun tank détecté dans le raid."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam A is too large for any reasonable raid size."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tÉquipe A trop grande pour une taille de raid raisonnable."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam B is too large for any reasonable raid size."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tÉquipe B trop grande pour une taille de raid raisonnable."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeams differ by more than 1 player — score is balanced by giving the weakest DPS to the larger team."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tLes équipes diffèrent de plus de 1 joueur — le score est équilibré en mettant le DPS le plus faible dans l'équipe la plus grande."
L["Apply the proposed split? This will move raid members."] =
    "Appliquer le split proposé ? Cela va déplacer les membres du raid."

-- Apply
L["nothing to do — split already matches"] = "Rien à faire — le raid est déjà arrangé."
L["combat detected — resuming after combat ends"] = "Combat détecté — reprise à la fin du combat."
L["combat ended — resuming apply"] = "Combat terminé — reprise de l'application."
L["lost lead/assist — apply aborted"] = "Tu as perdu le chef/assist — application annulée."
L["split applied"] = "Split appliqué."
L["applying split — %d moves queued"] = "Application du split — %d déplacements en file."

-- About / Changelog
L["About SplitWatch"] = "À propos de SplitWatch"
L["Auto-split a 10-40 man raid into 2 balanced teams (tanks, healers by HPS, DPS by damage) for split-mechanic encounters."] =
    "Sépare automatiquement un raid de 10 à 40 en 2 équipes équilibrées (tanks, heals selon HPS, DPS selon dégâts) pour les fights à mécaniques split."
L["Author"] = "Auteur"
L["Slash command"] = "Commande"
L["alias"] = "alias"
L["Sister addons"] = "Addons jumeaux"
L["Slash commands"] = "Commandes /slash"
L["Reset window position"] = "Réinitialiser la position de la fenêtre"
L["Reset the options window to its default center position."] = "Remet la fenêtre d'options au centre de l'écran."
L["Changelog"] = "Historique"
L["• 0 required addons — SplitWatch works standalone. Details!/Recount/Skada are optional for live DPS/HPS readings, otherwise Manual sliders are used."] =
    "• 0 addon requis — SplitWatch fonctionne tout seul. Details!/Recount/Skada sont optionnels pour lire DPS/HPS en live, sinon les sliders Manuels sont utilisés."
L["• Sister addon to BossWatch + TankWatch — shares the side-tab navigation, gold accent UI, and family colour palette."] =
    "• Addon jumeau de BossWatch + TankWatch — partage la navigation par side-tabs, l'UI à accent doré, et la palette de couleurs de la famille."
L["• Initial release: snake-distribution algorithm, preview pane with before/after stats, permission-gated Apply via SetRaidSubgroup."] =
    "• Version initiale : algorithme de distribution en serpent, aperçu avec stats avant/après, application protégée via SetRaidSubgroup."

-- v0.2.0 changelog entries
L["• 0 required addons — Details!/Recount/Skada remain optional integrations alongside the new Item Level (inspect) source and the per-player Manual sliders."] =
    "• 0 addon requis — Details!/Recount/Skada restent des intégrations optionnelles aux côtés de la nouvelle source Niveau d'objet (inspect) et des sliders Manuels."
L["• Sister addon to BossWatch + TankWatch — shares the side-tab navigation and the family UI."] =
    "• Addon jumeau de BossWatch + TankWatch — partage la navigation par side-tabs et l'UI de la famille."
L["• New section 'Constraints' on Setup — Raid Leader can toggle Battle Rez per team (ON by default), Bloodlust per team (ON by default), Balance melee vs ranged, Mass Dispel per team, Decurse per team."] =
    "• Nouvelle section 'Contraintes' sur Réglages — le RL peut activer Battle Rez par équipe (ON par défaut), Bloodlust par équipe (ON par défaut), équilibrer melee vs distance, Mass Dispel par équipe, Décurse par équipe."
L["• Constraint resolver runs AFTER the score-based snake so swaps stay minimal — picks the DPS pair closest in score, preserves role boundaries."] =
    "• Le résolveur de contraintes tourne APRÈS la distribution en serpent — il swap la paire de DPS la plus proche en score pour minimiser l'impact, en préservant les rôles."
L["• Team size rebalance: 2T / 1H / 17DPS no longer ends 11/9 — the weakest DPS migrates until |#A - #B| ≤ 1."] =
    "• Rebalance de taille d'équipe : 2T / 1H / 17DPS ne finit plus en 11/9 — le DPS le plus faible migre jusqu'à un écart ≤ 1."
L["• Source used for the split is now displayed on the Preview tab, no round-trip to Setup needed."] =
    "• La source utilisée pour le calcul est affichée sur l'onglet Aperçu — plus besoin de zapper sur Réglages."
L["• Each team-list line shows ilvl or DPS as a grey suffix next to the name."] =
    "• Chaque ligne d'équipe affiche l'ilvl ou le DPS en suffixe gris à côté du nom."
L["• Team titles include the player count: 'Équipe A (5)'."] =
    "• Les titres d'équipe incluent le compteur : 'Équipe A (5)'."
L["• Escape closes the panel (UISpecialFrames registration)."] =
    "• Échap ferme le panneau (intégration UISpecialFrames)."
L["• Damage meter sources: Details!, Recount, Skada, Manual — unavailable ones grey out in the dropdown."] =
    "• Sources de damage meter : Details!, Recount, Skada, Manuel — celles non installées sont grisées dans le dropdown."
L["• Healers balanced by HPS (live read from the active source), DPS by damage."] =
    "• Heals équilibrés selon le HPS (lecture live depuis la source active), DPS selon les dégâts."
L["• Supports raids from 10 to 40 members — subgroups assigned dynamically."] =
    "• Compatible raids de 10 à 40 — les sous-groupes sont assignés dynamiquement."
L["• Collapsible sections with per-section reset, persisted across reloads."] =
    "• Sections repliables avec reset par section, persisté entre les /reload."
L["• Initial release: manual weight mode, snake-distribution algorithm, preview pane with before/after stats, permission-gated Apply via SetRaidSubgroup."] =
    "• Version initiale : mode poids manuel, algorithme de distribution en serpent, aperçu avec stats avant/après, application protégée via SetRaidSubgroup."
L["• Supports retail 12.x and MoP Classic 5.5."] = "• Compatible retail 12.x et MoP Classic 5.5."
L["• Test mode (/splitw test) for UI preview without a raid."] =
    "• Mode test (/splitw test) pour prévisualiser l'UI sans raid."

-- Sister-addon side tabs
L["SplitWatch — Options"] = "SplitWatch — Options"
L["Open BossWatch options"] = "Ouvrir les options BossWatch"
L["Open TankWatch options"] = "Ouvrir les options TankWatch"

-- Blizzard settings page
L["Auto-split your 20-man raid — v%s\nClick the button below to open the SplitWatch options panel."] =
    "Sépare automatiquement ton raid 20 — v%s\nClique sur le bouton ci-dessous pour ouvrir le panneau SplitWatch."
L["Open SplitWatch options"] = "Ouvrir les options SplitWatch"
L["Open the floating SplitWatch options panel."] = "Ouvre le panneau d'options flottant de SplitWatch."
L["You can also use the slash command: /splitw"] = "Tu peux aussi utiliser la commande : /splitw"

-- Minimap
L["left-click: options"] = "clic gauche : options"
L["right-click: apply current split"] = "clic droit : appliquer le split actuel"

-- Slash help
L["commands:"] = "commandes :"
L["open options"] = "ouvrir les options"
L["compute and show split preview"] = "calculer et afficher l'aperçu du split"
L["apply the current split via SetRaidSubgroup"] = "appliquer le split actuel via SetRaidSubgroup"
L["toggle simulated 20-man roster"] = "activer/désactiver le faux roster 20"
L["reset all settings + reload"] = "tout réinitialiser + recharger l'UI"
L["test mode on (20 simulated members)"] = "mode test activé (20 membres simulés)"
L["test mode off"] = "mode test désactivé"

-- Misc
L["|cffffd100SplitWatch|r v%s loaded — type |cffffff00/splitw|r for options"] =
    "|cffffd100SplitWatch|r v%s chargé — tape |cffffff00/splitw|r pour les options"
L["WARN_CLASSIC"] = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tVersion Classic — UI pas encore testée à fond en raid, merci de signaler les bugs."
L["Panel"] = "Panneau"
L["Panel opacity"] = "Opacité du panneau"
L["Opacity of this options window. Saved account-wide."] = "Opacité de cette fenêtre. Sauvegardée pour tout le compte."
L["Test mode ON (20 simulated)"] = "Mode test ACTIF (20 simulés)"
L["No raid detected — enable test mode to preview"] = "Pas de raid détecté — active le mode test pour visualiser"
L["Live roster (%d members)"] = "Raid réel (%d membres)"
L["Source used for the split:"] = "Source utilisée pour le calcul :"

-- Constraints
L["Constraints"] = "Contraintes"
L["Battle Rez per team (Druid/DK/Warlock/Hunter/Paladin/DH)"] =
    "Battle Rez par équipe (Druide/DK/Démo/Hunter/Paladin/Démoniste Hunter)"
L["Enforce at least one battle-rez class per team."] = "Force au moins une classe avec Battle Rez par équipe."
L["Bloodlust per team (Shaman/Mage/Hunter/Evoker)"] =
    "Bloodlust par équipe (Chaman/Mage/Hunter/Evoker)"
L["Enforce at least one Bloodlust/Heroism/Time Warp/Primal Rage source per team."] =
    "Force au moins une source de Bloodlust / Héroïsme / Hâte temporelle / Rage primitive par équipe."
L["Balance melee vs ranged"] = "Équilibrer melee vs distance"
L["Equalise the melee/ranged DPS ratio between teams. Class-based heuristic (Druid/Shaman/Hunter default to ranged)."] =
    "Équilibre le ratio melee/distance entre les équipes. Heuristique par classe (Druide/Chaman/Hunter par défaut en distance)."
L["Mass Dispel per team (Priest)"] = "Mass Dispel par équipe (Prêtre)"
L["Enforce at least one Priest per team for Mass Dispel."] = "Force au moins un Prêtre par équipe pour Mass Dispel."
L["Decurse per team (Mage/Druid/Shaman/Monk)"] = "Décurse par équipe (Mage/Druide/Chaman/Moine)"
L["Enforce at least one decurse class per team."] = "Force au moins une classe pouvant décurse par équipe."

-- Constraint warnings
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo Battle Rez class in the raid — constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucune classe avec Battle Rez dans le raid — contrainte non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo Bloodlust giver in the raid — constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucun donneur de Bloodlust dans le raid — contrainte non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo Priest in the raid — Mass Dispel constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucun Prêtre dans le raid — contrainte Mass Dispel non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo decurse class in the raid — constraint cannot be satisfied."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucune classe décurse dans le raid — contrainte non satisfaite."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy Battle Rez (no compatible role pair)."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour satisfaire Battle Rez (pas de paire de rôle compatible)."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy Bloodlust (no compatible role pair)."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour satisfaire Bloodlust (pas de paire de rôle compatible)."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy Mass Dispel."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour satisfaire Mass Dispel."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't swap to satisfy Decurse."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tSwap impossible pour satisfaire Décurse."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tCouldn't fully balance melee/ranged ratio."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tImpossible d'équilibrer totalement le ratio melee/distance."
L["Source preview"] = "Aperçu de la source"
L["Live values read from the selected source for the current (or test) roster."] =
    "Valeurs lues en direct depuis la source sélectionnée, pour le roster actuel (ou test)."
L["No roster — enable test mode or join a raid."] = "Pas de roster — active le mode test ou rejoins un raid."
L["No data — join a raid, enable test mode, or fight something so the active source has actors to show."] =
    "Pas de données — rejoins un raid, active le mode test, ou tape sur quelque chose pour que la source active ait des acteurs à afficher."
L["Details!/Recount/Skada read live DPS+HPS from those addons when loaded. Manual uses the per-player sliders on the Weights tab."] =
    "Details!/Recount/Skada lisent DPS et HPS en direct depuis ces addons quand ils sont chargés. Manuel utilise les sliders par joueur de l'onglet Poids."
L["Click to collapse/expand this section."] = "Clic pour réduire/déplier cette section."
L["Reset this section to default values."] = "Réinitialise cette section aux valeurs par défaut."
