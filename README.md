# bamboo

I started with this project a few months ago, with the intent to create an app that can quickly perform tasks I occasionally perform on my app. Something I wanted to see whether I could do, was to create a "translucent" app of sorts, which I succeeded at. Basically, the app overlays over your home screen, making it seem as though it's a pop-up rather than a separate app. Due to Android's behavior, it unfortunately cannot overlay on other apps, but that's okay since I'm mostly launching it from the home screen app anyway.

With this app, I also wanted to use Flutter rather than the native (+ kotlin) Android framework, because I wanted to learn Flutter which I had hardly worked with before. Combining this with a transparent app introduced some complications, but it all turned out well.

It does have some bugs in a few places, but since this is a hobby project, I'll get around to fixing them when I feel like it. I usually have other things I'd rather spend my time on.



## Features

The app currently consists of two "apps". I didn't feel like creating separate apps for this, so the Android manifest contains two launcher activities. If I ever find a reason to split them into separate apps I might, but for now this is fine. Plus, I can share code between the apps this way without overhead, which is a big bonus.

I made sure to stick with a consistent theme throughout the app, and included animations as much as possible (props Flutter for making it so easy) so create a smooth and comfortable user experience.



### Bamboo

This is a clock app (which was the first thing I made and goes by the same name as the project). It can:

- Set a timer, which sends the signal to the native timer, which makes my life a lot easier and gives the user the most flexibility after a timer has started. I would like to add the option to add preset times since I occasionally set the same timer, but that's for later.
- Start a stopwatch. Currently there's two things that need fixing:
  - The native font has variable text widths and there's no simple way to make all numbers take up the same amount of space, so as the stopwatch updates, the widget's width shrinks and expands which is rather ugly. At least it's all centered so the buttons don't move around.
  - The screen turns still automatically turns off after a while (as per the device's behaviour), I want to turn this off since I use this stopwatch while planking and I don't want to have to touch my phone while doing that.



### Firefly

This app relates to lights, and currently has two features:

- A "night light", which is inspired by an app that does exactly the same that I used to use before I made this. Basically, it overlays a translucent black color over the entire screen in all apps, which allows the screen to become darker than what it would be with the lowest brightness, which is very pleasant later at night.
- An led controller for my [esp-leds](https://github.com/megamichiel/esp-leds) project. You can add locations (name/ip pairs), and for an led you can control the brightness and color, as well as add presets for special things such as a rainbow. To keep the app simple and clean, some of those actions are hidden behind pressing on things that don't seem like buttons or long pressing buttons.



## Structure

To achieve the transparent app and multiple app features, I had to write some custom stuff on the Android/kotlin side of things. You can find that under android/app/src/main/java/kotlin/.../bamboo/

The rest of the code can be found in the lib folder, with main.dart as entrypoint, and app-specific code in the bamboo and firefly folders.

Back button functionality works a bit weirdly in Flutter due to Dart's nature, so for the navigation I used in my app (consisting of just animations rather than separate views/activities entirely), I had to implement my own system for back button handling in nested views. The code for it can be found in the widget.dart file, and references to it can be found throughout the rest of the code if you're curious. Basically:

- There's a WillPopScope at the earliest in the tree where the action needs to be handled, or two sub-widgets exist which both need to handle the back button, provided with the BackButtonProvider class, which is a widget that should be included in the tree.
  - This provider is given a function to determine the current state, which should be a set of a few options, as well as a "BackContext", which is a context used to track who's in charge of a specific state. It also can be passed a default action to perform if there is no current state, or the current state does not have a back function stored in the context (see below).
  - Sub-widgets are passed this context, as well as which state they correspond with. A constructor with corresponding fields is provided through the BackButtonWidget class, but classes don't have to extend this and can instead copy the functionality of this widget, in case they need to extend another widget. This widget comes with a BackButtonState class which is an abstract class that contains an onBackPressed() function.
    - As soon as the sub-widget is initialized, it passes the back pressed function to the context, along with the state is represents.
    - If the sub-widget is disposed, it removes it from the context.
  - When the WillPopScope is called, the current state is determined, and sees if the state exists and is in the context. If it is, the corresponding back function is called. If it doesn't exist, the default function is called.
- There's also a BackButtonProvider class, which can be used to create descendant back button providers. It should be passed its own BackContext, and its defaultAction function can be assigned to a default action.

The following scenario could exist for instance:

- The root view is A, which has a BackButtonProvider with sub-widgets B and C. These widgets are wrapped in a BackButtonWidget with state "B" and "C" respectively.
  - Widget B has two states: If it's in state 1, it should return to state 0, but if it's in state 0, it should return to the root view A (simply returning false).
  - Widget C has two sub-views C0 and C1, each with their own functionality similar to widget B. What do do?
    - In Widget C, create a BackButtonProvider with default action (most likely returning to widget A).
    - When creating views C0/C1, pass the provider's context.
    - When the back action is passed to C, first check with the BackButtonProvider if the current sub-view can handle the action. If not, C can now handle the back action.
