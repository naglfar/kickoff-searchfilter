/*
    SPDX-FileCopyrightText: 2013 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

import org.kde.plasma.configuration as PlasmaConfig

PlasmaConfig.ConfigModel {
    PlasmaConfig.ConfigCategory {
        name: i18ndc("plasma_applet_org.kde.plasma.kickoff", "@title:group for configuration dialog page", "General")
        icon: "preferences-desktop-plasma"
        source: "ConfigGeneral.qml"
    }
    PlasmaConfig.ConfigCategory {
        // From libplasma's catalog, so it's translated where Plasma is
        name: i18nd("libplasma6", "Search")
        icon: "search"
        source: "ConfigSearch.qml"
    }
}
