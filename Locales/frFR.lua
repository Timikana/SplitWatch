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
L["Adjust each DPS player's relative weight (1-100). Higher = goes into the lower-scoring team first."] =
    "Règle le poids relatif de chaque joueur (1-100). Plus élevé = part dans l'équipe la moins chargée en priorité."
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
