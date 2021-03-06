

![Logo](/Images/WhiteLogo.png)




# Dosi_Xchange


# iOS App for Exchanging Area Dosimeters

Created by Ryan Ford (Feat. Helen Choi)

Replaces "Dosimeter Manager" (2017)
See version notes below

#### Installation

```
Install from SLAC MDM, SLAC Apps folder.
```
#### Connectivity

* The app stores data in CloudKit.  CloudKit is accessible from the Apple Developer Console.  A valid Apple Developer Account is needed to access the Developer Console.

#### Maintenance

* Periodic review of the Apple Developer console is necessary to verify the devices are registered correctly. 

* App is now available on devices registered with SLAC MDM, in the SLAC Apps folder on your device.

#### Version Notes

Version 1.2 / January 2020:
* Created and Modified Fields in Data Schema:
  - New createdDate and modified Date fields to use in lieu of system dates
  - Auto populate these fields during Alert 8 (deploy new), 3a (collect only), 3i (exchange only)
  - Fields added to raw data output:  myCreatedDate, myModifiedDate, recordID (for debugging reference)
* Cosmetic:
  - Disabled dark mode by problematic view controllers
  - Added default send email sound
  - Resized scanner view to fill frame
  - Cleaned up and commented code
* Briefcase mode:  
  - Outlined class for future upgrade for offline use (not visible)
  - Added flowchart png file
* Queries:
  - Nearest dosimeter query now includes "Active without Dosimeter!" entries and suppresses inactive ones
  - Replaced nils in this query with "" for text strings.
* Alerts:
  - Alert 8:  prevent save if location field is blank
  - New alerts 12 and 13:  Notification when Active field is nil and prevents crashes in Map View and List View
* Development/Production:
  - Migrated data from development to production in new schema
  - Connected app to production via entitlements file


