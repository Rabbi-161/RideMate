# RideMate — Product Requirements Document (PRD)

**Project Type:** Undergraduate Academic Mobile Application Prototype
**Platform:** Android
**Framework:** Flutter
**Language:** Dart
**Development Environment:** Google Antigravity / VS Code
**UI Design:** Figma
**Version Control:** GitHub
**Prototype Data:** Local JSON / Mock Data
**Future Backend:** Firebase or Supabase

---

## 1. Product Overview

RideMate is a simple mobile application prototype inspired by the interface and user flow of railway ticket-search applications such as Rail Sheba.
The main purpose of RideMate is to allow a user to search for available rides by selecting:
**From → To → Date → Time → Search Ride**
The user does not use GPS or a live map.
Instead, RideMate provides a predefined list of locations that users can select from dropdown menus.
The initial prototype focuses primarily on the **ride-search experience** and a simple results page.
The application should remain simple, clean, beginner-friendly, and suitable for an undergraduate software development project.

---

## 2. Core Concept

The core idea is:

> **Select a route and travel time, then find available RideMates travelling on that route.**

Example:

- **From:** Rajshahi → Rajshahi City → Kazla
- **To:** Rajshahi → Rajshahi City → Shaheb Bazar
- **Date:** 10 October 2026
- **Time:** 5:30 PM
- **Action:** Search Ride

The application then displays available rides matching the selected route and time.

---

## 3. Project Goals

The prototype should demonstrate:

1. A railway-style search interface.
2. Predefined selectable locations.
3. Easy From/To selection.
4. Date selection.
5. Time selection.
6. Ride searching.
7. Displaying matching rides.
8. Viewing basic ride information.
9. Simple local/mock data management.
10. A structure that can later be connected to Firebase or Supabase.

---

## 4. Project Scope

### Included

The prototype will include:

- Splash screen
- Login
- Sign Up
- Dashboard/Home
- From location dropdown
- To location dropdown
- Date picker
- Time picker
- Search Ride button
- Search results
- Ride details
- Basic profile
- Local/mock ride data

### Not Included

The prototype will NOT include:

- GPS
- Google Maps
- Live location
- Driver tracking
- Navigation
- Online payment
- Fare calculation
- Vehicle tracking
- Real-time dispatch
- Complex route calculation
- Live traffic
- Ride tracking
- AI chatbot
- Wallet
- Cryptocurrency
- Advanced admin dashboard

The application should remain focused on the search-and-match concept.

---

## 5. Target Users

The primary users are university students and young people who want to find someone travelling along a similar route.
The prototype is intended mainly to demonstrate the concept rather than operate as a real commercial transportation service.

---

## 6. Application Flow

The main user flow should be:

```
Splash Screen
      ↓
Login / Sign Up
      ↓
Dashboard
      ↓
Select From
      ↓
Select To
      ↓
Select Date
      ↓
Select Time
      ↓
Search Ride
      ↓
Search Results
      ↓
Ride Details
```

---

## 7. Splash Screen

The splash screen should display:
**RideMate**
Tagline:
**"Share the ride. Share the journey."**
Use a simple icon representing people sharing a journey.
After a short delay:

```
If user is not logged in
        ↓
Login

If user is logged in
        ↓
Dashboard
```

For the prototype, authentication can be mocked locally.

---

## 8. Authentication

Authentication should remain simple.

### Login Screen

Fields:

- Email
- Password

Buttons:

- Login
- Create an account

### Sign Up Screen

Fields:

- Name
- Email
- Password
- Confirm Password

Button:

- Create Account

For the prototype, use mock/local authentication.
Create an `AuthService` so Firebase or Supabase can be integrated later.

---

## 9. Dashboard

The dashboard is the **main screen of the application**.
The design should be inspired by the simplicity of railway ticket-search applications.
At the top:
**RideMate**
Subtitle:
**"Find people travelling your way."**
The main element should be a large search card.

---

## 10. Search Card

The dashboard search card should contain exactly four main inputs:

### From

Dropdown/selectable location.
Example:
**Kazla**

### To

Dropdown/selectable location.
Example:
**Shaheb Bazar**

### Date

Date picker.
Example:
**10 October 2026**

### Time

Time picker.
Example:
**5:30 PM**
Then:

### Search Ride

A large primary button.

---

## 11. From and To Location Selection

Locations must be predefined.
Do NOT use GPS.
Do NOT use Google Maps.
Do NOT ask the user to enter arbitrary coordinates.
The user selects locations from dropdowns or a location-selection screen.
The initial location hierarchy should be:

```
Division
    ↓
City
    ↓
Area
```

Example:

```
Rajshahi
    ↓
Rajshahi City
    ↓
Kazla
```

---

## 12. Initial Location Dataset

The initial prototype should contain Rajshahi City locations.
Example:

```
Rajshahi
└── Rajshahi City
    ├── Kazla
    ├── Talaimari
    ├── Binodpur
    ├── Motihar
    ├── Shaheb Bazar
    ├── Laxmipur
    ├── Vodra
    ├── Railgate
    ├── Shiroil
    ├── New Market
    └── Bornali
```

The dataset should be stored locally.
Recommended location:

```
assets/
└── data/
    └── locations.json
```

The structure must be easy to edit later.

---

## 13. Location Selection UI

When the user taps the From field, show a selection interface.
Example:

```
Select Departure

Search location...

Rajshahi
   Rajshahi City
      Kazla
      Talaimari
      Binodpur
      Motihar
      Shaheb Bazar
      Laxmipur
      Vodra
      Railgate
```

The same interface should be used for the To field.
The selected location should be clearly highlighted.
Example:
**Rajshahi → Rajshahi City → Kazla**

---

## 14. Editable Location Data

This is an important requirement.
The UI should NOT contain hard-coded location lists.
Instead:

```
locations.json
       ↓
LocationService
       ↓
Location Selection UI
```

This allows the team to later modify:

- Divisions
- Cities
- Areas

without redesigning the application.
For example, adding:

```
Dhaka
└── Dhaka City
    ├── Mirpur
    ├── Dhanmondi
    └── Uttara
```

should require only changing the local data.

---

## 15. Date Selection

When the user taps Date:
Open the standard Flutter date picker.
Display the selected date inside the search card.
Example:
**10 October 2026**
The prototype should prevent selecting invalid past dates for future rides.

---

## 16. Time Selection

When the user taps Time:
Open the standard Flutter time picker.
Example:
**5:30 PM**
The selected time should be displayed in the search card.

---

## 17. Search Validation

Before searching, validate the fields.

### Empty From

Show:
**"Please select your departure location."**

### Empty To

Show:
**"Please select your destination location."**

### Same From and To

Show:
**"Departure and destination cannot be the same."**

### Empty Date

Show:
**"Please select a travel date."**

### Empty Time

Show:
**"Please select a departure time."**

---

## 18. Search Logic

The prototype should use simple local matching.
Search the local ride dataset using:

```
From
+
To
+
Date
+
Time
```

The first version should prioritize exact matches.
Example:

```
Requested:

From: Kazla
To: Shaheb Bazar
Date: 10 Oct
Time: 5:30 PM
```

A ride with:

```
From: Kazla
To: Shaheb Bazar
Date: 10 Oct
Time: 5:30 PM
```

is an exact match.

---

## 19. Time Matching

The prototype does not need complex scheduling algorithms.
Use a simple rule:

```
Exact time = highest priority

Nearby time = lower priority
```

A configurable time tolerance can be used later.
For the first prototype, exact date and time matching is sufficient.

---

## 20. Search Results Screen

After pressing:
**Search Ride**
navigate to:
**Available RideMates**
Display rides as cards.
Each card should contain:

- User avatar
- User name
- From
- To
- Date
- Time
- Available seats
- Rating
- Match status
- View Ride button

Example:

```
Rahim Hasan
4.8 ★

Kazla
   ↓
Shaheb Bazar

10 October 2026
5:30 PM

2 seats available

100% Route Match

[ View Ride ]
```

---

## 21. Empty Search Result

If no ride matches:
Display:
**No RideMate found for this route yet.**
Secondary text:
**Try another date, time, or route.**
Button:
**Create a Ride**
This button may lead to a future Create Ride feature.
For the first prototype, it can simply show a placeholder message if Create Ride is not yet implemented.

---

## 22. Ride Details

When the user taps:
**View Ride**
show:

### Ride Details

**Host:**
Rahim Hasan
**Rating:**
4.8 ★
**From:**
Rajshahi → Rajshahi City → Kazla
**To:**
Rajshahi → Rajshahi City → Shaheb Bazar
**Date:**
10 October 2026
**Time:**
5:30 PM
**Available Seats:**
2
**Route Match:**
100%
**Optional Note:**
"Leaving from Kazla around 5:30 PM."
Primary button:
**Request to Join**

---

## 23. Request to Join

When the user presses:
**Request to Join**
show a confirmation:
**Ride request sent successfully!**
The request should be stored in local application state.
No real-time backend is required for the prototype.

---

## 24. Navigation

Use a simple bottom navigation bar.
Recommended sections:

```
Home
Rides
Profile
```

The **Home** tab contains the main search interface.
The **Rides** tab can show the user's upcoming/requested rides.
The **Profile** tab contains basic user information.
Do not add unnecessary navigation items.
The application is intentionally simple.

---

## 25. Rides Screen

The Rides screen should contain:

### Upcoming

Show rides the user has joined or requested.

### Requests

Show ride requests made by the user.

### Completed

Show completed rides.
Use simple status labels:

- Pending
- Accepted
- Upcoming
- Completed

---

## 26. Profile Screen

Show:

- Profile avatar
- Name
- Email
- Phone
- Rating
- Number of rides

Options:

- Edit Profile
- Settings
- Help
- Logout

Keep this screen simple.

---

## 27. Mock Data

Create several mock users:

- Rahim Hasan
- Karim Ahmed
- Nusrat Jahan
- Fahim Islam
- Sadia Akter
- Tanvir Hossain

Create several mock rides using different:

- Locations
- Dates
- Times
- Available seats

The mock data must allow the search functionality to visibly demonstrate successful results.

---

## 28. Data Architecture

Use a simple architecture:

```
UI
 ↓
Service
 ↓
Local Data
```

Recommended services:

```
AuthService
LocationService
RideService
MatchingService
```

Models:

```
User
Location
Ride
RideRequest
```

This allows local mock data to later be replaced by Firebase or Supabase.

---

## 29. Recommended Project Structure

```
lib/
│
├── main.dart
│
├── models/
│   ├── user.dart
│   ├── location.dart
│   ├── ride.dart
│   └── ride_request.dart
│
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── location_selection_screen.dart
│   ├── search_results_screen.dart
│   ├── ride_details_screen.dart
│   ├── rides_screen.dart
│   └── profile_screen.dart
│
├── widgets/
│   ├── search_card.dart
│   ├── location_selector.dart
│   ├── ride_card.dart
│   ├── custom_button.dart
│   └── empty_state.dart
│
├── services/
│   ├── auth_service.dart
│   ├── location_service.dart
│   ├── ride_service.dart
│   └── matching_service.dart
│
├── data/
│   ├── locations.json
│   ├── users.json
│   └── rides.json
│
└── theme/
    └── app_theme.dart
```

Keep the architecture beginner-friendly.
Do not introduce unnecessary enterprise architecture.

---

## 30. UI Design Requirements

The UI should be inspired by railway booking/search applications but should have its own RideMate identity.
Use:

- Clean white/light background
- One consistent primary color
- Rounded search card
- Clearly separated From and To fields
- Date and Time fields
- Large Search Ride button
- Simple icons
- Clear typography
- Comfortable spacing

The interface should feel:

- Simple
- Friendly
- Reliable
- Easy to understand
- Student-project appropriate

Avoid making it look like Uber, Pathao, or a commercial taxi platform.

---

## 31. Figma Compatibility

The UI should be easy to reproduce in Figma.
Use reusable design components:

```
Button
Input Field
Dropdown Field
Date Field
Time Field
Ride Card
Navigation Bar
```

Use a consistent:

- Color palette
- Typography
- Border radius
- Spacing system
- Icon style

Avoid unnecessarily complicated animations.

---

## 32. Backend Strategy

### Prototype

Use:

```
Local JSON
+
Mock services
+
Local application state
```

### Future Version

Replace:

```
AuthService
RideService
```

with:

```
Firebase
```

or:

```
Supabase
```

without changing the main UI.

---

## 33. Error Handling

The application should gracefully handle:

- Missing location data
- Invalid selection
- Empty search results
- Invalid dates
- Invalid time
- Duplicate From/To selection
- Missing mock ride data

Use user-friendly messages.
Do not expose technical errors to the user.

---

## 34. Performance Requirements

The prototype should:

- Start quickly.
- Navigate smoothly.
- Load local JSON efficiently.
- Avoid unnecessary packages.
- Avoid unnecessary network requests.
- Work offline for the main demonstration.

---

## 35. GitHub Requirements

The project should be GitHub-friendly.
Use separate files for:

- Screens
- Widgets
- Models
- Services
- Data
- Theme

Do not place all functionality in one file.
The structure should allow two team members to work on separate features.
Example:

### Developer 1

- Authentication
- Location selection

### Developer 2

- Search
- Ride results
- Ride details

Both can work without constantly modifying the same files.

---

## 36. Main Demonstration Flow

The most important demonstration should be:

```
Login
 ↓
Dashboard
 ↓
From: Kazla
 ↓
To: Shaheb Bazar
 ↓
Date: 10 October 2026
 ↓
Time: 5:30 PM
 ↓
Search Ride
 ↓
Matching Ride
 ↓
View Ride
 ↓
Ride Details
 ↓
Request to Join
 ↓
Request Confirmation
```

---

## 37. Final Product Objective

The application should communicate its purpose immediately:

> **RideMate helps people find others travelling from the same place to the same destination at a similar time.**

The most important screen is the **Dashboard/Search screen**.
The dashboard should make the user understand the application within a few seconds:

```
Where are you leaving from?

[ Kazla ▼ ]

Where are you going?

[ Shaheb Bazar ▼ ]

Travel Date

[ 10 Oct 2026 ]

Departure Time

[ 5:30 PM ]

[ SEARCH RIDE ]
```

The prototype should prioritize this core experience over advanced features.

---

## 38. Future Expansion

The architecture should leave room for future features such as:

- Firebase/Supabase authentication
- Online ride database
- Real ride requests
- User-to-user communication
- Ride acceptance/rejection
- Notifications
- More cities and locations
- User ratings
- Ride history

These features should NOT be implemented in the initial prototype unless required.

---

## 39. Success Criteria

The prototype is considered successful if a user can:

1. Open RideMate.
2. Log in.
3. See the railway-style dashboard.
4. Select a predefined From location.
5. Select a predefined To location.
6. Select a date.
7. Select a time.
8. Search for a ride.
9. See matching mock rides.
10. Open ride details.
11. Request to join a ride.
12. Receive a confirmation message.

The complete flow should work without requiring GPS, maps, payment systems, or a real backend.
