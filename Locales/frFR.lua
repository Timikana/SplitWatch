if GetLocale() ~= "frFR" then return end
local addonName, SplitW = ...
local L = SplitW.L

-- Pages / tabs
L["Setup"]    = "Réglages"
L["Weights"]  = "Poids"
L["Preview"]  = "Aperçu"
L["About"]    = "À propos"

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
L["Pick the data source for DPS weights"] = "Choisir la source des poids DPS"
L["Manual = the weights you set on the Weights tab. Details! or Recount = read recent damage from those addons."] =
    "Manuel = les poids que tu règles dans l'onglet Poids. Details! ou Recount = lit les dégâts récents depuis ces addons."
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
L["Team A (groups 1-2)"] = "Équipe A (groupes 1-2)"
L["Team B (groups 3-4)"] = "Équipe B (groupes 3-4)"
L["No split computed yet — click 'Compute split'."] = "Aucun split calculé — clique sur 'Calculer le split'."
L["(empty)"] = "(vide)"
L["Looks good — no warnings."] = "Tout est bon — aucun avertissement."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tOnly one tank — both teams share the same tank? Check your roster."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tUn seul tank — les deux équipes partagent le même tank ? Vérifie ton roster."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tNo tank detected in the raid."] = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tAucun tank détecté dans le raid."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam A has more than 10 players — cannot fit in two subgroups."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tL'équipe A dépasse 10 joueurs — impossible de tenir dans deux sous-groupes."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tTeam B has more than 10 players — cannot fit in two subgroups."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tL'équipe B dépasse 10 joueurs — impossible de tenir dans deux sous-groupes."
L["|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tRaid > 20 members — split will be uneven (algorithm tuned for 20-man)."] =
    "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16:16:0:0|tRaid > 20 membres — le split sera déséquilibré (algorithme calibré pour 20)."
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
L["SplitWatch v%s — auto-split a 20-man raid into 2 balanced teams.\nAuthor: Timikana\nSlash command: |cffffff00/splitw|r\nSister addons: BossWatch + TankWatch.\n"] =
    "SplitWatch v%s — sépare automatiquement un raid 20 en 2 équipes équilibrées.\nAuteur : Timikana\nCommande : |cffffff00/splitw|r\nAddons jumeaux : BossWatch + TankWatch.\n"
L["Changelog"] = "Historique"
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
