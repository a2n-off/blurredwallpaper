/*
    SPDX-FileCopyrightText: 2013 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2014 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick 2.5
import QtQuick.Window 2.2
// used to access the ImageBackend component, which handles the image loading and configuration
import org.kde.plasma.wallpapers.image 2.0 as Wallpaper
// for FastBlur
import QtGraphicalEffects 1.15

// root component displaying the image as the wallpaper
ImageStackView {
    id: root

    fillMode: wallpaper.configuration.FillMode
    configColor: wallpaper.configuration.Color
    blur: wallpaper.configuration.Blur
    // path of the chosen wallpaper
    source: {
        if (wallpaper.pluginName === "org.kde.slideshow") {
            return imageWallpaper.image;
        }
        if (wallpaper.configuration.PreviewImage !== "null") {
            return wallpaper.configuration.PreviewImage;
        }
        return wallpaper.configuration.Image;
    }
    sourceSize: Qt.size(root.width * Screen.devicePixelRatio, root.height * Screen.devicePixelRatio)
    wallpaperInterface: wallpaper

    // import the component
    WindowModel { id: windowModel }

    // Add a FastBlur effect to the wallpaper
    // the param is set via the `wallpaper.configuration` object
    layer.enabled: wallpaper.configuration.ActiveBlur
    layer.effect: FastBlur {
        anchors.fill: parent
        radius: windowModel.noWindowActive ? 0 : wallpaper.configuration.BlurRadius
        source: Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: root.source
        }
        // animate the blur apparition
        Behavior on radius {
            NumberAnimation {
                duration: wallpaper.configuration.AnimationDuration
            }
        }
    }

    // next 3 function : used by the WallpaperInterface to handle drag and drop, next slide, and open action
    // Public API functions accessible from C++:
    // e.g. used by WallpaperInterface for drag and drop
    function setUrl(url) {
        if (wallpaper.pluginName === "a2n.blur") {
            const result = imageWallpaper.addUsersWallpaper(url);

            if (result.length > 0) {
                // Can be a file or a folder (KPackage)
                wallpaper.configuration.Image = result;
            }
        } else {
            imageWallpaper.addSlidePath(url);
            // Save drag and drop result
            wallpaper.configuration.SlidePaths = imageWallpaper.slidePaths;
        }
    }

    // e.g. used by slideshow wallpaper plugin
    function action_next() {
        imageWallpaper.nextSlide();
    }

    // e.g. used by slideshow wallpaper plugin
    function action_open() {
        mediaProxy.openModelImage();
    }

    //private

    Component.onCompleted: {
        // In case plasmashell crashes when the config dialog is opened
        wallpaper.configuration.PreviewImage = "null";
        wallpaper.loading = true; // delays ksplash until the wallpaper has been loaded

        if (wallpaper.pluginName === "org.kde.slideshow") {
            wallpaper.setAction("open", i18nd("plasma_wallpaper_org.kde.image", "Open Wallpaper Image"), "document-open");
            wallpaper.setAction("next", i18nd("plasma_wallpaper_org.kde.image", "Next Wallpaper Image"), "user-desktop");
        }
    }

    // handles the configuration and loading of the wallpaper image
    Wallpaper.ImageBackend {
        id: imageWallpaper

        // Not using wallpaper.configuration.Image to avoid binding loop warnings
        configMap: wallpaper.configuration
        usedInConfig: false
        //the oneliner of difference between image and slideshow wallpapers
        renderingMode: (wallpaper.pluginName === "a2n.blur") ? Wallpaper.ImageBackend.SingleImage : Wallpaper.ImageBackend.SlideShow
        targetSize: root.sourceSize
        slidePaths: wallpaper.configuration.SlidePaths
        slideTimer: wallpaper.configuration.SlideInterval
        slideshowMode: wallpaper.configuration.SlideshowMode
        slideshowFoldersFirst: wallpaper.configuration.SlideshowFoldersFirst
        uncheckedSlides: wallpaper.configuration.UncheckedSlides

        // invoked from C++ to write the new image configuration
        function writeImageConfig(newImage: string) {
            configMap.Image = newImage;
        }
    }
}
