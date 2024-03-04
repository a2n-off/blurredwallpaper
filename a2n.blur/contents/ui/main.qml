/*
    SPDX-FileCopyrightText: 2013 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2014 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.wallpapers.image as Wallpaper
import org.kde.plasma.plasmoid

// for FastBlur
import Qt5Compat.GraphicalEffects

WallpaperItem {
    id: root

    // used by WallpaperInterface for drag and drop
    onOpenUrlRequested: (url) => {
        if (!root.configuration.IsSlideshow) {
            const result = imageWallpaper.addUsersWallpaper(url);
            if (result.length > 0) {
                // Can be a file or a folder (KPackage)
                root.configuration.Image = result;
            }
        } else {
            imageWallpaper.addSlidePath(url);
            // Save drag and drop result
            root.configuration.SlidePaths = imageWallpaper.slidePaths;
        }
    }

    contextualActions: [
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_org.kde.image", "Open Wallpaper Image")
            icon.name: "document-open"
            visible: root.configuration.IsSlideshow
            onTriggered: imageView.mediaProxy.openModelImage();
        },
        PlasmaCore.Action {
            text: i18nd("plasma_wallpaper_org.kde.image", "Next Wallpaper Image")
            icon.name: "user-desktop"
            visible: root.configuration.IsSlideshow
            onTriggered: imageWallpaper.nextSlide();
        }
    ]

    Component.onCompleted: {
        // In case plasmashell crashes when the config dialog is opened
        root.configuration.PreviewImage = "null";
        root.loading = true; // delays ksplash until the wallpaper has been loaded
    }

    ImageStackView {
        id: imageView
        anchors.fill: parent

        fillMode: root.configuration.FillMode
        configColor: root.configuration.Color
        blur: root.configuration.Blur
        source: {
            if (root.configuration.IsSlideshow) {
                return imageWallpaper.image;
            }
            if (root.configuration.PreviewImage !== "null") {
                return root.configuration.PreviewImage;
            }
            return root.configuration.Image;
        }
        sourceSize: Qt.size(root.width * Screen.devicePixelRatio, root.height * Screen.devicePixelRatio)
        wallpaperInterface: root

        // Add a FastBlur effect to the wallpaper
        layer.enabled: root.configuration.ActiveBlur
        layer.effect: FastBlur {
            anchors.fill: parent
            radius: windowModel.noWindowActive ? 0 : root.configuration.BlurRadius
            source: Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: root.source
            }
            // animate the blur apparition
            Behavior on radius {
                NumberAnimation {
                    duration: root.configuration.AnimationDuration
                }
            }
        }

        Wallpaper.ImageBackend {
            id: imageWallpaper

            // Not using root.configuration.Image to avoid binding loop warnings
            configMap: root.configuration
            usedInConfig: false
            //the oneliner of difference between image and slideshow wallpapers
            renderingMode: root.configuration.IsSlideshow ? Wallpaper.ImageBackend.SlideShow : Wallpaper.ImageBackend.SingleImage
            targetSize: imageView.sourceSize
            slidePaths: root.configuration.SlidePaths
            slideTimer: root.configuration.SlideInterval
            slideshowMode: root.configuration.SlideshowMode
            slideshowFoldersFirst: root.configuration.SlideshowFoldersFirst
            uncheckedSlides: root.configuration.UncheckedSlides

            // Invoked from C++
            function writeImageConfig(newImage: string) {
                configMap.Image = newImage;
            }
        }
    }
}
