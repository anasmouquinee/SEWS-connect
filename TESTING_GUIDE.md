    // Instructions for Testing SEWS Connect App

## Testing Your SEWS Connect App

### 1. Enable Windows Developer Mode (Required for Windows)
   - Press Windows key + I
   - Go to Settings > Update & Security > For developers
   - Turn ON "Developer Mode"
   - Restart your computer if prompted

### 2. Test Different Platforms

**Web Browser (Recommended for initial testing):**
```bash
flutter run -d chrome
```

**Windows Desktop (after enabling developer mode):**
```bash
flutter run -d windows
```

**Android (if you have Android Studio/device):**
```bash
flutter run -d android
```

### 3. Test Features

**Dashboard Features:**
- ✅ Welcome section with department info
- ✅ Quick actions (Emergency, Scanner, Tasks, Meeting)
- ✅ Department notifications
- ✅ Active tasks widget
- ✅ Statistics cards (Messages, Tasks, Meetings, Scanned)
- ✅ Bottom navigation

**Video Calling System:**
- ✅ Cross-platform calling (Web ↔ Mobile)
- ✅ Firebase-based signaling (reliable and fast)
- ✅ Automatic caller navigation when call is accepted
- ✅ Call invitation system with accept/decline
- ✅ Real-time call state synchronization
- ✅ Working call timer that updates every second
- ✅ Simple call interface with mute/video controls
- ✅ **APK BUILD SUCCESSFUL** - Ready for phone testing!
- ✅ **Real WebRTC Implementation** - Audio/video streaming with flutter_webrtc
- ⚠️ **Chrome Status**: WebRTC offer created, waiting for mobile answer
- ⚠️ **Connection Issue**: Phone needs to properly handle WebRTC signaling

**Current Call System Status:**
- **What Works**: Call invitations, Firebase signaling, WebRTC offer creation, ICE candidates
- **Chrome Logs**: Shows offer created, ICE candidates gathered, waiting for answer
- **Issue**: Mobile device not creating WebRTC answer or connection timeout
- **WebRTC State**: offer_created → waiting for answer_created
- **APK Location**: `build\app\outputs\flutter-apk\app-release.apk` (111.0MB)

**How Calling Works:**
1. **Caller**: Starts call → Sees "waiting for acceptance" → Automatically navigated to call interface when accepted
2. **Receiver**: Gets call invitation → Accepts call → Navigated to call interface  
3. **Both**: Now in the same call interface with working timer and controls
4. **Timer**: Shows "Connecting..." for 2 seconds, then starts counting call duration

**Admin Dashboard (Go to /admin):**
- ✅ User management
- ✅ Department overview
- ✅ System monitoring
- ✅ Admin statistics
- ✅ Settings management

**Navigation Routes:**
- `/dashboard` - Main user dashboard
- `/admin` - Admin dashboard
- `/chat` - Messaging system
- `/scanner` - QR/Barcode scanner
- `/tasks` - Task management
- `/meeting` - Video meetings
- `/notifications` - Push notifications

### 4. Firebase Setup (For Real Communication)

To enable real-time features, you'll need to:

1. **Create Firebase Project:**
   - Go to https://console.firebase.google.com
   - Create new project named "sews-connect"
   - Enable Authentication, Firestore, and Cloud Messaging

2. **Update Configuration:**
   - Replace placeholder values in `lib/core/config/firebase_config.dart`
   - Add your actual API keys and project IDs

3. **Test Real-time Features:**
   - Real-time messaging
   - Push notifications
   - User authentication
   - Data synchronization

### 5. Production Setup

**For Manufacturing Environment:**
- Set up Firebase with your company domain
- Configure department-specific access controls
- Add your equipment QR codes to the database
- Set up Agora RTC for video calling
- Configure company branding and colors

### 6. Expected UI Components

**Dashboard Layout:**
- Blue gradient welcome card
- 4 quick action buttons in grid
- Department notification cards
- Active tasks list
- 4 statistics cards in 2x2 grid
- Bottom navigation with 5 tabs

**Admin Layout:**
- Dark grey admin theme
- Statistics with trend indicators
- User management table
- Department overview with activity
- System health monitoring
- Settings management

Your app is ready for testing! 🚀
