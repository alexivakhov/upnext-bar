# UpNext Bar

A macOS menu bar app with cards for the events that matter: birthdays, payments, trips, releases. It shows how many days are left and reminds you when an event is coming up.

- Lives only in the menu bar, with no Dock icon.
- Colourful cards with an icon, a colour and an "in N days" countdown, plus the number of days between events.
- Events can last several days: add an end date and the card shows the range and stays on the timeline until it ends.
- A free-form comment on every event, shown in the editor.
- Filter the timeline by event name and by icon.
- Repeats daily, weekly, monthly or yearly. Repeating events move on to their next date by themselves.
- Reminders on the day of an event or the day before, at the hour you pick in Settings.
- Optionally shows past one-off events above the upcoming ones, with a "Today" marker in between.
- Can show the next event next to the menu bar icon.
- Launches at login.
- Interface in English or Ukrainian, chosen in the app. System, light or dark appearance.

## Install

Download `UpNextBar-<version>.dmg` from [Releases](https://github.com/alexivakhov/upnext-bar/releases), open it and drag **UpNext Bar** to **Applications**.

Releases are not signed with a Developer ID or notarized yet, so macOS blocks the first launch. To allow it, open the app once, then go to **System Settings → Privacy & Security** and click **Open Anyway** next to the UpNext Bar message. Alternatively, remove the quarantine flag:

```sh
xattr -dr com.apple.quarantine /Applications/UpNextBar.app
```

## Requirements

- macOS 26 or later
- To build: Xcode 26 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build and run

```sh
make run      # generate the project, build Debug and launch it
make test     # unit tests
make open     # open the project in Xcode
make install  # build Release and copy it to /Applications
make dmg      # build Release and package it as build/UpNextBar-<version>.dmg
```

`UpNextBar.xcodeproj` is generated from `project.yml` and is not kept in git. Run `make project` after changing `project.yml` or adding files.

Builds are signed ad-hoc ("Sign to Run Locally"), so no Apple Developer account is needed. Because of that, macOS may ask for notification permission again after each rebuild. Launch at login works reliably for the copy in `/Applications`, so use `make install` for everyday use.

## Structure

```
UpNextBar/
  App/        entry point (MenuBarExtra) and AppModel: state, navigation, reminder scheduling
  Models/     Event, CalendarDay (a date without time or time zone)
  Logic/      recurrence maths, card order, filter, reminder plan (pure logic, covered by tests)
  Services/   JSON storage, settings, notifications, launch at login
  Views/      SwiftUI screens: list, card, editor, settings
  Resources/  Localizable.xcstrings (en, uk), app icon
UpNextBarTests/
```

Data is stored in `~/Library/Containers/com.upnextbar.app/Data/Library/Application Support/UpNextBar/events.json`.

## Next

- Sorting
- Card background patterns, tags, attachments
- Several reminders per event
- iCloud sync, backups
