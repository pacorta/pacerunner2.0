# Pacebud Progress Log: August 22-25

### - Added weekly snapshot feature using the `fl_chart` library and a template from their documentation.

### - Redesigned home screen for quick goal setup or simple run:
- User now has the ability to set a distance goal, time goal, or a distance under time goal.
- Took a lot of time to come up with a simple setup to communicate this. Real usage will dictate if my approach was right.

### - Other Changes:

Eliminated all animations with pageView and pageController to have a smoother UX.

#### Minor UI/UX changes:
- Settings in both main screens.
- User profile displayed in settings
- Stats message sisplay for new users
- Added cupertino time and distance wheel pickers for iOS.
- Fixed floating number when displayed stats were too small.
- In current run screen I disabled the slide-back option

#### What's next:
- Implement live activity simple goal status display
- Add an end-of-run screen to eventually gather more data from user and save to DB.

#### (For earlier logs, see `PAST-LOGS.md`)